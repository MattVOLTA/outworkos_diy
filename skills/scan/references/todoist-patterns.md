# Scan — Todoist Patterns

Todoist Sync API patterns for label management, task creation, section handling, and caching.

---

## Sync Token Cache (Shared)

Multiple skills share a sync token cache at `/tmp/todoist-sync-cache.json`:
- `/scan`, `/whats-next` all use this cache
- 5-minute TTL — if fresh, do incremental sync instead of full
- After any Sync API call, update the cache with the new `sync_token`

```python
CACHE_PATH = '/tmp/todoist-sync-cache.json'
CACHE_TTL = 300  # 5 minutes

cached_token = '*'
if os.path.exists(CACHE_PATH):
    try:
        cache = json.load(open(CACHE_PATH))
        age = time.time() - os.path.getmtime(CACHE_PATH)
        if age < CACHE_TTL:
            cached_token = cache.get('sync_token', '*')
    except (json.JSONDecodeError, KeyError):
        pass
```

---

## Phase 0d: Full Sync + Label Reset

This script runs at the start of every scan. It fetches all data, resets labels, and saves files for downstream phases.

```bash
python3 << 'PYEOF'
import json, urllib.request, uuid, os, time, subprocess

# Read token from Vault
TOKEN = subprocess.check_output(
    [os.environ.get('OUTWORKOS_ROOT', '.') + '/scripts/get-secret.sh', 'todoist_api_token']
).decode().strip()

# --- Sync token cache ---
CACHE_PATH = '/tmp/todoist-sync-cache.json'
CACHE_TTL = 300

cached_token = '*'
if os.path.exists(CACHE_PATH):
    try:
        cache = json.load(open(CACHE_PATH))
        age = time.time() - os.path.getmtime(CACHE_PATH)
        if age < CACHE_TTL:
            cached_token = cache.get('sync_token', '*')
    except (json.JSONDecodeError, KeyError):
        pass

# Fetch labels, items, projects, and sections in one call
req = urllib.request.Request(
    'https://api.todoist.com/api/v1/sync',
    data=json.dumps({
        "sync_token": cached_token,
        "resource_types": ["labels", "items", "projects", "sections"]
    }).encode(),
    headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'},
    method='POST'
)
with urllib.request.urlopen(req) as resp:
    data = json.loads(resp.read().decode('utf-8'))

# Update shared sync token cache
json.dump({'sync_token': data.get('sync_token', '*')}, open(CACHE_PATH, 'w'))

# Save parsed data to /tmp for reuse
json.dump(data, open('/tmp/scan-sync-data.json', 'w'), ensure_ascii=True)

items = [t for t in data.get('items', []) if not t.get('checked') and not t.get('is_deleted')]
json.dump(items, open('/tmp/scan-items.json', 'w'), ensure_ascii=True)

projects = {p['id']: p['name'] for p in data.get('projects', []) if not p.get('is_deleted')}
json.dump(projects, open('/tmp/scan-projects.json', 'w'), ensure_ascii=True)

sections = [s for s in data.get('sections', []) if not s.get('is_deleted')]
json.dump(sections, open('/tmp/scan-sections.json', 'w'), ensure_ascii=True)

labels = data.get('labels', [])

# --- Create scan and gap labels if missing ---
commands = []
for label_name in ['scan', 'gap']:
    existing = next((l for l in labels if l['name'] == label_name and not l.get('is_deleted')), None)
    if not existing:
        commands.append({
            'type': 'label_add',
            'uuid': str(uuid.uuid4()),
            'temp_id': str(uuid.uuid4()),
            'args': {'name': label_name, 'color': 'charcoal'}
        })
        print(f'Creating {label_name} label')
    else:
        print(f'{label_name} label exists (id: {existing["id"]})')

# --- Reset scan label (clear from all tasks) ---
tasks_with_scan = [t for t in data.get('items', [])
                   if 'scan' in t.get('labels', [])
                   and not t.get('checked') and not t.get('is_deleted')]

for t in tasks_with_scan:
    new_labels = [l for l in t['labels'] if l != 'scan']
    commands.append({
        'type': 'item_update',
        'uuid': str(uuid.uuid4()),
        'args': {'id': t['id'], 'labels': new_labels}
    })

if commands:
    cmd_data = json.dumps({'commands': commands}).encode()
    req2 = urllib.request.Request(
        'https://api.todoist.com/api/v1/sync',
        data=cmd_data,
        headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'},
        method='POST'
    )
    urllib.request.urlopen(req2)

print(f'Cleared scan label from {len(tasks_with_scan)} task(s)')
print(f'Saved {len(projects)} projects, {len(items)} open items, {len(sections)} sections to /tmp/')
PYEOF
```

### Files Saved

| File | Contents | Used By |
|------|----------|---------|
| `/tmp/scan-sync-data.json` | Full sync response | Phase 5 label matching |
| `/tmp/scan-items.json` | Open items only | Phase 3 (active project detection), Phase 4 (workers) |
| `/tmp/scan-projects.json` | Project ID -> name mapping | Phase 4 (workers) |
| `/tmp/scan-sections.json` | All sections | Phase 5a (section detection) |

---

## Phase 5a: Create Gap Tasks (Batch)

Build all task creation commands in Python, write to a temp file, send via curl.

```python
import json, uuid

# Load sections for Triage section detection
sections = json.load(open('/tmp/scan-sections.json'))

commands = []
section_temp_ids = {}  # project_id -> triage_section_temp_id

for gap in all_gaps:
    project_id = gap['todoist_project_id']

    # Check if Triage section exists for this project
    triage_section = next(
        (s for s in sections if s['project_id'] == project_id and s['name'] == 'Triage'),
        None
    )

    if not triage_section and project_id not in section_temp_ids:
        # Auto-create all four sections
        for name in ['Triage', 'Do', 'Waiting', 'Defer']:
            temp = str(uuid.uuid4())
            commands.append({
                'type': 'section_add',
                'uuid': str(uuid.uuid4()),
                'temp_id': temp,
                'args': {'name': name, 'project_id': project_id}
            })
            if name == 'Triage':
                section_temp_ids[project_id] = temp

    # Determine section_id
    section_id = None
    if triage_section:
        section_id = triage_section['id']
    elif project_id in section_temp_ids:
        section_id = section_temp_ids[project_id]

    task_args = {
        'content': gap['content'],
        'description': gap['description'],
        'project_id': project_id,
        'priority': gap['priority'],
        'labels': ['gap']
    }
    if section_id:
        task_args['section_id'] = section_id
    if gap.get('due_string'):
        task_args['due'] = {'string': gap['due_string']}

    commands.append({
        'type': 'item_add',
        'uuid': str(uuid.uuid4()),
        'temp_id': str(uuid.uuid4()),  # MANDATORY — omitting causes error code 20
        'args': task_args
    })

payload = {'commands': commands}
with open('/tmp/scan-todoist-batch.json', 'w') as f:
    json.dump(payload, f)
```

Then send:
```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST "https://api.todoist.com/api/v1/sync" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/scan-todoist-batch.json
```

### Task Description Format

```
**Why this is here:**
[2-3 sentences: what happened, what decision is needed, why now]

**Sources:**
- Gmail: "[Subject]" — https://mail.google.com/mail/u/0/#inbox/{thread_id}
- Slack: "[Snippet]" — slack://channel?team=T&id={channel_id}&message={message_ts}
- Fireflies: "[Meeting title]" — https://app.fireflies.ai/view/{transcriptId}
- Calendar: "[Event title]" — {htmlLink}
```

### Priority Mapping (INVERTED from intuitive)

| Todoist Priority | Meaning |
|-----------------|---------|
| 4 | Urgent (highest) — overdue, someone waiting |
| 3 | High — due today/tomorrow, time-sensitive |
| 2 | Medium — this week, no hard deadline |
| 1 | Normal (lowest) — nice-to-do |

### Due String Values (Consistent Across Workers)

| Value | When to Use |
|-------|------------|
| `"today"` | Urgent, time-sensitive, someone waiting >3 days |
| `"tomorrow"` | High priority, needs attention soon |
| `"next monday"` | Important but not urgent, >3 days waiting |
| *omit* | No hard deadline |

---

## Phase 5b: Apply `scan` Label

After gap tasks are created, apply the `scan` label to all tasks in the current view.

```bash
python3 << 'PYEOF'
import json, uuid, urllib.request, subprocess, os

TOKEN = subprocess.check_output(
    [os.environ.get('OUTWORKOS_ROOT', '.') + '/scripts/get-secret.sh', 'todoist_api_token']
).decode().strip()

# TASKS_TO_LABEL: list of {"id": "task_id", "labels": ["existing_label", ...]}
# Built by matching ranked items to Todoist task IDs
tasks_to_label = json.load(open('/tmp/scan-tasks-to-label.json'))

commands = []
for t in tasks_to_label:
    labels = list(set(t['labels'] + ['scan']))
    commands.append({
        'type': 'item_update',
        'uuid': str(uuid.uuid4()),
        'args': {'id': t['id'], 'labels': labels}
    })

data = json.dumps({'commands': commands}).encode()
req = urllib.request.Request(
    'https://api.todoist.com/api/v1/sync',
    data=data,
    headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'},
    method='POST'
)
with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read().decode())
    ok = sum(1 for v in result.get('sync_status', {}).values() if v == 'ok')
    print(f'scan label applied to {ok} task(s)')
PYEOF
```

Before running, save the matched task list:
```python
json.dump(tasks_to_label, open('/tmp/scan-tasks-to-label.json', 'w'))
```

---

## Dedup: Source ID Check

Before creating any gap task, check if a task already exists with the same source identifier in its description.

```python
import re

def source_exists_in_tasks(source_id, tasks):
    """Check if any existing task references this source_id in its description."""
    for task in tasks:
        desc = task.get('description', '')
        if source_id in desc:
            return True
    return False

# Usage: skip creation if source already tracked
gmail_pattern = re.compile(r'mail\.google\.com/mail/u/0/#inbox/([A-Za-z0-9]+)')
slack_pattern = re.compile(r'slack://channel\?.*?message=([0-9.]+)')
fireflies_pattern = re.compile(r'app\.fireflies\.ai/view/([A-Za-z0-9]+)')
```

This is the shared dedup mechanism between `/scan` and `/whats-next`. Both check for existing source_ids before creating tasks, so running them independently won't create duplicates.

---

## Sections as Status (Auto-Created)

| Section | Purpose |
|---------|---------|
| **Triage** | New tasks from scan, needs decision |
| **Do** | Committed, actively working |
| **Waiting** | Blocked on someone else |
| **Defer** | Parked for later |

---

## Phase S4: Apply Stale Changes (Batch)

After the user approves stale proposals, apply all changes in a single Todoist Sync API call. Build the command list from approved proposals.

### Building the Batch

```python
import json, uuid, subprocess, os

TOKEN = subprocess.check_output(
    [os.environ.get('OUTWORKOS_ROOT', '.') + '/scripts/get-secret.sh', 'todoist_api_token']
).decode().strip()

# Load sections for section_id lookup
sections = json.load(open('/tmp/scan-sections.json'))

# approved_proposals: list of proposal dicts from stale workers, filtered by user approval
commands = []

for p in approved_proposals:
    action = p['action']

    if action == 'complete':
        # item_close: marks task as complete
        commands.append({
            'type': 'item_close',
            'uuid': str(uuid.uuid4()),
            'args': {'id': p['task_id']}
        })

    elif action == 'reprioritize':
        update_args = {'id': p['task_id']}
        if 'new_priority' in p:
            update_args['priority'] = p['new_priority']
        if 'due_string' in p:
            update_args['due'] = {'string': p['due_string']}
        commands.append({
            'type': 'item_update',
            'uuid': str(uuid.uuid4()),
            'args': update_args
        })

    elif action == 'add_due_date':
        update_args = {'id': p['task_id']}
        if 'due_string' in p:
            update_args['due'] = {'string': p['due_string']}
        if 'new_priority' in p:
            update_args['priority'] = p['new_priority']
        commands.append({
            'type': 'item_update',
            'uuid': str(uuid.uuid4()),
            'args': update_args
        })

    elif action == 'move_section':
        # Look up target section_id by name and project
        target_name = p['target_section']
        project_id = p['todoist_project_id']
        target_section = next(
            (s for s in sections
             if s['project_id'] == project_id and s['name'] == target_name),
            None
        )
        if target_section:
            commands.append({
                'type': 'item_move',
                'uuid': str(uuid.uuid4()),
                'args': {'id': p['task_id'], 'section_id': target_section['id']}
            })
        else:
            print(f"WARNING: Section '{target_name}' not found for project {project_id}, skipping move for {p['task_id']}")

payload = {'commands': commands}
with open('/tmp/scan-stale-batch.json', 'w') as f:
    json.dump(payload, f)

print(f'Built {len(commands)} stale change commands')
```

Then send:
```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST "https://api.todoist.com/api/v1/sync" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/scan-stale-batch.json
```

### Command Reference

| Command Type | Purpose | Required Args |
|-------------|---------|---------------|
| `item_close` | Mark task as complete | `id` |
| `item_update` | Change priority and/or due date | `id`, plus `priority` and/or `due` |
| `item_move` | Move task to different section | `id`, `section_id` |

### Section ID Lookup

Always look up `section_id` by name from `/tmp/scan-sections.json` — never hardcode IDs. Sections are per-project, so filter by both `project_id` and `name`:

```python
def get_section_id(sections, project_id, section_name):
    """Find section_id by project and name. Returns None if not found."""
    return next(
        (s['id'] for s in sections
         if s['project_id'] == project_id and s['name'] == section_name),
        None
    )
```

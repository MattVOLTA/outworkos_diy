# Risk — API Patterns & Credentials

Credential handling and Todoist sync patterns for the risk skill. Gmail, Calendar, Fireflies, and Supabase patterns are handled by workers using MCP tools discovered at runtime via ToolSearch.

---

## Credentials

### Todoist Token

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
```

**CRITICAL: REST v2 is DEAD.** `https://api.todoist.com/rest/v2/*` returns HTTP 410 Gone. NEVER use it. Use Sync API (`/api/v1/sync`).

---

## Todoist Sync (Phase 0b)

Reuses the shared sync token cache with `/scan` and `/whats-next`.

```bash
python3 << 'PYEOF'
import json, urllib.request, uuid, os, time, subprocess

# Read token from Vault
_ROOT = os.environ.get('OUTWORKOS_ROOT', '')
TOKEN = subprocess.check_output(
    [_ROOT + '/scripts/get-secret.sh', 'todoist_api_token']
).decode().strip()

# --- Shared sync token cache ---
CACHE_PATH = '/tmp/todoist-sync-cache.json'
CACHE_TTL = 300  # 5 minutes

# Check if /scan or /whats-next ran recently
SCAN_ITEMS = '/tmp/scan-items.json'
scan_fresh = False
if os.path.exists(SCAN_ITEMS) and os.path.exists(CACHE_PATH):
    try:
        cache_age = time.time() - os.path.getmtime(CACHE_PATH)
        items_age = time.time() - os.path.getmtime(SCAN_ITEMS)
        if cache_age < CACHE_TTL and items_age < CACHE_TTL:
            scan_fresh = True
    except OSError:
        pass

if scan_fresh:
    import sys
    print('[cache] Reusing fresh scan data (< 5 min old)', file=sys.stderr)
    items = json.load(open(SCAN_ITEMS))
    sections = json.load(open('/tmp/scan-sections.json')) if os.path.exists('/tmp/scan-sections.json') else []
    # Still need labels for risk label management — do a labels-only sync
    req = urllib.request.Request(
        'https://api.todoist.com/api/v1/sync',
        data=json.dumps({"sync_token": "*", "resource_types": ["labels"]}).encode(),
        headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'},
        method='POST'
    )
    with urllib.request.urlopen(req) as resp:
        label_data = json.loads(resp.read().decode('utf-8'))
    labels = label_data.get('labels', [])
    all_items_for_label_reset = items
else:
    cached_token = '*'
    if os.path.exists(CACHE_PATH):
        try:
            cache = json.load(open(CACHE_PATH))
            age = time.time() - os.path.getmtime(CACHE_PATH)
            if age < CACHE_TTL:
                cached_token = cache.get('sync_token', '*')
        except (json.JSONDecodeError, KeyError):
            pass

    req = urllib.request.Request(
        'https://api.todoist.com/api/v1/sync',
        data=json.dumps({
            "sync_token": cached_token,
            "resource_types": ["items", "sections", "projects", "labels"]
        }).encode(),
        headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'},
        method='POST'
    )
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode('utf-8'))

    # Update shared sync token cache
    json.dump({'sync_token': data.get('sync_token', '*')}, open(CACHE_PATH, 'w'))

    items = [t for t in data.get('items', []) if not t.get('checked') and not t.get('is_deleted')]
    sections = [s for s in data.get('sections', []) if not s.get('is_deleted')]
    labels = data.get('labels', [])
    all_items_for_label_reset = data.get('items', [])

# --- Create risk label if missing ---
commands = []
existing_risk = next((l for l in labels if l['name'] == 'risk' and not l.get('is_deleted')), None)
if not existing_risk:
    commands.append({
        'type': 'label_add',
        'uuid': str(uuid.uuid4()),
        'temp_id': str(uuid.uuid4()),
        'args': {'name': 'risk', 'color': 'red'}
    })
    print('Creating risk label (color: red)')
else:
    print(f'risk label exists (id: {existing_risk["id"]})')

# --- Reset risk label (clear from all tasks) ---
tasks_with_risk = [t for t in all_items_for_label_reset
                   if 'risk' in t.get('labels', [])
                   and not t.get('checked') and not t.get('is_deleted')]

for t in tasks_with_risk:
    new_labels = [l for l in t['labels'] if l != 'risk']
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

print(f'Cleared risk label from {len(tasks_with_risk)} task(s)')

# Save for workers to read
json.dump(items, open('/tmp/risk-items.json', 'w'), ensure_ascii=True)
json.dump(sections, open('/tmp/risk-sections.json', 'w'), ensure_ascii=True)

print(f'Loaded {len(items)} open items, {len(sections)} sections')
PYEOF
```

### Files Saved

| File | Contents | Used By |
|------|----------|---------|
| `/tmp/risk-items.json` | Open items only | Phase 0c (filtering), Phase 1 (workers) |
| `/tmp/risk-sections.json` | All sections | Phase 0c (Defer detection), Phase 1 (workers) |

---

## Phase 0c: Filter to Active Projects

After syncing, filter projects to those with open non-deferred tasks:

```python
import json

items = json.load(open('/tmp/risk-items.json'))
sections = json.load(open('/tmp/risk-sections.json'))

# Build section lookup: section_id -> section_name
section_names = {s['id']: s['name'] for s in sections}

# Build defer section IDs (tasks in Defer are excluded)
defer_section_ids = {s['id'] for s in sections if s['name'] == 'Defer'}

# Group non-deferred tasks by project_id
from collections import defaultdict
project_tasks = defaultdict(list)
for item in items:
    if item.get('section_id') not in defer_section_ids:
        project_tasks[item['project_id']].append(item)

# Match against manifest projects (by Todoist ID)
# MANIFEST_PROJECTS: list of {name, slug, todoist_id, path, db_id}
qualifying = []
for proj in MANIFEST_PROJECTS:
    tid = proj['todoist_id']
    if tid and tid in project_tasks and len(project_tasks[tid]) > 0:
        qualifying.append({
            **proj,
            'task_count': len(project_tasks[tid])
        })

print(f'{len(qualifying)} projects qualify for risk assessment')
for q in qualifying:
    print(f'  {q["name"]}: {q["task_count"]} tasks')
```

---

## MCP Tool Discovery

Workers discover tools at runtime. Key search patterns:

| Need | ToolSearch Query |
|------|-----------------|
| Gmail | `+google gmail` |
| Calendar | `+google calendar` |
| Supabase SQL | `+supabase` |
| Fireflies | `+fireflies` |

Workers use MCP tools for all data source access. No raw REST API calls from workers.

---

## Phase 2a: Auto-Close Resolved Tasks Batch

After collecting worker results, complete any tasks where evidence confirms the action was already taken.

```bash
python3 << 'PYEOF'
import json, uuid, urllib.request, subprocess, os

_ROOT = os.environ.get('OUTWORKOS_ROOT', '')
TOKEN = subprocess.check_output(
    [_ROOT + '/scripts/get-secret.sh', 'todoist_api_token']
).decode().strip()

# CLOSE_IDS: list of task IDs to auto-close (built by main agent from worker results)
close_ids = json.load(open('/tmp/risk-auto-close.json'))

if not close_ids:
    print('No tasks to auto-close')
    exit(0)

commands = []
for task_id in close_ids:
    commands.append({
        'type': 'item_close',
        'uuid': str(uuid.uuid4()),
        'args': {'id': task_id}
    })

payload = json.dumps({'commands': commands}).encode()
req = urllib.request.Request(
    'https://api.todoist.com/api/v1/sync',
    data=payload,
    headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'},
    method='POST'
)
with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read().decode())
    ok = sum(1 for v in result.get('sync_status', {}).values() if v == 'ok')
    print(f'Auto-closed {ok}/{len(commands)} resolved task(s)')
PYEOF
```

Before running, save the close list:
```python
json.dump(close_ids, open('/tmp/risk-auto-close.json', 'w'))
```

---

## Phase 2b: Priority Escalation + Label Application Batch

After synthesizing worker results, escalate Todoist priorities for Critical and At Risk items (only escalates, never downgrades) and apply the `risk` label to ALL Critical and At Risk tasks.

```bash
python3 << 'PYEOF'
import json, uuid, urllib.request, subprocess, os

_ROOT = os.environ.get('OUTWORKOS_ROOT', '')
TOKEN = subprocess.check_output(
    [_ROOT + '/scripts/get-secret.sh', 'todoist_api_token']
).decode().strip()

# ESCALATIONS: list of {"task_id": "...", "new_priority": 4, "old_priority": 2, ...}
# Built by main agent from worker results (see SKILL.md Phase 2b)
escalations = json.load(open('/tmp/risk-escalations.json'))

# RISK_TASKS: list of {"task_id": "...", "labels": ["existing", ...], "tier": "critical"|"at_risk"}
# ALL Critical and At Risk tasks — includes tasks already at target priority
risk_tasks = json.load(open('/tmp/risk-tasks-to-label.json'))

commands = []

# Priority escalation commands (only for tasks that need escalation)
for e in escalations:
    commands.append({
        'type': 'item_update',
        'uuid': str(uuid.uuid4()),
        'args': {
            'id': e['task_id'],
            'priority': e['new_priority']
        }
    })

# Label application commands (all Critical and At Risk tasks)
# Skip tasks already handled by escalation (they'll get labels in a separate command)
escalated_ids = {e['task_id'] for e in escalations}
for t in risk_tasks:
    labels = list(set(t.get('labels', []) + ['risk']))
    commands.append({
        'type': 'item_update',
        'uuid': str(uuid.uuid4()),
        'args': {
            'id': t['task_id'],
            'labels': labels
        }
    })

if not commands:
    print('No escalations or labels to apply')
    exit(0)

payload = json.dumps({'commands': commands}).encode()
req = urllib.request.Request(
    'https://api.todoist.com/api/v1/sync',
    data=payload,
    headers={'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'},
    method='POST'
)
with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read().decode())
    ok = sum(1 for v in result.get('sync_status', {}).values() if v == 'ok')
    print(f'Processed {ok}/{len(commands)} command(s) ({len(escalations)} escalations, {len(risk_tasks)} labels)')
PYEOF
```

Before running, save both lists:
```python
json.dump(escalations, open('/tmp/risk-escalations.json', 'w'))
json.dump(risk_tasks, open('/tmp/risk-tasks-to-label.json', 'w'))
```

### Building `risk_tasks` List

From the merged worker results, collect ALL Critical and At Risk tasks for labeling:

```python
risk_tasks = []
for result in all_worker_results:
    for risk in result.get('risks', []):
        if risk['tier'] in ('critical', 'at_risk'):
            risk_tasks.append({
                'task_id': risk['task_id'],
                'labels': risk.get('labels', []),  # existing labels from Todoist
                'tier': risk['tier']
            })
```

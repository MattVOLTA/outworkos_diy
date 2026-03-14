# Todoist API Reference for Claude Code

Drop this section into any project's `CLAUDE.md` to enable Todoist integration. Requires `todoist_api_token` in Vault (stored via `$OUTWORKOS_ROOT/scripts/set-secret.sh`).

---

## Setup

### Token

Get a personal API token from [Todoist Settings > Integrations > Developer](https://todoist.com/app/settings/integrations/developer). Store in Vault:

```bash
"$OUTWORKOS_ROOT/scripts/set-secret.sh" todoist_api_token "your_token_here" "Todoist personal API token"
```

### Authentication

All requests use Bearer token auth:

```
Authorization: Bearer $TODOIST_API_TOKEN
```

---

## API Choice: Always Use the Sync API

Todoist has two APIs. **Always prefer the Sync API** for Claude Code usage.

| | REST API v2 | Sync API |
|---|---|---|
| Base URL | `https://api.todoist.com/rest/v2/` | `https://api.todoist.com/api/v1/sync` |
| Batching | No - 1 request per operation | Yes - up to 100 commands per request |
| Rate limit | 450 req / 15 min | 1,000 incremental or 100 full syncs / 15 min |
| Incremental sync | No | Yes - via `sync_token` |

A single Sync API call with 100 commands counts as **1 request**. The equivalent via REST would burn 100 requests. There is no reason to use REST for anything except the simplest one-off read.

---

## Rate Limits

| API | Limit | Window | On Exceed |
|-----|-------|--------|-----------|
| REST API v2 | 450 requests | 15 minutes | HTTP 429 |
| Sync API (incremental) | 1,000 requests | 15 minutes | HTTP 429 |
| Sync API (full sync) | 100 requests | 15 minutes | HTTP 429 |

**Avoiding 429s:**
- Use incremental sync (stored `sync_token`) instead of full sync (`"*"`) whenever possible
- Batch all writes into a single Sync API call
- On 429: back off exponentially (`2^attempt` seconds), check `retry_after` in error response
- Include `X-Request-Id` (UUID) on all write requests for safe retries

---

## Reading Data (Sync API)

### Full Sync (first call or cold start)

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token": "*", "resource_types": ["items", "projects", "sections", "labels"]}'
```

- `sync_token: "*"` means "give me everything"
- Counts against the **100 full syncs / 15 min** limit
- Response includes a new `sync_token` - **save it** for incremental sync

### Incremental Sync (subsequent calls)

```bash
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token": "SAVED_TOKEN_FROM_LAST_CALL", "resource_types": ["items"]}'
```

- Returns **only changes** since the last sync
- Counts against the **1,000 incremental / 15 min** limit (10x more generous)
- Much smaller response payload

### Resource Types

Use `resource_types` to fetch only what you need:

| Value | Returns |
|-------|---------|
| `"items"` | Tasks |
| `"projects"` | Projects |
| `"sections"` | Sections within projects |
| `"labels"` | Labels |
| `"notes"` | Comments on tasks |
| `"all"` | Everything (avoid unless needed) |

### Filtering Responses

The Sync API returns everything for the requested resource types. Filter client-side:

```python
# Filter tasks to a specific project
project_tasks = [t for t in response["items"] if t["project_id"] == "YOUR_PROJECT_ID"]

# Filter to a specific section
section_tasks = [t for t in response["items"] if t["section_id"] == "YOUR_SECTION_ID"]
```

### Key Task Fields in Response

```json
{
  "id": "task_id",
  "content": "Task title (supports Markdown)",
  "description": "Extended description",
  "project_id": "project_id",
  "section_id": "section_id or null",
  "parent_id": "parent_task_id or null",
  "labels": ["label1", "label2"],
  "priority": 1,          // 1=normal, 2=medium, 3=high, 4=urgent
  "due": {
    "date": "2026-02-20",
    "string": "tomorrow",
    "is_recurring": false,
    "datetime": "2026-02-20T10:00:00Z",
    "timezone": "America/Halifax"
  },
  "is_completed": false,
  "checked": false,
  "added_at": "2026-01-15T12:00:00Z",
  "child_order": 1
}
```

---

## Writing Data (Sync API Commands)

### Batch Command Structure

All writes go through the same `/sync` endpoint with a `commands` array:

```bash
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {
        "type": "item_add",
        "uuid": "unique-uuid-1",
        "temp_id": "temp-id-for-referencing",
        "args": {
          "content": "New task",
          "project_id": "PROJECT_ID",
          "section_id": "SECTION_ID",
          "priority": 2,
          "due": {"string": "tomorrow"}
        }
      },
      {
        "type": "item_complete",
        "uuid": "unique-uuid-2",
        "args": {
          "id": "existing-task-id"
        }
      }
    ]
  }'
```

**Every command needs:**
- `type` - The operation
- `uuid` - A unique UUID you generate (for idempotency and result tracking)
- `args` - Operation-specific arguments

**Optional:**
- `temp_id` - A UUID you assign to a newly created resource so other commands in the same batch can reference it

### Command Types Reference

#### Tasks

| Command | Args | Notes |
|---------|------|-------|
| `item_add` | `content` (required), `project_id`, `section_id`, `parent_id`, `labels`, `priority`, `due`, `description` | Use `temp_id` to reference in same batch |
| `item_update` | `id` (required), plus any fields to change | Only send changed fields |
| `item_complete` | `id` (required) | Marks done. Recurring tasks reschedule instead of completing. |
| `item_uncomplete` | `id` (required) | Reopens a completed task |
| `item_delete` | `id` (required) | Permanent deletion |
| `item_move` | `id` (required), `project_id` or `section_id` or `parent_id` | Move between projects/sections |
| `item_reorder` | `items` (array of `{id, child_order}`) | Reorder within a section |

#### Projects

| Command | Args |
|---------|------|
| `project_add` | `name` (required), `parent_id`, `color`, `is_favorite`, `view_style` |
| `project_update` | `id` (required), plus fields to change |
| `project_delete` | `id` (required) |

#### Sections

| Command | Args |
|---------|------|
| `section_add` | `name` (required), `project_id` (required) |
| `section_update` | `id` (required), `name` |
| `section_delete` | `id` (required) |

### Response Structure

```json
{
  "sync_token": "new_token",
  "sync_status": {
    "uuid-1": "ok",
    "uuid-2": {"error_code": 40, "error": "Invalid argument value"}
  },
  "temp_id_mapping": {
    "temp-id-you-assigned": "actual-id-created"
  }
}
```

- Check `sync_status` to verify each command succeeded
- Use `temp_id_mapping` to get real IDs for newly created resources

---

## Common Patterns for Claude Code

### Pattern 1: Read all tasks for a project

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
RESPONSE=$(curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token": "*", "resource_types": ["items", "sections"]}')

# Filter to your project and parse with python
echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tasks = [t for t in data.get('items', []) if t.get('project_id') == 'YOUR_PROJECT_ID']
for t in tasks:
    status = 'DONE' if t.get('checked') else 'OPEN'
    due = t.get('due', {}).get('date', 'no date') if t.get('due') else 'no date'
    print(f'[{status}] {t[\"content\"]} (due: {due}, id: {t[\"id\"]})')
print(f'\nsync_token: {data[\"sync_token\"]}')
"
```

### Pattern 2: Close a task + create a new one in one call

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"commands\": [
      {
        \"type\": \"item_complete\",
        \"uuid\": \"$(uuidgen)\",
        \"args\": {\"id\": \"TASK_ID_TO_CLOSE\"}
      },
      {
        \"type\": \"item_add\",
        \"uuid\": \"$(uuidgen)\",
        \"args\": {
          \"content\": \"Follow up on X\",
          \"project_id\": \"PROJECT_ID\",
          \"section_id\": \"SECTION_ID\",
          \"due\": {\"string\": \"next Monday\"}
        }
      }
    ]
  }"
```

### Pattern 3: Update task content and due date

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"commands\": [
      {
        \"type\": \"item_update\",
        \"uuid\": \"$(uuidgen)\",
        \"args\": {
          \"id\": \"TASK_ID\",
          \"content\": \"Updated task title\",
          \"due\": {\"string\": \"Feb 25\"}
        }
      }
    ]
  }"
```

---

## CLAUDE.md Snippet

Copy this block into a project's `CLAUDE.md` to enable Todoist access:

````markdown
## Todoist Access

**API Token:** Stored in Vault as `todoist_api_token`. Retrieve via `$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)`

**Always use the Sync API** (`POST https://api.todoist.com/api/v1/sync`), never individual REST calls. The Sync API supports batching (up to 100 commands = 1 request) and incremental sync.

**Rate limits:** 100 full syncs or 1,000 incremental syncs per 15 minutes. Batch all writes into a single call.

**Reading tasks:**
```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token": "*", "resource_types": ["items", "sections"]}'
```

Filter response client-side by `project_id` or `section_id`.

**Writing tasks** (close, create, update - batch in one call):
```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"commands": [{"type": "item_complete", "uuid": "'$(uuidgen)'", "args": {"id": "TASK_ID"}}]}'
```

**Key IDs:**
- Project: `YOUR_PROJECT_ID`
- Sections: list via Sync API with `resource_types: ["sections"]`

**Rules:**
- Always generate a UUID for each command (`uuidgen`)
- Batch multiple operations into a single `commands` array
- On HTTP 429: exponential backoff, do not retry immediately
- Recurring tasks reschedule on `item_complete` (use `item_delete` to remove permanently)
````

---

## Gotchas

1. **`item_complete` vs `item_delete`** - Completing a recurring task reschedules it to the next occurrence. Only `item_delete` permanently removes it.
2. **`sync_token: "*"`** counts against the stricter 100/15min full sync limit. Cache the token when possible.
3. **No MCP server exists** for Todoist. All access is via `curl` in Bash.
4. **UUIDs are required** on every command. Use `$(uuidgen)` in bash or generate in Python.
5. **Priority is inverted** - `4` is urgent/highest, `1` is normal/lowest (opposite of what you'd expect).
6. **Due dates** - Use `due.string` for natural language ("tomorrow", "every Monday"), `due.date` for exact dates ("2026-02-20"), `due.datetime` for date+time with timezone.
7. **Task IDs are strings**, not integers, in the newer API responses.
8. **Filters are client-side** - The Sync API returns all items; filter by `project_id`/`section_id` in your parsing code.

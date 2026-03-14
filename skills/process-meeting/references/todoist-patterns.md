# Todoist Sync API Patterns for Task Creation

## Endpoint

```
POST https://api.todoist.com/api/v1/sync
```

## Authentication

```
Authorization: Bearer <token>
```

Token stored in Vault with label `todoist_api_token`. Retrieve at runtime:
```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
```

## CRITICAL: REST v2 is Dead

```
https://api.todoist.com/rest/v2/*  ->  HTTP 410 Gone
```

Never use `/rest/v2/` endpoints. Always use the Sync API for both reads and writes.

## Batch Task Creation

Build payloads in Python to avoid shell escaping issues. Every `item_add` command requires both `uuid` and `temp_id`.

```python
import json, uuid

commands = []
for item in action_items:
    commands.append({
        "type": "item_add",
        "uuid": str(uuid.uuid4()),
        "temp_id": str(uuid.uuid4()),
        "args": {
            "content": item["task"],
            "project_id": "TODOIST_PROJECT_ID",
            "description": f"Fireflies: {transcript_id}. {item.get('context', '')}",
            "priority": item.get("priority", 2),
            "labels": ["from-meeting"]
        }
    })

payload = {"commands": commands}
with open("/tmp/meeting-tasks.json", "w") as f:
    json.dump(payload, f)
```

Then send:
```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST "https://api.todoist.com/api/v1/sync" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Request-Id: $(uuidgen)" \
  -d @/tmp/meeting-tasks.json
```

## Include X-Request-Id for Idempotency

Always include `X-Request-Id` header with a UUID on write requests. If a request times out and you retry, the same `X-Request-Id` prevents duplicate task creation.

## Section Mapping

Tasks use Todoist sections as a status workflow:

| Section | Purpose |
|---------|---------|
| **Triage** | New tasks from meetings, needs decision |
| **Do** | Committed, actively working |
| **Waiting** | Blocked on someone else |
| **Defer** | Parked for later |

By default, meeting action items go into the **Triage** section (new tasks requiring prioritization). To place into a section, include `"section_id"` in the `item_add` args.

To find the Triage section ID for a project, do a sync read first:
```bash
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token": "*", "resource_types": ["sections"]}'
```

Filter sections by `project_id` and `name == "Triage"`.

## Priority Mapping (Inverted)

| Todoist Priority | Meaning |
|-----------------|---------|
| 4 | Urgent (highest) |
| 3 | High |
| 2 | Medium |
| 1 | Normal (lowest) |

Default meeting action items to priority 2 (medium) unless urgency is apparent from the transcript.

## Response Verification

```python
import json

response = json.loads(result)
status = response.get("sync_status", {})
ok = sum(1 for v in status.values() if v == "ok")
failed = len(status) - ok
print(f"Created: {ok}, Failed: {failed}")

# Get real IDs for created tasks
mapping = response.get("temp_id_mapping", {})
for temp_id, real_id in mapping.items():
    print(f"  {temp_id} -> {real_id}")
```

## Error Codes

| Code | Meaning | Fix |
|------|---------|-----|
| 20 | Missing `temp_id` | Every `item_add` must have a `temp_id` (UUID) |
| 22 | Invalid `project_id` | Verify the project ID exists |
| 40 | Invalid argument value | Check field types and values |

## Shell Escaping Gotchas

- Never use inline `$(uuidgen)` inside JSON strings
- Never use `!=` in Python inside bash heredocs (bash escapes it as `\!=`)
- Always build JSON payloads in standalone Python, write to temp file, then `curl -d @file.json`
- Use `str(uuid.uuid4())` in Python instead of shell-level UUID generation

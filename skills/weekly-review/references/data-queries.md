# Data Queries for Weekly Review

## Log Entries (Supabase)

Query via Supabase MCP `execute_sql`:

```sql
SELECT
  le.project_id,
  p.name AS project_name,
  le.entry_date,
  le.session_title,
  le.content,
  le.source
FROM log_entries le
LEFT JOIN projects p ON p.id = le.project_id
WHERE le.user_id = auth.uid()
  AND le.entry_date >= '{start_date}'
  AND le.entry_date <= '{end_date}'
ORDER BY le.entry_date DESC;
```

Group results by `project_id` to get per-project activity.

## Todoist Completed Tasks

Use the Todoist Sync API completed items endpoint:

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token": "*", "resource_types": ["items"]}'
```

Filter response client-side:
```python
import json, sys
data = json.load(sys.stdin)
# Get all completed items
completed = [t for t in data.get('items', []) if t.get('checked')]
# Filter by completion date (items have 'completed_at' field)
# Group by project_id
```

For completed items archive (items completed and removed from active list), use:
```bash
curl -s "https://api.todoist.com/sync/v9/completed/get_all" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -d "since={start_date}T00:00:00" \
  -d "until={end_date}T23:59:59"
```

Map `project_id` to project names using the session manifest or a Sync API call with `resource_types: ["projects"]`.

## Gmail Thread Volume

Search via Google Workspace MCP Gmail search tool using `USER_EMAIL` from Runtime Context:

```
# All sent/received in date range
query: "after:{start_yyyy/mm/dd} before:{end_yyyy/mm/dd}"

# Per-project (use known contact emails from manifest)
query: "from:contact@example.com OR to:contact@example.com after:{start} before:{end}"
```

Count unique threads per project. If a project has no known contacts in the manifest, skip Gmail for that project.

## Fireflies Meetings

Search via Fireflies MCP search tool:

```
query: "" (empty to get all recent)
```

Filter results by `dateString` within the date range. Map to projects by:
1. Matching participant emails to project contacts
2. Matching meeting title keywords to project names
3. If no match, list under "Unmatched Meetings"

## Todoist Waiting/Blocked Items

To find blockers, query for tasks in "Waiting" sections:

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST https://api.todoist.com/api/v1/sync \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token": "*", "resource_types": ["items", "sections"]}'
```

Filter client-side:
```python
# Find all "Waiting" section IDs
waiting_sections = [s['id'] for s in data['sections'] if s['name'] == 'Waiting']
# Filter tasks in those sections
blocked = [t for t in data['items'] if t.get('section_id') in waiting_sections and not t.get('checked')]
```

## Upcoming Deadlines

From the same Todoist sync response, find tasks due in the next 7 days:

```python
from datetime import datetime, timedelta
next_week = (datetime.now() + timedelta(days=7)).strftime('%Y-%m-%d')
today = datetime.now().strftime('%Y-%m-%d')
upcoming = [t for t in data['items']
            if t.get('due') and t['due'].get('date')
            and today <= t['due']['date'] <= next_week
            and not t.get('checked')]
```

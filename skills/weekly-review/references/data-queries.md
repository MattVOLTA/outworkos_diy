# Data Queries for Weekly Review

The data gathering step is unchanged from a traditional review — you still need the raw inputs. The difference is in how they're synthesized (narrative prose, not metrics tables).

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

Log entries are the richest source for narrative synthesis — they contain session summaries with context about what was accomplished and why.

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

Completed tasks supplement log entries — they show the granular work that happened even when a formal log entry wasn't written.

## Gmail Thread Volume

Search via Google Workspace MCP Gmail search tool using `USER_EMAIL` from Runtime Context:

```
# All sent/received in date range
query: "after:{start_yyyy/mm/dd} before:{end_yyyy/mm/dd}"

# Per-project (use known contact emails from manifest)
query: "from:contact@example.com OR to:contact@example.com after:{start} before:{end}"
```

Gmail data helps identify which relationships were active — conversations had, decisions communicated, introductions made.

## Fireflies Meetings

Search via Fireflies MCP search tool:

```
query: "" (empty to get all recent)
```

Filter results by `dateString` within the date range. Map to projects by:
1. Matching participant emails to project contacts
2. Matching meeting title keywords to project names
3. If no match, list under "Unmatched Meetings"

Meeting data reveals collaboration and decision-making that may not appear in logs or tasks.

## Usage Notes

- **Run all four queries in parallel** — they are independent
- **Log entries are primary** — they have the richest narrative content for synthesis
- **Tasks and emails are supplementary** — they fill in gaps where no log entry was written
- **Meetings provide color** — participant lists and titles help reconstruct the week's conversations
- **No blocker or deadline queries needed** — this review is backward-looking only

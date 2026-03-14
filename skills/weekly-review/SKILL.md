---
name: weekly-review
description: "Cross-project weekly retrospective. Aggregates log entries, Todoist completions, Gmail threads, and Fireflies meetings across all projects for the past 7 days. Use for weekly reviews, board updates, identifying stalled projects, or asking 'what happened this week'."
context: fork
---

# /weekly-review

Generate a cross-project retrospective for a given time window (default: last 7 days).

## Runtime Context

At the start of each review, retrieve user context:

```sql
SELECT email, timezone FROM user_profiles WHERE user_id = auth.uid()
```

Use the returned `email` for Gmail queries (replacing any hardcoded sender address) and `timezone` for date calculations.

Store these values as `USER_EMAIL` and `USER_TIMEZONE` for use throughout all steps.

## When to Use

- Weekly planning or reflection
- Preparing board updates or status reports
- Identifying stalled or neglected projects
- Asking "what happened this week?" or "what did I work on?"

## Workflow

### Step 1: Determine Date Range

Default: last 7 days from today. Accept optional user input for custom range (e.g., "last 2 weeks", "Feb 1-15").

Calculate `start_date` and `end_date` in `YYYY-MM-DD` format.

### Step 2: Gather Log Entries

Query `log_entries` table via Supabase MCP `execute_sql` for all entries in the date range. Group by `project_id`.

Read `references/data-queries.md` for the SQL query pattern.

### Step 3: Gather Todoist Completions

Fetch all completed tasks from Todoist Sync API using the completed items endpoint. Filter by `completed_at` within the date range. Group by project.

Read `references/data-queries.md` for the Todoist API pattern.

### Step 4: Gather Gmail Volume

Search Gmail via Google Workspace MCP for threads in the date range per project. Use known contact emails from the session manifest to map threads to projects.

Read `references/data-queries.md` for Gmail search patterns.

### Step 5: Gather Fireflies Meetings

Search Fireflies for meetings in the date range. Map to projects by participant email or title keywords.

Read `references/data-queries.md` for Fireflies query pattern.

### Step 6: Aggregate and Analyze

Combine all data sources into a per-project activity summary. Identify:

- **Active projects** — Have log entries, completed tasks, or email activity
- **Stalled projects** — Zero activity across all sources in the review window
- **Top accomplishments** — Pull from log entry content
- **Open blockers** — Tasks in "Waiting" sections across all Todoist projects
- **Upcoming deadlines** — Tasks with due dates in the next 7 days

### Step 7: Format Output

Present using the template in `references/output-template.md`:

1. Summary stats (totals across all projects)
2. Per-project breakdown (sorted by activity level, most active first)
3. Stalled projects list
4. Highlights (top accomplishments from logs)
5. Blockers (Waiting section items)
6. Recommended priorities for coming week

### Step 8: Offer Follow-up Actions

Ask the user:
1. **Save to file** — Write the review to `briefs/weekly-review-YYYY-MM-DD.txt`
2. **Create priority tasks** — Add recommended priorities as Todoist tasks
3. **Generate audio brief** — Produce a spoken version via ElevenLabs (reuse `/sitrep` audio patterns)
4. **Done** — No further action

## Key Rules

- All secrets from Vault via `$OUTWORKOS_ROOT/scripts/get-secret.sh <label>`
- Never hardcode MCP tool names — use ToolSearch to discover available tools
- Run data source queries in parallel (Steps 2-5 are independent)
- Graceful degradation: if a data source is unavailable, note it in the output and continue
- User ID for DB queries: always use `auth.uid()` — never hardcode a user ID

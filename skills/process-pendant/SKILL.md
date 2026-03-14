---
name: process-pendant
description: "Reviews all conversations captured by the Limitless Pendant for a given day, cross-references with Calendar events and Fireflies transcripts to pick the best source, then collaboratively matches signals to existing projects, contacts, and ideas. Use when processing daily pendant data, reviewing ambient conversations, or capturing insights from in-person meetings."
argument-hint: ["today" (default) | "yesterday" | "YYYY-MM-DD"]
context: fork
---

# Process Pendant

## Runtime Context

Before executing, resolve the following dynamic values:

1. **User ID**: Use `auth.uid()` in all SQL queries. For raw SQL inserts where a literal UUID is needed, first query: `SELECT auth.uid() AS user_id` and cache the result.
2. **User email**: Query `SELECT email FROM user_profiles WHERE id = auth.uid()` via Supabase MCP `execute_sql`.
3. **User timezone**: Query `SELECT timezone FROM user_profiles WHERE id = auth.uid()`. Use this for all time-related parameters (API calls, timestamp conversions, display formatting). All references to timezone below use `{user_timezone}` — substitute the queried value.
4. **Vault secrets**: Construct Vault key names dynamically. First get the user ID, then build the key as `'user_' || {user_id} || '_{label}'`. For example, for the Limitless API key: `'user_' || {user_id} || '_limitless_api_key'`.
5. **Supabase project ID**: Use the `SUPABASE_PROJECT_ID` environment variable or read from the SessionStart manifest. Never hardcode.
6. **OutworkOS root**: Use `$OUTWORKOS_ROOT` environment variable (fallback: discover from SessionStart context).
7. **MCP tools**: Use `ToolSearch` to discover all MCP tool names at runtime. Never hardcode tool names.

Cache these values at the start of execution and reuse throughout.

## Purpose

Turn a full day of Limitless Pendant recordings into tracked work by cross-referencing three data sources (Calendar, Fireflies, Limitless), selecting the best source for each time block, and collaboratively routing signals to projects, contacts, and action items.

The pendant captures what other tools miss: in-person meetings, hallway conversations, podcast insights, evening work sessions, and ambient idea capture.

## Data Storage Rules

- **DB is source of truth** via Supabase MCP `execute_sql`. Discover MCP tools via `ToolSearch` at runtime — never hardcode tool names.
- **Project DB IDs** come from the SessionStart manifest (injected into context). Each project entry includes `DB ID`, `Slug`, and `Todoist ID`.
- **Dual-write during transition:** Write to both DB and local files. DB writes use `execute_sql`; local file writes use the existing patterns.
- **User ID for all DB writes:** Use the value resolved from `auth.uid()` in Runtime Context.
- **Graceful fallback:** If Supabase MCP is unavailable, fall back to file-only I/O. Skills never break from DB outage.

## Prerequisites

- Supabase MCP available (required for Vault access and database writes)
- Limitless API key in Vault (retrieve dynamically — see Step 1A)
- Todoist API token in Vault (retrieve dynamically — see Step 5)
- Google Calendar MCP available (discover via ToolSearch)
- Fireflies MCP available (discover via ToolSearch)
- SessionStart manifest in context (for project matching)

## Execution Steps

### Step 0: Parse Arguments & Set Date

Determine the target date:
- `today` (default): Use current date
- `yesterday`: Use previous date
- `YYYY-MM-DD`: Use the specified date

All timestamps throughout this skill must use the user's timezone (from Runtime Context). Convert any UTC timestamps from APIs accordingly.

### Step 1: Gather All Three Sources (Parallel)

Fetch data from all three sources concurrently:

#### 1A: Limitless Lifelogs

Retrieve the API key from Vault via Supabase MCP `execute_sql`. First resolve the user ID, then construct the secret name dynamically:
```sql
SELECT auth.uid() AS user_id;
```
Then:
```sql
SELECT decrypted_secret FROM vault.decrypted_secrets
WHERE name = 'user_' || '{user_id}' || '_limitless_api_key' LIMIT 1;
```
Extract the `decrypted_secret` value from the result.

Fetch lifelogs for the target date. The API returns max 10 per request with no reliable pagination, so fetch both ascending and descending:

```bash
# Ascending (oldest first)
curl -s -X GET "https://api.limitless.ai/v1/lifelogs?date={YYYY-MM-DD}&timezone={user_timezone}&includeMarkdown=true&includeHeadings=true&includeContents=true&limit=10&direction=asc" \
  -H "X-API-Key: $LIMITLESS_API_KEY"

# Descending (newest first)
curl -s -X GET "https://api.limitless.ai/v1/lifelogs?date={YYYY-MM-DD}&timezone={user_timezone}&includeMarkdown=true&includeHeadings=true&includeContents=true&limit=10&direction=desc" \
  -H "X-API-Key: $LIMITLESS_API_KEY"
```

**CRITICAL: API Response Structure.** The Limitless API wraps lifelogs inside a `data` key:
```json
{
  "data": {
    "lifelogs": [ ... ]
  }
}
```
Parse as `response["data"]["lifelogs"]`, NOT `response["lifelogs"]`.

Merge and deduplicate results by `id`. Each lifelog has:
- `id`, `title`, `markdown`, `startTime`, `endTime`
- `contents[]` with `type`, `content`, `speakerName`, `speakerIdentifier`

#### 1B: Google Calendar Events

Discover Calendar tools via ToolSearch:
```
ToolSearch: "gcal list events"
```

Fetch all events for the target date with full details (attendees, descriptions):
- `timeMin`: `{YYYY-MM-DD}T00:00:00`
- `timeMax`: `{YYYY-MM-DD}T23:59:59`
- `timeZone`: `{user_timezone}`
- `condenseEventDetails`: false

Each event provides: `summary`, `start`, `end`, `attendees[]`, `description`, `location`.

#### 1C: Fireflies Transcripts

Discover Fireflies tools via ToolSearch:
```
ToolSearch: "fireflies transcripts"
```

Fetch all transcripts for the target date:
- `fromDate`: `{YYYY-MM-DD}`
- `toDate`: `{YYYY-MM-DD}`
- `format`: `json`
- `limit`: 50

Each transcript provides: `id`, `title`, `dateString` (UTC), `duration`, `summary`, `meetingAttendees[]`, `participants[]`.

**Important:** Fireflies timestamps are UTC. Convert to the user's timezone for alignment.

### Step 2: Build the Timeline & Select Best Source

Create a unified timeline of the day by matching events across sources using time overlap.

#### Source Priority Cascade

For each time block, select the best source using this hierarchy:

| Priority | Source | Condition | Why |
|----------|--------|-----------|-----|
| 1 | **Fireflies** | Transcript exists for this time window | Speaker IDs, structured summaries, action items already extracted |
| 2 | **Limitless** | Lifelog exists but no Fireflies transcript | Only source for in-person meetings, ambient capture, missed recordings |
| 3 | **Calendar** | Event exists but no audio source | Metadata only — attendees, description, location |

#### Matching Logic

For each calendar event:
1. Check if a Fireflies transcript overlaps the event time window (within 5-minute tolerance)
2. If yes: mark as `source: fireflies` — **auto-skip in review** (already captured; use `/process-meeting` if needed)
3. If no: check if a Limitless lifelog overlaps the event time window
4. If yes: mark as `source: limitless` — **include in review** (pendant-only, would be lost otherwise)
5. If neither: mark as `source: calendar_only` — note as gap, no audio data

For Limitless lifelogs that don't overlap any calendar event:
- These are **ambient captures** (morning content, evening work, hallway conversations)
- Mark as `source: limitless_ambient`
- **Always include in review** — these are often the highest-value pendant captures

For Fireflies transcripts from team members (not on the user's calendar):
- Mark as `source: fireflies_team`
- **Show as brief 1-2 line summaries for awareness** — don't ask individual questions per meeting

#### Auto-Skip Rules

**The pendant review should ONLY focus on what is unique to the pendant.** Meetings already in Fireflies are already captured with higher quality (speaker IDs, structured summaries, action items). Do not re-review them.

**Auto-skip (show in summary table only, do not prompt for action):**
- Meetings with a matching Fireflies transcript
- Lifelogs categorized as `noise` (< 30 seconds or no meaningful content)
- Lifelogs categorized as `personal` (medical, family, casual chat)

**Include in interactive review:**
- Meetings with NO Fireflies transcript (in-person, missed recordings) — highest value
- Ambient idea captures (podcast content, brainstorming, content consumption)
- Work sessions (code analysis, data updates, project discussion)
- Hallway/informal conversations with actionable content

#### Categorize Each Entry

Assign a category based on content analysis:

| Category | Signal | Review? | Examples |
|----------|--------|---------|----------|
| `meeting` | Structured meeting with attendees | Only if no Fireflies | AICON, 1:1s, client calls |
| `idea` | New concept, insight, or inspiration | Yes | Podcast content, brainstorming |
| `work_session` | Active work discussion (code, data, design) | Yes | Evening code analysis, project details |
| `personal` | Non-work content | Auto-skip | Doctor appointments, casual chat |
| `noise` | Too short (<30s) or no meaningful content | Auto-skip | Brief acknowledgments, ambient noise |

#### Limitless API Timezone Note

The Limitless `date` parameter with the user's timezone returns lifelogs correctly in that timezone. However, the `start`/`end` range parameters appear to interpret timestamps differently — they may use the lifelog's internal UTC storage. **Always use the `date` parameter** for fetching a full day's data, not `start`/`end` ranges.

### Step 3: Match to Projects & Contacts

For each non-noise, non-personal entry, attempt to match against existing data:

#### Project Matching

Use the SessionStart manifest to match entries to projects by:
1. **Attendee email domain/address** → project routing rules
2. **Attendee name** → contacts table → project association
3. **Calendar event title** → project name fuzzy match
4. **Content keywords** → project name/description match
5. **Fireflies summary keywords** → project topic match

First, get all projects (the `projects` table has no `user_id` column — all rows are relevant):
```sql
SELECT id, name, slug, todoist_project_id FROM projects WHERE is_active = true ORDER BY name;
```

Then check routing rules. The `project_routing_rules` table uses `email_address` and `email_domain` columns (NOT `rule_type`/`rule_value`, and has no `user_id`):
```sql
SELECT project_name, project_id, email_domain, email_address
FROM project_routing_rules
WHERE email_domain IN ('domain1.com', 'domain2.com')
   OR email_address IN ('person1@example.com', 'person2@example.com');
```

Query contacts table for name matching:
```sql
SELECT id, display_name, email, organization
FROM contacts
WHERE display_name ILIKE '%{name}%'
LIMIT 5;
```

#### Contact Matching

For names mentioned in lifelogs (from `speakerName` fields or content), check:
```sql
SELECT id, display_name, email, organization, title
FROM contacts
WHERE display_name ILIKE '%{name}%'
OR organization ILIKE '%{term}%'
LIMIT 10;
```

### Step 4: Present Overview, Then Interactive Review

This step has two phases: a full-day overview, then focused review of pendant-unique content.

#### Phase 1: Full-Day Overview (non-interactive)

First, present the entire day as a single timeline table so the user sees the big picture. This is NOT interactive — just show it.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FULL DAY TIMELINE — {YYYY-MM-DD} ({user_timezone})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALREADY IN FIREFLIES (auto-skipped, use /process-meeting if needed):
  {HH:MM}  {title} ({duration} min) — Fireflies ID: {id}
  ...

NO FIREFLIES — PENDANT/CALENDAR ONLY (will review):
  {HH:MM}  {title} ({context})
  ...

PENDANT-ONLY AMBIENT (will review):
  {HH:MM}  {title} — {category}
  ...

TEAM MEETINGS (brief summaries below):
  {HH:MM}  {title} ({duration} min)
  ...

AUTO-SKIPPED:
  {count} personal/noise entries
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Phase 1B: Team Meeting Briefs (non-interactive)

For team Fireflies transcripts (meetings the user didn't attend), show 1-2 line summaries in a batch. Do NOT ask individual questions per meeting — just present for awareness:

```
TEAM MEETING BRIEFS:

[{HH:MM}] {title} ({duration} min)
  {1-2 sentence summary from Fireflies short_summary}

[{HH:MM}] {title} ({duration} min)
  {1-2 sentence summary}
```

#### Phase 2: Interactive Review (pendant-unique content only)

Now walk through ONLY the items that need user direction — pendant-unique captures. These fall into three buckets:

**Bucket 1: Missed meetings (no Fireflies)**
- Calendar event exists but Fireflies didn't capture it
- Show Limitless markdown if available, or calendar metadata
- Note this was likely in-person or the recording bot missed it
- Extract action items from pendant content manually
- These are highest-value — this data would be lost without the pendant

**Bucket 2: Ambient idea captures (podcast, content, brainstorming)**
- No calendar event, no Fireflies — pendant-only
- Summarize the key insight or idea in 2-3 sentences
- Great for morning podcast captures, walking thoughts, brainstorming

**Bucket 3: Work sessions (code, data, project discussion)**
- Evening or off-meeting-hours work captured by pendant
- Summarize what was being worked on

Present all items from these buckets together, then ask ONE question with all items listed. Use AskUserQuestion with multiSelect to let the user pick which ones to act on:

```
Which pendant-only captures should I process?
(Select all that apply)

[] [12:00] Martin Fay in-person meeting — log to {project}
[] [16:00] Sam Silver meeting (no Fireflies) — log to {project}
[] [08:02] AI management podcast insights — save as idea
[] [08:10] One-person billion-dollar startups — save as idea
[] [08:32] Colleague coached 1,300 founders — save action item
[] [21:27] Evening code analysis session — log to {project}
```

For selected items, ask one follow-up if needed (e.g., "Log Sam Silver to Sprint?") then execute.

### Step 5: Execute Actions

Based on user direction in Step 4, execute the chosen actions for each entry:

#### Log to Project

Write a log entry via `execute_sql`. Note: `project_id` is type `uuid`, so cast the string:

```sql
INSERT INTO log_entries (user_id, project_id, entry_date, session_title, content, source, metadata)
VALUES (
  '{user_id}'::uuid,
  '{project_db_id}'::uuid,
  '{YYYY-MM-DD}',
  '{entry title}',
  '{summary markdown}',
  '{limitless | fireflies | calendar}',
  '{
    "source_id": "{lifelog_id or transcript_id}",
    "source_type": "{limitless | fireflies | calendar}",
    "category": "{meeting | idea | work_session}",
    "attendees": [{attendee list}],
    "duration_minutes": {duration},
    "action_items_count": {count},
    "pendant_time_range": "{startTime} - {endTime}"
  }'::jsonb
);
```

#### Create Todoist Tasks

For action items the user approves, create tasks using the Todoist Sync API. See `/process-meeting/references/todoist-patterns.md` for the batch pattern.

Retrieve the Todoist API token from Vault via Supabase MCP (using the user_id resolved in Runtime Context):
```sql
SELECT decrypted_secret FROM vault.decrypted_secrets
WHERE name = 'user_' || '{user_id}' || '_todoist_api_token' LIMIT 1;
```

Build batch payload in Python, write to `/tmp/pendant-tasks.json`, then send via curl.

#### Save as Idea/Memory

For ideas the user wants to capture. The `memories` table has columns: `namespace`, `category`, `title`, `content`, `confidence`, `tags`, `source_type`, `source_id`, `source_project`. It does NOT have `user_id` or `metadata`:

```sql
INSERT INTO memories (namespace, category, title, content, source_type, source_id, source_project, confidence, tags)
VALUES (
  'user',
  'idea',
  '{short title}',
  '{idea description with context}',
  'limitless',
  '{lifelog_id}',
  '{project_slug or null}',
  'high',
  ARRAY['{tag1}', '{tag2}']
);
```

#### Log Contact Interaction

For meetings with matched contacts. The `interactions` table has columns: `contact_id` (uuid), `interaction_type` (text), `source_type` (text), `source_id` (text), `summary` (text), `occurred_at` (timestamptz). It does NOT have `user_id`, `interaction_date`, `source`, or `metadata`:

```sql
INSERT INTO interactions (contact_id, interaction_type, source_type, source_id, summary, occurred_at)
VALUES (
  '{contact_db_id}'::uuid,
  '{meeting | conversation | email}',
  '{limitless | fireflies | calendar}',
  '{lifelog_id or transcript_id}',
  '{brief summary}',
  '{YYYY-MM-DD}T{HH:MM:SS}{timezone_offset}'
)
ON CONFLICT DO NOTHING;
```

### Step 6: Present Summary

After processing all entries, show a final summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PENDANT DAILY REVIEW — {YYYY-MM-DD}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sources analyzed:
  Calendar events: {N}
  Fireflies transcripts: {N} ({N} yours, {N} team)
  Limitless lifelogs: {N}

Source selection:
  Fireflies (best source): {N} meetings
  Limitless (gap filler): {N} entries
  Calendar only (metadata): {N} events

Actions taken:
  Logged to projects: {N} entries across {N} projects
  Todoist tasks created: {N}
  Ideas captured: {N}
  Contact interactions logged: {N}
  Skipped: {N}

Projects touched:
  {Project 1}: {N} entries, {N} tasks
  {Project 2}: {N} entries, {N} tasks
  ...

Pendant-only captures (would have been lost without pendant):
  {List of entries that had no Fireflies or Calendar coverage}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Key Rules

- **All times in user's timezone** (from Runtime Context). Convert Fireflies UTC timestamps accordingly. Limitless API returns times in the user's timezone when the `timezone` parameter is passed.
- **Secrets from Vault** via Supabase MCP `execute_sql` querying `vault.decrypted_secrets`. The secret name format is `user_{user_id}_{label}` — construct dynamically using the user ID from Runtime Context. Do NOT use `get-secret.sh` as it depends on Keychain state that may not be available. Never hardcode tokens.
- **Generic tool references** in all instructions. Never hardcode MCP tool names. Use ToolSearch to discover tools at runtime.
- **User ID for DB writes:** Use the value resolved from `auth.uid()` in Runtime Context.
- **Python for JSON payloads.** Build batch payloads in Python, write to temp file, then curl.
- **Auto-skip Fireflies-covered meetings.** If a meeting has a Fireflies transcript, it's already captured with higher quality. Don't re-review it — just list it in the overview table. The user can run `/process-meeting` separately if needed.
- **Focus review on pendant-unique captures.** The interactive review should ONLY cover: missed meetings (no Fireflies), ambient ideas, work sessions, and actionable hallway conversations. This is the pendant's unique value.
- **Batch the review.** Present all reviewable items together and let the user multi-select which to act on. Don't ask one question per item — that's too granular. One multi-select question, then execute.
- **Fireflies wins over Limitless** when both cover the same meeting. Fireflies has speaker IDs, structured summaries, and pre-extracted action items.
- **Limitless is the gap filler** — it captures what Fireflies misses: in-person meetings, ambient conversations, podcast content, evening work sessions.
- **Calendar is the skeleton** — it provides attendee emails, meeting descriptions, and structure that neither audio source captures.

## Edge Cases

- **API returns max 10 lifelogs per direction**: Fetch both asc and desc, deduplicate by `id`. For very active days (>20 lifelogs), some mid-day entries may be missed. Note this to the user.
- **Fireflies timestamp offset**: Fireflies stores UTC. Convert using the user's timezone offset. A 5-minute tolerance window handles slight recording start/end differences.
- **In-person meetings**: Calendar shows a meeting, no Fireflies, Limitless may have captured it. Flag these — pendant-only data is highest-value.
- **Limitless speaker names all "Unknown"**: The pendant doesn't identify speakers well. Use Calendar attendees to infer who was talking.
- **Team Fireflies transcripts**: Present briefly for awareness. User didn't attend, so keep review lightweight.
- **No pendant data for parts of the day**: Pendant may have been off, out of range, or charging. Note gaps rather than assuming nothing happened.
- **Personal/medical content**: If a lifelog is clearly personal (medical appointments, family conversations), mark as `personal` and default to skip. Don't log to projects.
- **Limitless API key expired**: Flag the error and tell the user to update via Vault.
- **No project match**: Ask the user. If truly ad-hoc, either skip or log to the catch-all project.

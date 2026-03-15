---
name: scan
description: "Cross-project inbox scan — cleans noise, routes signals to projects, creates Todoist tasks for gaps, and ranks priorities by time block. Replaces /triage, /inbox-zero, and /sitrep."
argument-hint: ["(default: since last scan)" | "1h" | "2h" | "morning" | "afternoon" | "day" | "stale"]
context: fork
---

# Scan — Cross-Project Inbox Sweep

## Runtime Context

At the start of each scan, retrieve user context:

```sql
SELECT email, domain, timezone FROM user_profiles WHERE user_id = auth.uid()
```

Use the returned `email` for sent-mail queries (replacing any hardcoded sender address), `domain` for internal/external classification (e.g., filtering out internal-only emails, excluding your own domain from routing), and `timezone` for date calculations.

Store these values as `USER_EMAIL`, `USER_DOMAIN`, and `USER_TIMEZONE` for use throughout all phases.

## What This Does

One pass over all inboxes (Gmail + Slack DMs). Cleans noise, routes signals to projects, runs a deep scan per active project, creates Todoist tasks for gaps, **auto-closes tasks where follow-up was sent or a reply was received**, and ranks everything by priority. The result is a Todoist view (`@scan`) that always reflects what needs attention right now.

## Data Storage Rules

- **DB is source of truth** via Supabase MCP `execute_sql`. Discover MCP tools via `ToolSearch` at runtime — never hardcode tool names.
- **Project DB IDs** come from the SessionStart manifest (injected into context). Each project entry includes `DB ID`, `Slug`, `Todoist ID`, and `Path`.
- **User ID for all DB writes:** `auth.uid()` — never hardcode a user ID. All queries must use `auth.uid()` for RLS compatibility.
- **Graceful fallback:** If Supabase MCP is unavailable, fall back to file-only I/O. Skills never break from a DB outage.
- **Secrets from Vault:** Use `$OUTWORKOS_ROOT/scripts/get-secret.sh <label>` to retrieve API tokens at runtime.

## Arguments — Time Blocks

The argument controls how many items surface in the final output, not what gets scanned. The scan always processes everything since the last run.

| Argument | Items Surfaced | Output Style |
|----------|---------------|--------------|
| *(default)* | Top 5-7 items | Text summary |
| `1h` | Top 1-2 items | Single focus recommendation |
| `2h` | Top 3-4 items | Short priority list |
| `morning` | Top 5-7 items | Full morning block |
| `afternoon` | Top 5-7 items | Full afternoon block |
| `day` | All ranked items | Complete daily view |
| `stale` | All open tasks across all projects | Backlog maintenance — staleness review + proposals |

**IMPORTANT: Phases 0-5 are invariant.** The time block argument ONLY affects Phase 5d ranking (how many items surface) and Phase 6 output formatting. Never skip inbox cleaning, noise archival, signal archival, or resolved-email archival based on the time block argument. A `1hr` scan does the same cleaning work as a `day` scan — it just surfaces fewer items in the output.

---

## Phase 0: Load Rules + State + Credentials

### 0a. Load Scan Rules from DB

Query all active rules in one call:

```sql
SELECT id, rule_type, rule, context
FROM scan_rules
WHERE user_id = auth.uid()
  AND active = true
  AND (expires_at IS NULL OR expires_at > now())
ORDER BY rule_type, created_at;
```

Parse rules into working sets:
- **Noise filters:** `noise_sender`, `noise_domain`, `noise_subject`, `noise_sender_pattern`, `self_send` rules
- **Routing overrides:** `routing` rules (sender -> project, applied before the cascade)
- **Priority modifiers:** `priority` rules (boost/suppress projects)
- **Behavior instructions:** `behavior` rules (injected as directives)
- **Presentation instructions:** `presentation` rules (applied to output formatting)
- **Contact overrides:** `contact` rules (supplement context map contacts)
- **Thread ignores:** `ignore_thread` rules (skip specific threads)

### 0b. Load Last Scan State

**DB-first:** Query `skill_state` table:
```sql
SELECT state_value FROM skill_state
WHERE skill_name = 'scan' AND state_key = 'last_run';
```

Extract `last_run` timestamp to determine the scan window. If no state exists (first run), default to 7 days.

### 0c. Load Credentials

Run in parallel — read the detailed patterns in `references/api-patterns.md`:
1. **Gmail OAuth** — refresh access token from Vault credentials
2. **Todoist API token** — from Vault
3. **Contacts cache** — refresh if >24h old (see `references/api-patterns.md`)

### 0d. Todoist Sync + Label Reset

Read the detailed script in `references/todoist-patterns.md`:
1. Sync all Todoist data (items, labels, projects, sections) via Sync API
2. **Reset `scan` label** — clear from all tasks so it reflects only this run's output
3. **Create `scan` and `gap` labels** if they don't exist (color: charcoal)
4. Save sync data to `/tmp/scan-sync-data.json`, open items to `/tmp/scan-items.json`, projects to `/tmp/scan-projects.json`, sections to `/tmp/scan-sections.json`

---

## Phase 1: Clean + Scan Inboxes

Run Gmail and Slack scans in parallel. Read detailed patterns in `references/api-patterns.md`.

### 1a. Gmail — Archive Noise + Fetch Signals

Spawn a **Signal Agent** (subagent_type: `general-purpose`, model: `sonnet`). Pass it the Gmail access token, scan window, and noise filter rules from Phase 0a.

> **Quick mode gate:** If `GOOGLE_WORKSPACE_MODE` is `quick`, the Signal Agent runs all phases normally but SKIPS archival in phase 5 (no `batchModify` available). It still counts noise and filtered emails. Set `"archive_skipped": true` in output. The main scan notes: "Noise identified but not archived (quick mode). Switch to full mode to enable auto-archive."

The Signal Agent runs six phases:
1. **Fetch signal emails** — `in:inbox newer_than:Nd -category:promotions -category:social -category:forums -category:updates`. Extract message_id, thread_id, subject, from_name, from_email, date, is_important.
2. **Fetch and archive noise categories** — For each category (promotions, social, forums, updates), search `in:inbox category:{category}` to get message IDs. Collect all IDs for archival. Record counts per category.
3. **Bulk reply check** — `from:{USER_EMAIL} newer_than:Nd` (where `USER_EMAIL` comes from the Runtime Context lookup). Build a Set of replied thread_ids. Mark each signal email as `replied: true/false`.
4. **Apply noise filters** — check each signal email against noise_sender, noise_domain, noise_subject, noise_sender_pattern, self_send rules, and ignore_thread rules. Mark matches as filtered.
5. **Archive noise + filtered** — Gmail batchModify to remove INBOX + UNREAD labels from ALL noise category emails (from step 2) AND filtered signal emails (from step 4). This is not optional.
6. **Verify inbox** — Search `in:inbox` (no filters) and record the remaining count. This count is included in the output for the main scan to verify.

**Output:** `/tmp/scan-signal.json` — noise counts, signal emails with metadata + reply status, filtered emails.

### 1b. Slack DMs — Fetch New Direct Messages

Use Slack MCP tools (discovered via `ToolSearch: "+slack search"` at runtime).

1. Search for DMs since last scan:
   ```
   slack_search_public_and_private(
     query: "to:me",
     channel_types: "im",
     sort: "timestamp",
     sort_dir: "desc",
     after: "{last_scan_unix_timestamp}",
     limit: 20
   )
   ```
   Paginate if needed. Exclude bot messages (`include_bots: false`).

2. For each DM result, extract: sender user_id, sender name, message text (snippet), timestamp, channel_id, message_ts.

3. **Resolve sender identity**: For each unique sender user_id, call `slack_read_user_profile(user_id: "{id}")` to get their email address. This email is used for project routing in Phase 2.

4. For DM threads with multiple messages, use `slack_read_thread` to get full context (limit: 10 messages).

**Output:** `/tmp/scan-slack-dms.json`:
```json
{
  "dms": [
    {
      "source": "slack",
      "sender_name": "Jane Smith",
      "sender_email": "jane@company.com",
      "sender_slack_id": "U0ABC123",
      "channel_id": "D0XYZ789",
      "message_ts": "1234567890.123456",
      "snippet": "Hey, can you review the proposal?",
      "date": "2026-02-28",
      "thread_context": "..."
    }
  ],
  "total_found": 5
}
```

---

## Phase 2: Route Signals to Projects

Match each signal (email or Slack DM) to a project using a 5-tier cascade. **Routing overrides** from `scan_rules` (rule_type: `routing`) are checked first — if a sender has an override, skip the cascade.

### Build Routing Table

For each project in the SessionStart manifest that has a context map:
- **Read local files:** `$OUTWORKOS_PARENT/{ProjectName}/context-map.md` (use manifest project names to construct paths; `OUTWORKOS_PARENT` defaults from the environment)
- **Do NOT** bulk-query `context_map_md` from the DB — the combined result exceeds tool output limits and produces unparseable double-escaped JSON

Extract from each project's context map:
1. **Email addresses** — all emails mentioned, stored as `email -> project_slug`
2. **Organization domains** — derived from emails, excluding generic domains (gmail.com, hotmail.com, outlook.com, yahoo.com) and the user's own domain (`USER_DOMAIN` from Runtime Context)
3. **Subject keywords** — from `subject:"..."` patterns
4. **General keywords** — project names, org names, product/company names
5. **Project purposes** — full description text (for Tier 5 LLM fallback)

### Classification Cascade

Process each signal email and Slack DM through tiers in order, stopping at the first match:

| Tier | Method | Confidence |
|------|--------|------------|
| 0 | `routing` rule override (exact sender match) | Highest |
| 1 | Sender email exact match | High |
| 2 | Sender domain match — **exact emails only** | High |
| 2b | Sender domain match — **unknown sender from known domain** | Needs confirmation |
| 3 | Subject/snippet keyword match | Medium |
| 4 | Body/snippet email or keyword match | Medium |
| 5 | LLM batch fuzzy match (unmatched items) | Low |

**Tier 2b (unknown sender from known domain):** Do NOT auto-route. Mark as `domain_match_unconfirmed` and present to user at end of Phase 2 for confirmation (e.g., `Colin Conrad <colin.conrad@dal.ca> -> AICON (dal.ca) [route / skip / other]`). If confirmed, optionally create a `routing` rule. If skipped, falls through to Tier 3+. This prevents false positives from large domains (`dal.ca`, `rbc.com`, `acoa-apeca.gc.ca`).

**Special rule — Internal Email**: If both sender and recipient share the user's domain (`USER_DOMAIN`), only classify if a project keyword appears in subject/snippet (Tiers 3/4). Otherwise route to a catch-all project.

**Output:** `project_slug -> [signals]` mapping, saved to `/tmp/scan-routed-signals.json`.

---

## Phase 3: Identify Active Projects

A project is "active" (gets a deep-scan worker in Phase 4) if ANY of:

1. **Has new signals** — routed emails or Slack DMs from Phase 2
2. **Has overdue or due-today tasks** — from `/tmp/scan-items.json` (match by Todoist project ID from the manifest)
3. **Has imminent meetings** — Calendar events in the next 48h involving the project's stakeholder

### Calendar Check

Use Google Workspace MCP tools (discovered via `ToolSearch: "+google calendar"` at runtime):
- Fetch events for today + tomorrow
- Match events to projects by attendee email (from context maps) or event title keywords
- Save to `/tmp/scan-calendar-events.json` (including `htmlLink` per event)

### Priority Modifiers

Apply `priority` rules from `scan_rules`:
- `boost` projects get a worker even without signals (if they have any open tasks)
- `suppress: true` projects are skipped entirely (no worker, no output)

**Output:** List of active project slugs with their trigger reasons.

---

## Phase 4: Per-Project Deep Scan (Parallel Workers)

For each active project, spawn a worker agent. **Run all workers in parallel** using the Agent tool.

Read the detailed worker prompt in `references/worker-prompt.md`.

### Worker Agent Settings

| Setting | Value |
|---------|-------|
| `subagent_type` | `general-purpose` |
| `model` | `sonnet` |

### What Each Worker Does

1. **Load project context** — context map from DB or local file. Extract primary stakeholder email, Todoist project ID, person name.

2. **Filter Todoist tasks** — from `/tmp/scan-items.json`, filter to this project's Todoist ID. Categorize as overdue, due today, due tomorrow, upcoming (7 days).

3. **Scan data sources** (parallel within the worker):
   - **Gmail**: Build a scoped query from ALL email addresses in the context map's People section — `(from:{addr1} OR from:{addr2} OR ... OR to:{addr1} OR to:{addr2} OR ...)` last 7 days, fetch content. Do NOT use a broad single-contact query.
   - **Fireflies**: Search transcripts by participant email, last 7 days, pull summaries + action items
   - **Routed signals**: Read this project's signals from `/tmp/scan-routed-signals.json`

4. **Validate against sent mail**: Search `from:{USER_EMAIL} to:{stakeholder_email}` last 7 days. Build cross-reference matrix: for each (task x sent email), determine if action was taken. See `references/worker-prompt.md` for the full matrix protocol.

5. **Identify gaps**: Compare findings against existing Todoist tasks. An item is "untracked" if:
   - An email/DM requests action with no matching Todoist task
   - A meeting action item has no matching task
   - An upcoming event needs prep with no matching task
   - The user has NOT already responded (per sent-mail check)

6. **Return structured JSON**:
```json
{
  "project": "sprint",
  "project_name": "Sprint",
  "todoist_project_id": "6fxfXWp4qPqvX4wm",
  "tasks": {
    "overdue": [...],
    "due_today": [...],
    "due_tomorrow": [...],
    "upcoming": [...]
  },
  "action_taken": ["task_id_1", "task_id_2"],
  "gaps": [
    {
      "content": "Reply to Robert Newcombe — discovery call follow-up",
      "description": "**Why this is here:**\nRobert replied to the Sprint discovery thread on Feb 27. No response yet.\n\n**Sources:**\n- Gmail: \"Re: Discovery call\" — https://mail.google.com/mail/u/0/#inbox/{thread_id}",
      "priority": 3,
      "due_string": "today",
      "source_type": "gmail",
      "source_id": "thread_id_abc"
    }
  ],
  "upcoming_events": [...],
  "signals_summary": "2 new emails (1 thread reply), 1 Slack DM from Jane"
}
```

### Collecting Worker Results

- Wait for all workers to return
- If a worker times out (>90s) or returns invalid JSON: record `{"project": "NAME", "error": "timeout"}` and continue
- Collect all results into `/tmp/scan-worker-results.json`

---

## Phase 5: Create Tasks + Apply Labels + Rank

### 5a. Create Todoist Tasks for Gaps

Read the detailed patterns in `references/todoist-patterns.md`.

For each gap identified across all workers:
1. **Reply check**: If the gap's source_type is `gmail`, verify the thread_id is NOT in the replied thread_ids Set from Phase 1a. If it IS in the set, the user already replied — skip creation. This is a safety net for cases where the worker missed the `replied: true` flag.
2. **Dedup check**: Search existing tasks for matching source_id in description (`Sources:` block contains the same thread_id, transcript_id, or event link). If found, skip creation.
3. **Build task**: Content, description with `**Why this is here:**` and `**Sources:**` blocks, project_id, priority, due date, section_id (Triage section).
4. **Auto-create Triage/Do/Waiting/Defer sections** if the project lacks them.
5. **Apply `gap` label** to all newly created tasks.
6. **Batch all commands** into a single Todoist Sync API call.

### 5b. Apply `scan` Label

After creating gap tasks, apply the `scan` label to every task that should appear in the current scan's Todoist view:
- All tasks due today or overdue (from any active project)
- All tasks due tomorrow (if morning/day block)
- All newly created gap tasks
- All tasks explicitly referenced by workers as needing attention
- Exclude tasks flagged as `action_taken` by workers

Use a single Sync API batch call to apply the label. Read the pattern in `references/todoist-patterns.md`.

### 5c. Archive Resolved Gmail

> **Quick mode gate:** If `GOOGLE_WORKSPACE_MODE` is `quick`, skip Phase 5c archival entirely. Still run the inbox count query via built-in `gmail_search_messages(q: "in:inbox")` for reporting, but do not attempt `batchModify`. Note in output: "N emails identified for archival but left in inbox (quick mode)."

For each signal email that now has a clear disposition, archive it:

| Disposition | Archive? |
|-------------|----------|
| Replied + task exists in Todoist | Yes |
| Replied + no task needed | Yes |
| Unreplied + task just created | Yes |
| Unreplied + task already existed | Yes |
| Not important + unknown sender + no task | Yes |
| Needs human decision (ambiguous) | No — leave in inbox |

Use Gmail batchModify to remove INBOX + UNREAD labels. Process in batches of 1,000 max.

### 5c-verify. Inbox Verification Gate (REQUIRED)

After all archival operations (noise categories, filtered emails, resolved signals), query `in:inbox` with NO filters to get the true remaining inbox count. If count > 0, fetch metadata for all remaining messages.

**For each remaining message, run these checks in order:**

1. **Noise filter check** — apply all `scan_rules` noise filters. If matched -> archive immediately, note the gap in noise rules.
2. **Todoist cross-reference** — load `/tmp/scan-items.json` (all open Todoist tasks). For each remaining email:
   - Search task descriptions for the email's `thread_id` (in `Sources:` blocks or `#inbox/` links)
   - Fuzzy-match the email subject/sender against task `content` fields (same topic = match)
   - If ANY open task tracks this email -> **archive** (it's already in Todoist)
3. **Sent-mail reply check** — for remaining emails not caught by step 2, check if the email's `thread_id` appears in the sent-mail Set built during Phase 1a. If the user has already replied AND the email doesn't require further action -> **archive**.
4. **Classify survivors** — anything still remaining after steps 1-3:
   - **Needs human decision** (ambiguous, unreplied, no task, from a known contact) — leave in inbox, list in "Still in Inbox" output section
   - **Not important + unknown sender** — archive immediately

**This gate must process ALL remaining inbox messages, including those older than the scan window.** Many inbox stragglers are emails that pre-date `newer_than:Nd` from Phase 1a but already have a corresponding Todoist task — step 2 catches these.

**Never report "inbox clear" without running this verification.** The inbox count from this step is the authoritative number shown in the output.

### 5d. Rank Across Projects

Merge all task lists from all workers. Apply the priority stack:

1. **Overdue tasks** — past due date
2. **Meeting prep** — events in next 48h needing preparation
3. **Awaiting response** — someone is waiting on the user
4. **High priority** — Todoist p4/p3 tasks
5. **Deadlines this week** — due in next 7 days
6. **Gap tasks** — newly created from this scan
7. **Everything else** — by creation order (oldest first)

Within each tier:
- Prefer tasks that unblock other people
- Apply `priority` boost/suppress rules from `scan_rules`
- Cross-project tiebreaker: project with an imminent meeting wins

Filter to the time block's item count (see Arguments table).

### 5e. Check Reply Tracking

Check all emails the user is waiting on a reply for. Query the tracking table:

```sql
SELECT id, gmail_thread_id, recipient_name, recipient_emails,
       subject, summary, sent_at, todoist_task_id, project_slug
FROM reply_tracking
WHERE user_id = auth.uid()
  AND status = 'waiting'
ORDER BY sent_at ASC;
```

For each tracked item, check **three channels** for a response (run all checks in parallel):

#### 1. Email Reply Check
Search Gmail for new messages in the thread from the recipient:
```
thread:{thread_id} from:{recipient_email}
```
If any message exists with a date AFTER `sent_at`, mark as reply detected via `email`.

#### 2. Calendar Booking Check
Search Calendar for new events with the recipient as an attendee, created after `sent_at`:
- Use Google Workspace Calendar tools to search events in the next 30 days
- Match by recipient email in attendee list
- If a new event exists that was created after `sent_at`, mark as reply detected via `calendar`

#### 3. Slack Message Check
Search Slack for DMs from the recipient since `sent_at`:
```
slack_search_public_and_private(
  query: "from:{recipient_slack_id_or_name}",
  channel_types: "im",
  after: "{sent_at_unix}",
  limit: 5
)
```
If any DM exists from the recipient after `sent_at`, mark as reply detected via `slack`.

#### Processing Results

**Reply detected:**
1. Update the DB record — set status to `'replied'` immediately:
   ```sql
   UPDATE reply_tracking
   SET status = 'replied',
       reply_detected_at = now(),
       reply_channel = '{channel}',
       reply_summary = '{brief description of the reply}'
   WHERE id = '{tracking_id}';
   ```

2. If `todoist_task_id` exists: **add to the completion batch** (collected in Phase 5f). The linked task will be closed automatically.
3. Add to "Completed — Reply Received" output section with channel and summary.

**No reply detected:**
- Calculate age: `days_waiting = now() - sent_at`
- Add to "Waiting for Reply" output section with age
- If 7+ days: append "(Consider following up)" suggestion

### 5f. Close Completed Tasks (Batch)

Collect all tasks that should be auto-closed based on evidence gathered during this scan:

1. **Action-taken tasks** — all `action_taken` task IDs from worker results (Phase 4). These are tasks where sent mail confirms the user already acted.
2. **Reply-received tasks** — all `todoist_task_id` values from reply tracking items where a reply was detected (Phase 5e).

Deduplicate (a task may appear in both lists). Build a single Todoist Sync API batch:

```python
import json, uuid

completion_ids = set()

# From worker results
for worker in all_worker_results:
    for task_id in worker.get('action_taken', []):
        completion_ids.add(task_id)

# From reply tracking (Phase 5e detections)
for tracked in reply_detections:
    if tracked.get('todoist_task_id'):
        completion_ids.add(tracked['todoist_task_id'])

commands = []
for task_id in completion_ids:
    commands.append({
        'type': 'item_close',
        'uuid': str(uuid.uuid4()),
        'args': {'id': task_id}
    })

if commands:
    payload = {'commands': commands}
    with open('/tmp/scan-complete-batch.json', 'w') as f:
        json.dump(payload, f)
```

Then send:
```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
curl -s -X POST "https://api.todoist.com/api/v1/sync" \
  -H "Authorization: Bearer $TODOIST_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/scan-complete-batch.json
```

Report in output: "Completed {N} tasks ({A} follow-up confirmed, {R} reply received)."

**Skip the `scan` label for completed tasks** — they're done, no need to surface them.

---

## Phase 6: Present Results + Capture Feedback

### Output Format

```
## Scan Complete — {date} {time_block}

**Focus:** {top 1 item with 1-sentence rationale}

### Priority List ({count} items)

{Numbered list, each showing:}
1. **[Task name]** — [Project] (due: [date])
   [1-line context: why this, why now]
   [Gmail](link) / [Slack](link) / [Calendar](link)

### New Tasks Created ({count})

{Numbered list of gap tasks with source}

### Completed — Follow-Up Sent ({count})

{Tasks where sent mail confirms the user already acted. Auto-closed this scan.}

1. **{Task name}** — {Project} ~~(was: due {date})~~
   Evidence: Sent "{email subject}" on {date}

### Completed — Reply Received ({count})

{Tracked emails where a reply was detected. Linked Todoist tasks auto-closed, reply_tracking status set to 'replied'.}

1. **{Recipient Name}** — "{Subject}" (sent {N} days ago)
   Reply via {channel}: {brief reply summary}

### Waiting for Reply ({count})

{Emails the user is waiting on a reply for, ordered by age (oldest first).}

1. **{Recipient Name}** — "{brief what was asked}" ({N} days)
2. **{Recipient Name}** — "{brief what was asked}" ({N} days) -- Consider following up

{Items 7+ days old get the "Consider following up" suggestion.}

### Still in Inbox ({count})

{Signal emails/DMs left for human decision — not auto-archived}

### Noise Cleared

{Promotions: N, Social: N, Forums: N, Updates: N, Filtered: N}

---
Any corrections? (e.g., "emails from X are noise", "route Y to project Z")
```

### Reply Tracking Feedback

Completions from Phase 5f are automatic — no confirmation needed. The user can still provide corrections:

**If the user says a completion was wrong** (e.g., "reopen #2", "that wasn't resolved"):
1. Reopen the Todoist task via Sync API (`item_uncomplete`, `args: {id: task_id}`)
2. Reset the reply_tracking record:
   ```sql
   UPDATE reply_tracking
   SET status = 'waiting', reply_detected_at = NULL, reply_channel = NULL, reply_summary = NULL
   WHERE id = '{tracking_id}';
   ```

**If the user wants to dismiss/stop tracking** (e.g., "dismiss #3", "don't need a reply anymore"):
```sql
UPDATE reply_tracking SET status = 'dismissed' WHERE id = '{tracking_id}';
```
Then complete the linked Todoist task (if not already closed).

### Feedback Capture

If the user provides corrections after the scan, parse into `scan_rules` rows and insert:

```sql
INSERT INTO scan_rules (user_id, rule_type, rule, context, source, active)
VALUES (
  auth.uid(),
  '{rule_type}',        -- noise_sender, noise_domain, routing, priority, etc.
  '{rule_value}',       -- e.g., "newsletter@service.com" or "colin.conrad@dal.ca -> aicon"
  '{user_feedback_text}', -- original user words for audit trail
  'user_feedback',
  true
);
```

**Parsing examples:**
- "emails from X are noise" -> `rule_type: 'noise_sender'`, `rule: 'X'`
- "route Y to project Z" -> `rule_type: 'routing'`, `rule: 'Y -> Z'`
- "ignore threads about newsletters" -> `rule_type: 'noise_subject'`, `rule: 'newsletters'`

Confirm: "Rule created: [description]. Will apply on next scan."

### Auto-Detected Rule Proposals

If the scan notices patterns:
- A sender has appeared in 3+ scans and never resulted in a task -> propose `noise_sender` rule
- A sender always routes to the same project -> propose `routing` rule
- A project has had no activity in 30+ days -> propose `priority` suppress rule

Store proposals as `active: false`, `source: 'auto_detected'`. Show in output:
```
### Suggested Rules
- "noreply@service.com" appeared 4 times, never actioned -> add as noise? [y/n]
```

---

## Phase 7: Update State

**DB-first (primary):** Upsert into `skill_state`:
```sql
INSERT INTO skill_state (user_id, skill_name, state_key, state_value)
VALUES (auth.uid(), 'scan', 'last_run', '{
  "last_run": "{ISO-8601 timestamp}",
  "emails_processed": N,
  "slack_dms_processed": N,
  "noise_archived": N,
  "signal_archived": N,
  "tasks_created": N,
  "tasks_completed": N,
  "tasks_completed_action_taken": N,
  "tasks_completed_reply_received": N,
  "scan_label_applied": N,
  "projects_scanned": N
}')
ON CONFLICT (user_id, skill_name, state_key)
DO UPDATE SET state_value = EXCLUDED.state_value, updated_at = now();
```

**Update rule freshness:** For every `scan_rules` row that was actually used during this scan:
```sql
UPDATE scan_rules SET last_applied_at = now()
WHERE id = ANY(ARRAY['{used_rule_ids}']);
```

**Stale rule check:** If any active rules have `last_applied_at` older than 90 days, mention in the output: "N rules haven't matched anything in 90+ days — review with `/scan rules`?"

---

## Compatibility with /whats-next

`/whats-next` remains a standalone single-project deep dive. The two skills share data but don't conflict:

- **Shared cache:** Both use `/tmp/todoist-sync-cache.json` (5-minute TTL). If `/scan` ran recently, `/whats-next` reuses cached Todoist data.
- **No label conflict:** `/whats-next` never touches the `scan` label. It may create tasks with the `gap` label (same dedup logic — check source_id in description before creating).
- **No signal conflict:** `/scan` doesn't write to a `signals` table. Both skills use Todoist as the system of record. Dedup is by source_id in task descriptions.
- **Todoist is the shared state:** Both skills read and write to Todoist. The `scan` label is ephemeral (reset each run). The `gap` label is sticky (stays until user triages).

---

## Edge Cases

| Condition | Behavior |
|-----------|----------|
| No context maps | Noise clearing + Todoist overdue only. Skip workers. |
| Todoist 401/403 | Stop. Direct user to `set-secret.sh todoist_api_token <new>` |
| Gmail OAuth expired | Direct user to `$OUTWORKOS_ROOT/scripts/google-auth.sh` |
| Slack/Fireflies MCP unavailable | Log warning, continue without. Non-fatal. |
| No new signals | Rank existing Todoist tasks only. Don't force-create work. |
| Worker timeout (>90s) | Record error, continue with other workers. Note in output. |
| First run (no state) | 7-day lookback for Gmail, process all inbox for noise clearing. |

---

## Stale Mode (`/scan stale`)

Backlog maintenance mode. Reviews ALL open tasks across ALL context-mapped projects, checks source artifacts for freshness, and proposes priority/due-date/section/completion changes. The user approves before anything is applied.

**Key difference from default mode:** Stale mode skips Phases 1-3 entirely (no inbox scanning). It's about the backlog, not the inbox.

### Phase Flow

| Phase | What Happens | Reused From |
|-------|-------------|-------------|
| Phase 0 | Load rules, state, credentials, Todoist sync + label reset | Reused entirely |
| Phase S1 | Group all open tasks by project | New |
| Phase S2 | Spawn stale workers in parallel | New (same Agent pattern as Phase 4) |
| Phase S3 | Collect proposals, present for approval | New |
| Phase S4 | Apply approved changes via Todoist Sync API batch | New |
| Phase 7 | Update `skill_state` with `stale_last_run` | Adapted |

### Phase S1: Group Tasks by Project

From `/tmp/scan-items.json` (loaded in Phase 0d), group all open tasks by their Todoist project ID. Cross-reference against the SessionStart manifest to get project names, slugs, stakeholder info, and context map paths.

A project gets a stale worker if it has **>= 1 open task** in Todoist.

For each project with tasks:
1. Filter tasks from `/tmp/scan-items.json` by `project_id`
2. Filter sections from `/tmp/scan-sections.json` by `project_id`
3. Read context map from `$OUTWORKOS_PARENT/{ProjectName}/context-map.md` to extract stakeholder name/email
4. Bundle task list, sections, stakeholder info, and today's date for the worker prompt

### Phase S2: Spawn Stale Workers (Parallel)

For each project with open tasks, spawn a stale worker agent. **Run all workers in parallel** using the Agent tool.

Read the detailed worker prompt in `references/stale-worker-prompt.md`.

#### Worker Agent Settings

| Setting | Value |
|---------|-------|
| `subagent_type` | `general-purpose` |
| `model` | `sonnet` |
| `name` | `stale-worker-{project_slug}` |

Each worker:
- Receives ALL open tasks for that project, sections, stakeholder info, today's date
- Categorizes each task by staleness (age, no due date, section stagnation, source link freshness)
- For tasks with Gmail source links: checks thread for new replies or resolution
- Searches sent mail to stakeholder for completion evidence (one batch query per project)
- Checks calendar for upcoming meetings with stakeholder
- Returns JSON with one proposal per task: `complete`, `reprioritize`, `add_due_date`, `move_section`, or `no_change`

#### Collecting Worker Results

- Wait for all workers to return
- If a worker times out (>90s) or returns invalid JSON: record `{"project": "NAME", "error": "timeout"}` and continue
- Collect all results into `/tmp/scan-stale-results.json`

### Phase S3: Present Proposals for Approval

Group proposals by action type and present in tables. **Do not apply any changes until the user approves.**

#### Output Format

```
## Backlog Review — {date}

Reviewed {total_tasks} tasks across {project_count} projects.

### Likely Complete ({count})

Tasks where sent mail or source evidence confirms action was taken.

| # | Task | Project | Evidence | Approve? |
|---|------|---------|----------|----------|
| 1 | Reply to Jane — proposal follow-up | Sprint | Sent "Attached the updated proposal" on Feb 15 | Y |
| 2 | Send contract to Alex | Scale AI | Thread archived, reply sent Feb 20 | Y |

### Needs Attention ({count})

Tasks that should be reprioritized or given a due date based on new activity.

| # | Task | Project | Reason | Proposed Change |
|---|------|---------|--------|-----------------|
| 3 | Prepare board deck | Morrison Park | Board meeting Mar 10, no due date | Add due: Mar 8, priority: High |
| 4 | Review partnership terms | AICON | New reply received Feb 28 | Priority: Normal -> High |

### Consider Deferring ({count})

Tasks 30+ days old with no source activity, no due date, and no stakeholder communication.

| # | Task | Project | Age | Last Activity |
|---|------|---------|-----|---------------|
| 5 | Follow up on partnership | RBCx | 42 days | No sent mail in 35 days |
| 6 | Research competitor pricing | BAI Metrics | 38 days | No source activity |

### No Changes ({count})

{count} tasks across {project_count} projects are fresh and correctly prioritized.

---
Approve all? Or specify by number (e.g., "approve 1,2,3,5" or "skip 4").
```

#### Approval Handling

- **"approve all"** or **"yes"** — apply all proposed changes
- **"approve 1,2,5"** — apply only the numbered proposals
- **"skip 4"** — apply all except the listed numbers
- **"none"** — skip all changes
- Any freeform feedback is treated as corrections (e.g., "don't complete #2, I still need to follow up")

### Phase S4: Apply Approved Changes

Read the batch pattern in `references/todoist-patterns.md` (Phase S4 section).

Build a single Todoist Sync API batch with all approved changes:
- `item_close` for completions
- `item_update` for priority changes and due date additions
- `item_move` for section moves (requires section_id lookup from `/tmp/scan-sections.json`)

Send as one API call. Report results:
```
### Changes Applied

- Completed: {n} tasks
- Reprioritized: {n} tasks
- Due dates added: {n} tasks
- Moved to Defer: {n} tasks
- Errors: {n}
```

### Phase 7 (Stale): Update State

**Separate state key.** `stale_last_run` is independent of `last_run`, so running `/scan stale` doesn't affect the next normal `/scan` window.

```sql
INSERT INTO skill_state (user_id, skill_name, state_key, state_value)
VALUES (auth.uid(), 'scan', 'stale_last_run', '{
  "last_run": "{ISO-8601 timestamp}",
  "tasks_reviewed": N,
  "projects_reviewed": N,
  "proposals_made": N,
  "proposals_approved": N,
  "completed": N,
  "reprioritized": N,
  "due_dates_added": N,
  "deferred": N
}')
ON CONFLICT (user_id, skill_name, state_key)
DO UPDATE SET state_value = EXCLUDED.state_value, updated_at = now();
```

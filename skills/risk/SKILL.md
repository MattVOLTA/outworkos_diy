---
name: risk
description: "Cross-project risk analyzer — identifies open Todoist tasks where follow-through is missing by cross-referencing sent mail, project logs, and calendar. Scores risk by temporal compounding, escalates Todoist priorities for Critical/At Risk items, and sends Pushover alerts. Use daily, when asking 'what have I dropped', or to audit follow-through across projects."
argument-hint: ["(default: all projects)" | "sprint" | "bai-metrics" | "all"]
context: fork
---

# Risk — Follow-Through Analyzer

## What This Does

Scans open Todoist tasks across all (or one) project, cross-references against sent email, project logs, and calendar to determine whether commitments have been actioned. Scores each unactioned item by how long it's been neglected and how serious the gap is. Automatically escalates Todoist priorities for Critical and At Risk items, and sends a Pushover notification.

## Runtime Context

At the start of every run, look up the current user's profile to get dynamic values. Use Supabase MCP tools (discover via ToolSearch at runtime) to execute:

```sql
SELECT id AS user_id, email, display_name, timezone
FROM user_profiles
WHERE id = auth.uid()
LIMIT 1;
```

Use the returned values throughout this skill:
- `user_id` — for all DB reads/writes (replaces any hardcoded UUID)
- `email` — for Gmail sent-mail searches (e.g., `from:{email}`)
- `display_name` — for display purposes
- `timezone` — for date calculations

If `auth.uid()` is not available in your SQL context, retrieve the user ID from the session environment or manifest instead.

## Data Storage Rules

- **DB is source of truth** via Supabase MCP `execute_sql`. Discover MCP tools via `ToolSearch` at runtime — never hardcode tool names.
- **Project DB IDs** come from the SessionStart manifest (injected into context). Each project entry includes `DB ID`, `Slug`, `Todoist ID`, and `Path`.
- **User ID for all DB writes:** Use `auth.uid()` in SQL or the `user_id` from the Runtime Context lookup above.
- **Secrets from Vault:** Use `$OUTWORKOS_ROOT/scripts/get-secret.sh <label>` to retrieve API tokens at runtime.

## Arguments

| Invocation | Behavior |
|---|---|
| `/risk` | All projects with open tasks + Todoist IDs |
| `/risk sprint` | Single project by name or slug |
| `/risk all` | Explicit all-projects scan |

Matching is case-insensitive against both project **name** and **slug** from the SessionStart manifest.

---

## Risk Rubric

### Five Risk Signals

| # | Signal | Description | Base Weight |
|---|---|---|---|
| 1 | **Commitment breach** | Promised something (in sent email or meeting) with no evidence of delivery | 5 |
| 2 | **Unanswered inbound** | Stakeholder sent a message and no reply exists | 4 |
| 3 | **Meeting without follow-through** | Meeting occurred but no tasks created or emails sent afterward | 3 |
| 4 | **Communication decay** | No outbound email to stakeholder while tasks are open | 2 |
| 5 | **Stale engagement** | Zero activity across all sources for a project with open commitments | 1 |

### Temporal Compounding

Risk compounds non-linearly with time. Days are measured from the most recent evidence of activity (sent email, log entry, task completion) for that specific task or stakeholder.

| Tier | Label | Days Since Last Activity | Time Multiplier |
|---|---|---|---|
| 0 | **Clear** | 0–3 | 1.0 |
| 1 | **Watch** | 4–5 | 1.5 |
| 2 | **At Risk** | 6–7 | 3.0 |
| 3 | **Critical** | 7+ | 5.0 |

### Scoring

```
risk_score = base_weight x time_multiplier
```

A commitment breach at 8 days = 5 x 5.0 = **25** (critical)
Communication decay at 4 days = 2 x 1.5 = **3** (watch)

Projects are ranked by their **highest single risk score**. Tasks within a project are ranked by individual score descending.

### Per-Project Threshold Overrides

Some projects have different natural cadences. Check the context map for a `Risk Cadence` field. If present, use those thresholds instead of defaults. If absent, use defaults.

Example override: `Risk Cadence: 30/60/90` means Watch at 30 days, At Risk at 60, Critical at 90 (for quarterly-cadence projects like Board Communication).

### What Does NOT Get Flagged

- Projects with no open Todoist tasks (dormant by design)
- Tasks in the **Waiting** section with evidence of a recent handoff email (ball is in their court)
- Tasks in the **Defer** section (explicitly parked)
- Internal-only tasks with no external stakeholder
- Routine automated notifications or newsletters
- **Conversational closure** — stakeholder replies that are confirmations ("that works", "sounds good"), delegations to a third party ("@Gina, can you set up..."), or informational with no call to action directed at the user. These do not count as unanswered inbound.
- **Scheduling tasks with calendar confirmation** — if a task is about scheduling a meeting and a matching calendar event exists within the next 7 days with the same stakeholder, treat as Clear regardless of email thread state.

---

## Phase 0: Load State + Todoist Sync

### 0a. Resolve Target Projects

If an **argument** was provided:
1. Normalize to lowercase
2. Match against SessionStart manifest by project name (case-insensitive) or slug
3. If found, scope to that single project
4. If no match, list available projects with Todoist IDs

If **no argument** or `all`:
1. Get all projects from the manifest that have a `Todoist ID`
2. These are the candidates for Phase 1

### 0b. Todoist Sync + Label Reset (Shared Cache)

Reuse the shared Todoist sync cache. Read the script in `references/api-patterns.md`.

1. Check `/tmp/todoist-sync-cache.json` — if fresh (< 5 min), reuse `/tmp/scan-items.json`
2. If stale, do a full sync: items, sections, projects, labels
3. Save to `/tmp/risk-items.json`, `/tmp/risk-sections.json`
4. **Create `risk` label** if it doesn't exist (color: `red`)
5. **Reset `risk` label** — clear from all tasks so it reflects only this run's output (same pattern as `/scan` resets the `scan` label)

### 0c. Filter to Active Projects

From the synced items, identify which candidate projects actually have open tasks:
- Filter items by `project_id` matching each candidate's Todoist ID
- Exclude tasks in **Defer** sections (look up section names from sections data)
- A project qualifies for a risk worker if it has >= 1 non-deferred open task

**Output:** List of qualifying projects with their task counts.

---

## Phase 1: Spawn Per-Project Risk Workers (Parallel)

For each qualifying project, spawn a worker agent. **Run all workers in parallel.**

Read the detailed worker prompt in `references/worker-prompt.md`.

### Worker Agent Settings

| Setting | Value |
|---|---|
| `subagent_type` | `general-purpose` |
| `name` | `risk-worker-{project_slug}` |

### What Each Worker Does

1. **Load project context** — context map from local file at `$OUTWORKOS_PARENT/{ProjectName}/context-map.md`. Extract stakeholder names, emails, person-to-email mappings.

2. **Get open tasks** — from `/tmp/risk-items.json`, filter to this project's Todoist ID. Exclude Defer section tasks.

3. **Search sent mail** — for each person in the context map, search all their known email addresses. Use the `email` from the Runtime Context lookup (user_profiles) as the sender:
   ```
   from:{user_email} (to:{email1} OR to:{email2}) newer_than:30d
   ```
   Fetch full content for each result. Build evidence pool.

4. **Query project logs** — via Supabase MCP, query `log_entries` for this project:
   ```sql
   SELECT logged_at, summary, details FROM log_entries
   WHERE project_id = '{project_db_id}'
     AND logged_at > now() - interval '30 days'
   ORDER BY logged_at DESC LIMIT 20;
   ```

5. **Check calendar** — search for meetings with stakeholder in the past 14 days and next 7 days.

6. **Score each task** — for every open task, evaluate all 5 risk signals. Compute `days_since_last_activity` by finding the most recent evidence across:
   - Sent email to the relevant person
   - Log entry mentioning the task topic
   - Calendar meeting with the stakeholder
   - Task modification date

7. **Return structured JSON** — see `references/worker-prompt.md` for the full schema.

### Collecting Worker Results

- Wait for all workers to return
- If a worker times out (>90s) or returns invalid JSON: record `{"project": "NAME", "error": "timeout"}` and continue
- Collect all results into `/tmp/risk-results.json`

---

## Phase 2a: Auto-Close Resolved Tasks

Before scoring or escalating, collect all tasks from worker results where `auto_close: true` (tier `"resolved"`). These are tasks where the worker found evidence the action was already taken but the Todoist checkbox was never ticked.

### Build Auto-Close Batch

```python
close_ids = []
for result in all_worker_results:
    for risk in result.get('risks', []):
        if risk.get('tier') == 'resolved':
            close_ids.append(risk['task_id'])
```

### Execute via Todoist Sync API

```python
import uuid
commands = []
for task_id in close_ids:
    commands.append({
        'type': 'item_close',
        'uuid': str(uuid.uuid4()),
        'args': {'id': task_id}
    })
```

Send as a single Sync API batch (same pattern as Phase 2b). If the list is empty, skip.

**Exclude resolved tasks from all subsequent phases** — they should not be scored, escalated, labeled, or included in the notification. They appear only in the "Auto-Closed" section of the output (Phase 4).

---

## Phase 2: Synthesize + Rank

Merge all worker results, **excluding resolved/auto-closed tasks**. For each project:
1. Take the highest-scored risk item as the project's headline risk
2. Count items per tier (Critical / At Risk / Watch / Clear)

Rank projects by highest single risk score descending.

Cross-project pattern detection:
- If 3+ projects have Critical items, note "systemic follow-through gap"
- If a single person appears in risk items across multiple projects, note "multi-project stakeholder at risk: {name}"

---

## Phase 2b: Escalate Todoist Priorities

Automatically escalate task priorities for Critical and At Risk items. **Only escalates, never downgrades.** If a task is already at or above the target priority, skip it.

### Escalation Rules

| Risk Tier | Target Priority | Todoist Value | Condition |
|---|---|---|---|
| Critical (7+ days) | P1 (Urgent) | `priority: 4` | Only if current priority < 4 |
| At Risk (6-7 days) | P2 (High) | `priority: 3` | Only if current priority < 3 |
| Watch | No change | — | — |
| Clear | No change | — | — |

### Build Batch Update

Collect all tasks that need escalation from the merged worker results:

```python
escalations = []
for result in all_worker_results:
    for risk in result.get('risks', []):
        if risk['tier'] == 'critical' and risk.get('priority', 4) < 4:
            escalations.append({'task_id': risk['task_id'], 'old_priority': risk['priority'], 'new_priority': 4, 'task_content': risk['task_content'], 'project': result['project_name'], 'tier': 'critical'})
        elif risk['tier'] == 'at_risk' and risk.get('priority', 3) < 3:
            escalations.append({'task_id': risk['task_id'], 'old_priority': risk['priority'], 'new_priority': 3, 'task_content': risk['task_content'], 'project': result['project_name'], 'tier': 'at_risk'})
```

If `escalations` is empty, skip the API call.

### Apply via Todoist Sync API

Read the batch update pattern in `references/api-patterns.md` (Phase 2b section).

Build `item_update` commands for each escalation and send as a single Sync API batch call. Record which tasks were escalated for Phase 4 output.

### Apply `risk` Label

In the same Sync API batch call, apply the `risk` label to ALL Critical and At Risk tasks (not just those whose priority changed). This includes tasks already at or above the target priority.

For each Critical or At Risk task, add `risk` to its existing labels array:
```python
labels = list(set(task['labels'] + ['risk']))
```

This makes `@risk` a live Todoist filter showing everything that needs attention right now. The label is ephemeral — reset at the start of each run (Phase 0b), so it always reflects the latest assessment.

---

## Phase 3: Pushover Notification

If ANY items scored **At Risk** (tier 2) or **Critical** (tier 3), send a Pushover notification.

### Build Notification

**Title:** `Risk Alert: {count} items need attention`

**Message:** List the top 3 highest-scored items (max 500 chars for Pushover):
```
CRITICAL: Sprint — Reply to Robert re: pipeline (8d)
CRITICAL: Scale AI — Send contract to Alex (12d)
AT RISK: AICON — Follow up with Colin (7d)
{count - 3} more items. Run /risk for full report.
```

**Priority:** If any Critical items exist, use priority `1` (high — bypasses quiet hours). Otherwise use priority `0` (normal).

**URL:** Link to the `@risk` label view in Todoist so tapping the notification opens all flagged tasks:
- Label view URL: `https://app.todoist.com/app/label/risk`
- Use the `url` and `url_title` Pushover parameters

### Send Notification

```bash
_ROOT="${OUTWORKOS_ROOT:?OUTWORKOS_ROOT not set}"
PUSHOVER_API_TOKEN=$("$_ROOT/scripts/get-secret.sh" pushover_api_token)
PUSHOVER_USER_KEY=$("$_ROOT/scripts/get-secret.sh" pushover_user_key)

# PRIORITY: 1 if any Critical items, 0 otherwise

curl -s -o /dev/null -w "%{http_code}" \
  --form-string "token=$PUSHOVER_API_TOKEN" \
  --form-string "user=$PUSHOVER_USER_KEY" \
  --form-string "title=Risk Alert: {count} items" \
  --form-string "message={message}" \
  --form-string "priority=$PRIORITY" \
  --form-string "sound=siren" \
  --form-string "url=https://app.todoist.com/app/label/risk" \
  --form-string "url_title=View all risk items in Todoist" \
  https://api.pushover.net/1/messages.json
```

If NO items are At Risk or Critical, skip the notification entirely. Don't send "all clear" — silence means no risk.

---

## Phase 4: Present Results

```
## Risk Report — {date}

### Auto-Closed ({count})

Tasks completed in Todoist — evidence confirms the action was already taken.

| Task | Project | Evidence |
|------|---------|----------|
| Find and review Gina's renewal agreement | RBCx | Sent "Just signed the 2026 partnership agreement" on Mar 1. Gina confirmed receipt Mar 2. |
| Reply to Lorie — monthly check-ins | RBCx | Lorie delegated to Gina ("@Gina, do you want to set up a recurring booking?"). Conversational closure — no action needed. |

### Critical ({count})

Items 7+ days without evidence of follow-through.

| Score | Task | Project | Signal | Days | Evidence Gap |
|-------|------|---------|--------|------|--------------|
| 25 | Reply to Robert — pipeline update | Sprint | Commitment breach | 12d | Wrote "I'll send the pipeline by Friday" on Feb 23. No sent email with "pipeline" to Robert since. |
| 20 | Send contract to Alex | Scale AI | Commitment breach | 8d | Meeting action item from Feb 27. No sent email to alex@scale.ai since. |

### At Risk ({count})

Items 6-7 days without activity.

| Score | Task | Project | Signal | Days | Evidence Gap |

### Watch ({count})

Items 4-5 days — emerging gaps.

| Score | Task | Project | Signal | Days |

### Clear ({count})

{count} tasks across {project_count} projects have recent activity. No action needed.

### Priority Escalated ({count})

Tasks whose Todoist priority was automatically raised.

| Task | Project | Previous | New | Reason |
|------|---------|----------|-----|--------|
| Reply to Robert — pipeline update | Sprint | P3 | P1 | Critical: 12d commitment breach |
| Follow up with Colin | AICON | P3 | P2 | At Risk: 7d unanswered inbound |

### Cross-Project Patterns

- {any systemic patterns detected}

---
Auto-closed: {count} tasks.
Pushover notification sent: {count} items alerted.
Priority escalated: {count} tasks.
```

---

## Phase 5: Update State

```sql
INSERT INTO skill_state (user_id, skill_name, state_key, state_value)
VALUES (auth.uid(), 'risk', 'last_run', '{
  "last_run": "{ISO-8601 timestamp}",
  "projects_scanned": N,
  "tasks_assessed": N,
  "critical_count": N,
  "at_risk_count": N,
  "watch_count": N,
  "clear_count": N,
  "priorities_escalated": N,
  "auto_closed": N,
  "notification_sent": true/false
}')
ON CONFLICT (user_id, skill_name, state_key)
DO UPDATE SET state_value = EXCLUDED.state_value, updated_at = now();
```

---

## Edge Cases

- **No context map found for a project**: Skip project, note in output. Suggest running `/context-map`.
- **No open tasks across any project**: Report "No open tasks found" and exit. No notification.
- **Todoist token expired (401/403)**: Stop and tell user to update via `$OUTWORKOS_ROOT/scripts/set-secret.sh todoist_api_token <new_token>`
- **Gmail OAuth expired**: Direct user to re-auth via `$OUTWORKOS_ROOT/scripts/google-auth.sh`
- **Pushover credentials missing**: Skip notification, note in output. Suggest setting up via Vault.
- **Worker timeout**: Record error, continue with other workers. Include note in output.
- **Tasks in Waiting section**: Only flag if NO outbound email was sent handing off. If a handoff email exists, task is legitimately waiting — skip it.
- **All items Clear**: No notification, brief "All clear" output.

---

## Compatibility

- **Shared Todoist cache** with `/scan` and `/whats-next` at `/tmp/todoist-sync-cache.json` (5-min TTL)
- **Priority escalation** — escalates priorities for Critical (→P1) and At Risk (→P2) items. Never downgrades.
- **`risk` label** — ephemeral, reset each run. Applied to all Critical and At Risk tasks. Filter `@risk` in Todoist = "what's at risk right now." Does not touch `scan` or `gap` labels.
- **No task creation** — run `/whats-next` or `/scan` to create tasks from gaps.
- **Log entries** — reads `log_entries` table but does not write to it. Use `/log` to record sessions.

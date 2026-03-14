# Risk — Per-Project Worker Prompt

Template for the per-project risk assessment workers spawned in Phase 1.

---

## Worker Spawn Settings

```
Agent tool:
  subagent_type: "general-purpose"
  name: "risk-worker-{project_slug}"
```

## Prompt Template

Fill in `{PLACEHOLDERS}` before spawning:

---

You are a risk assessment worker for **{PROJECT_NAME}**. Your job is to evaluate every open Todoist task for this project and determine whether the user has actually followed through on each one. You do this by cross-referencing against sent email, project logs, and calendar.

**CRITICAL — Resolved Task Detection:** Before scoring risk, check if the task's action has ALREADY been completed. If sent mail, calendar, or thread evidence shows the action was taken (reply sent, meeting held, document signed, RSVP'd, etc.), mark the task as `"resolved"` with `"auto_close": true`. This prevents zombie tasks from being re-flagged daily when the work is done but the Todoist checkbox wasn't ticked.

**Task ownership filter:** Only assess tasks where the user is the responsible actor. Skip tasks that are:
- Sourced from **impactOS engagement data** (milestones, target dates, engagement status) — impactOS is a record system, not the user's task list. These tasks should not exist and should be flagged for cleanup.
- Phrased as someone else's action (e.g., "Reply to {user}: ..." means the OTHER person needs to reply, not vice versa)
- Delegation tracking items where the user is monitoring someone else's deliverable, not executing themselves

If you encounter such tasks, include them in the output as tier `"skip"` with a note explaining why (e.g., `"skip_reason": "impactOS engagement milestone — not user's task"`).

**Why this matters:** A missed follow-up that goes undetected for a week can damage a client relationship. Your assessment is the early warning system. Be thorough — a false "Clear" means the risk keeps growing silently.

## Project Context

**Project:** {PROJECT_NAME}
**Slug:** {PROJECT_SLUG}
**Todoist Project ID:** {TODOIST_PROJECT_ID}
**Project DB ID:** {PROJECT_DB_ID}
**Primary Stakeholder:** {STAKEHOLDER_NAME} ({STAKEHOLDER_EMAIL})
**Today:** {TODAY_DATE}

**Person-to-Email Mapping** (from context map):
```
{PERSON_EMAIL_MAPPING}
```

**Risk Cadence Override:** {CADENCE_OVERRIDE or "default (3/5/7 days)"}

## Open Tasks (non-deferred)

```json
{TASKS_JSON}
```

## Sections

```json
{SECTIONS_JSON}
```

## Instructions

### 1. Search Sent Mail (One Query Per Person)

For each person in the person-to-email mapping, search the user's sent mail. Use Google Workspace MCP tools (discover via ToolSearch: "+google gmail").

For each person with emails [email1, email2, ...], use the user's email (provided as `{USER_EMAIL}` from user_profiles lookup):
```
search_gmail_messages(query: "from:{USER_EMAIL} (to:{email1} OR to:{email2}) newer_than:30d", max_results: 20)
```

Fetch **full content** for each returned email. Build an evidence pool: a list of sent emails with subject, recipient, date, and body summary.

### 2. Query Project Logs

Use Supabase MCP tools (discover via ToolSearch: "+supabase"). Query the `log_entries` table:

```sql
SELECT logged_at, summary, details FROM log_entries
WHERE project_id = '{PROJECT_DB_ID}'
  AND logged_at > now() - interval '30 days'
ORDER BY logged_at DESC LIMIT 20;
```

Build a log evidence pool: entries with date and summary.

### 3. Check Calendar

Use Google Workspace MCP tools (discover via ToolSearch: "+google calendar"):

**Past meetings** (last 14 days):
```
get_events(calendar_id: "primary", time_min: "{14_days_ago_iso}", time_max: "{today_iso}")
```

**Upcoming meetings** (next 7 days):
```
get_events(calendar_id: "primary", time_min: "{today_iso}", time_max: "{7_days_from_now_iso}")
```

Filter to events where the stakeholder email appears in attendees or stakeholder name appears in the event title.

### 4. Assess Each Task

**Step 1 — Check for resolution FIRST.** Before scoring risk signals, determine if the task's action has already been completed. A task is resolved if ANY of the following are true:

1. **Reply sent** — The user sent an email that directly addresses the task's action (e.g., task says "Reply to X about Y" and a sent email to X about Y exists)
2. **Agreement/document completed** — Task is about reviewing/signing something and evidence shows it was done (e.g., "Just signed the agreement" in sent mail, or counterparty confirmed receipt)
3. **Meeting held** — Task is about scheduling/attending a meeting and a matching calendar event exists in the PAST (already happened)
4. **Conversational closure on the task itself** — The task was created from an inbound email, and that thread now shows conversational closure (delegation, confirmation, no action needed from user)
5. **Explicit completion evidence** — Log entries or emails that confirm the deliverable was sent/completed

If resolved: set `tier: "resolved"`, `auto_close: true`, and include `resolution_evidence` explaining what evidence confirms completion. `auto_close` may ONLY be `true` when `tier` is `"resolved"` — never set it on any other tier. Do NOT score risk signals for resolved tasks.

**Step 2 — Score unresolved tasks.** For EVERY open task that is NOT resolved, evaluate against the five risk signals. For each signal, determine if it applies and compute the days since last relevant activity.

#### Risk Signals

| Signal | How to Detect | Base Weight |
|---|---|---|
| **Commitment breach** | Task description or related sent email contains promise language ("I'll send", "will follow up", "by end of week") AND no subsequent sent email delivering on that promise | 5 |
| **Unanswered inbound** | Stakeholder sent an email related to this task's topic AND no reply from user exists in the sent mail pool AND the email is not conversational closure (see below) | 4 |
| **Meeting without follow-through** | Calendar shows a meeting with stakeholder in the past 14 days AND no sent email or log entry after that meeting references the task topic | 3 |
| **Communication decay** | No sent email to stakeholder in X days while this task remains open | 2 |
| **Stale engagement** | No activity across ANY source (sent mail, logs, calendar, task modification) for this task's topic | 1 |

#### Conversational Closure (Unanswered Inbound Filter)

A stakeholder reply does NOT constitute an unanswered inbound if any of these apply:

1. **Confirmation/acknowledgment** — The reply affirms or accepts something the user proposed ("that works", "sounds good", "thanks for this", "perfect", "agreed"). No question or request directed at the user.
2. **Delegation to a third party** — The reply passes the action to someone else ("@Gina, can you set up...", "I'll have my EA book it", "Looping in X to handle"). The ball is not in the user's court.
3. **Informational with no call to action** — The reply shares information but asks nothing of the user (FYI forwards, status updates, CC additions).

When any of these apply, the stakeholder's reply is conversational closure — mark the related task as **Clear** (not unanswered inbound). If the reply contains BOTH a closure element AND a new question/request, assess only the new question/request.

#### Calendar Resolution for Scheduling Tasks

If a task is about **scheduling or confirming a meeting** (contains language like "schedule", "set up meeting", "book time", "March 11 meeting", or references a specific date) AND a matching calendar event exists within the next 7 days with the same stakeholder in the attendees or title, treat the task as **Clear** — the meeting is confirmed regardless of email thread state.

#### Determining `days_since_last_activity`

For each task, find the **most recent** evidence of activity across all sources:
- Most recent sent email to the relevant person about this topic
- Most recent log entry mentioning this topic
- Most recent calendar meeting with the stakeholder
- Task's own `date_added` or last modified date (from Todoist)

`days_since_last_activity` = today - most_recent_evidence_date

#### Temporal Scoring

Apply thresholds (use cadence override if provided, otherwise defaults):

| Tier | Label | Days (Default) | Time Multiplier |
|---|---|---|---|
| 0 | Clear | 0-3 | 1.0 |
| 1 | Watch | 4-5 | 1.5 |
| 2 | At Risk | 6-7 | 3.0 |
| 3 | Critical | 7+ | 5.0 |

```
risk_score = base_weight x time_multiplier
```

Use the HIGHEST applicable signal's base weight (not cumulative). If multiple signals apply, report all of them but score using the highest.

#### Evidence Requirements

For each flagged task (Watch or above), you MUST provide:
- **Signal type**: Which of the 5 signals triggered
- **Days**: Exact count since last activity
- **Evidence gap**: Specific description of what's missing. Examples:
  - "Wrote 'I'll send the updated pipeline by Friday' on Feb 23. No sent email with 'pipeline' to robert@ai-first.ca since."
  - "Robert sent 'Following up on the contract' on Mar 1. No reply found."
  - "Meeting 'Sprint Sync' on Feb 28 with Robert. No sent email or log entry after that date references pipeline tasks."
- **Last activity**: What the most recent evidence IS (date + description)

#### Special Rules for Waiting Section

Tasks in the **Waiting** section get special treatment:
1. Search sent mail for a "handoff" email — evidence that the user sent something and is waiting for a reply
2. If handoff evidence exists AND the handoff was recent (within threshold), mark as **Clear** — the ball is legitimately in their court
3. If handoff evidence exists BUT it's old (past threshold), mark as **Communication decay** — may need a follow-up nudge
4. If NO handoff evidence exists, the task shouldn't be in Waiting — flag as **Unanswered inbound** or **Commitment breach**

### 5. Return JSON

Return ONLY valid JSON (no markdown, no explanation outside the JSON):

```json
{
  "project": "{PROJECT_SLUG}",
  "project_name": "{PROJECT_NAME}",
  "todoist_project_id": "{TODOIST_PROJECT_ID}",
  "total_tasks_assessed": 8,
  "sent_emails_checked": 12,
  "log_entries_checked": 5,
  "meetings_checked": 3,
  "summary": {
    "resolved": 1,
    "critical": 1,
    "at_risk": 2,
    "watch": 1,
    "clear": 3
  },
  "risks": [
    {
      "task_id": "task_id_123",
      "task_content": "Reply to Robert — pipeline update",
      "section": "Do",
      "priority": 3,
      "due": "2026-02-28",
      "tier": "critical",
      "risk_score": 25,
      "days_since_last_activity": 12,
      "signals": [
        {
          "type": "commitment_breach",
          "base_weight": 5,
          "evidence_gap": "Wrote 'I'll send the updated pipeline by Friday' to robert@ai-first.ca on Feb 23. No sent email containing 'pipeline' to Robert since.",
          "last_activity": "Feb 23 — sent email: 'Re: Sprint sync — I'll send the updated pipeline by Friday'"
        },
        {
          "type": "communication_decay",
          "base_weight": 2,
          "evidence_gap": "No outbound email to robert@ai-first.ca since Feb 23 (12 days).",
          "last_activity": "Feb 23 — last sent email to Robert"
        }
      ]
    },
    {
      "task_id": "task_id_456",
      "task_content": "Review contract terms",
      "section": "Do",
      "priority": 2,
      "due": null,
      "tier": "resolved",
      "auto_close": true,
      "resolution_evidence": "Sent email Mar 1: 'Just signed the 2026 partnership agreement'. Counterparty confirmed receipt Mar 2.",
      "risk_score": 0,
      "days_since_last_activity": 0,
      "signals": [],
      "last_activity": "Mar 1 — sent email: 'Re: Contract — Just signed the 2026 partnership agreement'"
    },
    {
      "task_id": "task_id_789",
      "task_content": "Follow up with Alex on proposal",
      "section": "Do",
      "priority": 2,
      "due": null,
      "tier": "clear",
      "risk_score": 2,
      "days_since_last_activity": 2,
      "signals": [],
      "last_activity": "Mar 5 — sent email: 'Re: Proposal — looks good, minor edits attached'"
    }
  ],
  "stakeholder_last_outbound": {
    "date": "2026-02-23",
    "subject": "Re: Sprint sync",
    "recipient": "robert@ai-first.ca"
  },
  "upcoming_meetings": [
    {"title": "Sprint Sync", "date": "2026-03-10", "htmlLink": "..."}
  ]
}
```

---

## Parallel Spawning Pattern

Spawn ALL workers in a single message (no waiting between spawns):

```
Agent(name: "risk-worker-sprint", subagent_type: "general-purpose", prompt: "...")
Agent(name: "risk-worker-scale-ai", subagent_type: "general-purpose", prompt: "...")
Agent(name: "risk-worker-aicon", subagent_type: "general-purpose", prompt: "...")
```

Collect results as they return. If a worker times out (>90s), record `{"project": "NAME", "error": "timeout"}` and proceed.

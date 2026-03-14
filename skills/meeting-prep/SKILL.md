---
name: meeting-prep
description: "Produces a meeting prep briefing for upcoming calendar meetings by researching attendees, email history, past meetings, and company backgrounds. Use when the user asks to prepare for meetings, prep for tomorrow, review upcoming meetings, get ready for a meeting day, or asks 'what meetings do I have'. Also use when the user asks to research a specific meeting or contact before a call."
argument-hint: ["(default: tomorrow)" | "today" | "2026-03-15" | "monday"]
context: fork
---

# Meeting Prep

## Runtime Context

Before executing, resolve the following dynamic values:

1. **User email**: Query `SELECT email FROM user_profiles WHERE id = auth.uid()` via Supabase MCP `execute_sql`. Use this wherever the user's email is needed.
2. **User domain**: Query `SELECT domain FROM user_profiles WHERE id = auth.uid()`. Use this to distinguish internal vs. external attendees.
3. **User timezone**: Query `SELECT timezone FROM user_profiles WHERE id = auth.uid()`. Use this for all time-related parameters (calendar queries, display formatting).
4. **Vault secrets**: Construct Vault key names dynamically as `'user_' || auth.uid() || '_{label}'` (e.g., `'user_' || auth.uid() || '_resend_api_key'`).
5. **Supabase project ID**: Use the `SUPABASE_PROJECT_ID` environment variable or read from the SessionStart manifest. Never hardcode.
6. **OutworkOS root**: Use `$OUTWORKOS_ROOT` environment variable (fallback: discover from SessionStart context).
7. **MCP tools**: Use `ToolSearch` to discover all MCP tool names at runtime. Never hardcode tool names like `mcp__google-workspace__*` or `mcp__fireflies__*`.

Cache these values at the start of execution and reuse throughout.

## What This Does

Fetches calendar events for a target date, identifies meetings with external attendees, determines how well you know each contact, and then researches each meeting at the appropriate depth. First meetings get the full treatment (bio, company overview, web research). Established contacts just get a "what's new" summary. After research, enriched contact data is written back to Google Contacts so future lookups are faster.

## Data Sources (ranked by proven value)

| Source | Score | What It Provides | Notes |
|--------|-------|-------------------|-------|
| Gmail | 5.0/5 | Relationship timeline, attendee details from sigs, meeting context, action items | Always the richest source |
| Fireflies | 4.2/5 | Past meeting summaries, action items, longitudinal project arcs | Empty for brand-new contacts |
| Perplexity | 4.0/5 | Company profiles, person bios, org context | Best-effort; no structured API |
| Google Contacts | 1.3/5 | Name, title, phone (when stored) | Improves over time via write-back |

## Familiarity Tiers

Before researching anyone, check how many past Fireflies transcripts exist with that person. This determines how deep to go:

| Past Meetings | Tier | Research Depth | Output Style |
|---------------|------|----------------|--------------|
| 0 | First meeting | **Full**: All 4 sources including web search + full bio | Full briefing with company overview, attendee bios, relationship history |
| 1-2 | Early relationship | **Medium**: Gmail recent threads + Fireflies last summary. Skip web search. | Briefing with attendee one-liner, relationship history, recent context |
| 3+ | Established | **Light**: Latest Gmail thread + latest Fireflies summary only | Just "what's changed" — recent context and any open action items |

The goal: you don't need to be told who Steve Lane is for the 11th time. You need to know what happened since you last spoke.

## Arguments

The argument sets the target date. If omitted, defaults to **tomorrow**.

| Argument | Target Date |
|----------|-------------|
| *(default)* | Tomorrow |
| `today` | Today |
| `YYYY-MM-DD` | Specific date |
| `monday`, `tuesday`, etc. | Next occurrence of that weekday |

## Execution

### Step 1: Parse Date and Fetch Calendar

Resolve the target date from the argument. Use ToolSearch to discover the Google Calendar MCP tool for listing events, then fetch all events for the target date:

- `condenseEventDetails: false` (need full attendee lists)
- `timeZone`: use the user's timezone from Runtime Context
- Time range: midnight to 23:59:59 on the target date

### Step 2: Filter to Qualifying Meetings

From the event list, categorize each event:

**Include in briefing** (external meetings):
- Has at least one attendee with an email domain that does NOT match the user's domain (from Runtime Context)
- This includes `@gmail.com`, `@outlook.com`, etc. — personal email addresses often belong to important first-time contacts booked via Cal.com or Calendly

**List but don't research** (internal meetings):
- All attendees share the user's email domain
- Still show these in the summary table for schedule awareness

**Skip entirely:**
- Events with zero attendees (holds, focus blocks, personal reminders)
- Events where the user is the only attendee
- Cancelled events (`status: "cancelled"`)

For each qualifying meeting, extract:
- Title, start/end times, location/video link
- External attendee emails and display names
- Internal attendee emails
- Event description (may contain agenda, Cal.com booking details, or video links)

### Step 3: Determine Familiarity per Attendee

Before spawning research agents, do a quick familiarity check for each unique external attendee across all qualifying meetings. Use ToolSearch to find the Fireflies search tool, then search for each attendee's name or email. Count the number of past transcripts.

Also check the Supabase `contacts` table for existing enriched data:

```sql
SELECT display_name, email, organization, title, phone, notes, last_interaction_at
FROM contacts
WHERE email = '{attendee_email}';
```

Combine these signals to assign a tier:
- **0 Fireflies transcripts + no contact record** → First meeting (full research)
- **0 Fireflies transcripts + has contact with notes** → Early relationship (medium — contact data exists from a prior enrichment, so skip web search)
- **1-2 Fireflies transcripts** → Early relationship (medium research)
- **3+ Fireflies transcripts** → Established (light research)

Pass the tier to each research agent so it knows what depth to operate at.

### Step 4: Research Each Meeting (Parallel Sub-Agents)

Spawn one sub-agent per qualifying external meeting. All agents run in parallel. Each agent receives the meeting details, attendee familiarity tiers, and follows the research protocol in `references/research-agent-prompt.md`.

The agent prompt template needs these variables filled in:
- `{meeting_title}` — event summary
- `{meeting_time}` — formatted start-end time
- `{meeting_location}` — location or video link
- `{external_attendees}` — comma-separated list of `Name <email> [TIER: first/early/established]` for external attendees
- `{internal_attendees}` — comma-separated list for internal attendees
- `{event_description}` — the calendar event description, if any
- `{target_date}` — the date being researched
- `{existing_contact_data}` — any data already in Supabase contacts (org, title, phone, notes) to avoid redundant lookups

Read `references/research-agent-prompt.md` and fill in these variables before passing to each agent.

### Step 5: Compile the Briefing

Once all agents return, assemble the final output as a **narrative morning brief** — written in flowing prose that could be read aloud or listened to. No bullet points, no tables, no structured headers per meeting. Think chief-of-staff verbal briefing.

**Opening paragraph:** One sentence summarizing the day — how many external meetings, any internal blocks worth noting, the overall shape of the day.

**Per-meeting sections** (external meetings only, chronological, separated by `---`):

Each meeting gets an `## {Meeting Title} — {Time}` heading, then narrative paragraphs. The depth and content vary by tier, but the style is always conversational prose.

**First meeting — full narrative:**
Write 3-4 paragraphs covering:
1. Who this person is, what their organization does, and why this meeting is happening — woven together naturally, not as separate sections. Include company scale, location, and industry as part of the story, not as a data card.
2. How you're connected — who introduced you, what correspondence led to this meeting, what the trajectory of the relationship looks like so far. Weave in the timeline naturally ("she reached out last week," "the introduction came through Jessi at ACOA in mid-February") rather than listing dated bullet points.
3. What to expect — the likely agenda based on email context, what they're looking for, what stage the conversation is at (exploring, evaluating, ready to move). End with the key thing to know going in.

**Early relationship — medium narrative:**
Write 2-3 paragraphs. Skip the bio and company overview since you've met before. Focus on the relationship arc and what's happened since you last connected. What are you working on together? What's the current status? What's likely on the agenda today?

**Established — short narrative:**
Write 1-2 paragraphs. Open with a one-line reminder of who this person is and how many times you've met. Then focus entirely on what's changed since the last meeting — latest email exchange, outstanding action items, decisions pending. This is a "here's what's new" update, not a briefing.

**Writing style rules:**
- Conversational, warm, professional — like a colleague catching you up over coffee
- Write in second person ("you," "your") addressing the reader directly
- No bullet points or numbered lists — everything in flowing paragraphs
- No tables or structured data cards
- Weave dates into sentences naturally ("she emailed yesterday," "you signed the agreement on March 1st") rather than listing them
- No markdown formatting beyond the `##` heading per meeting and `---` separators
- Don't invent or speculate about what to say or strategy — stick to facts from the sources
- Keep company descriptions factual and woven into the narrative, not called out separately
- If a meeting has multiple attendees, introduce each person in context within the narrative rather than listing them

### Step 6: Enrich Contacts (Write-Back)

After presenting the briefing, write enriched data back to Google Contacts and Supabase. This step runs silently — don't wait for user confirmation.

**For each external attendee where new data was discovered:**

1. **Google Contacts** — Use ToolSearch to find the Google Workspace `manage_contact` tool.
   - If contact doesn't exist: create with name, email, title, org, phone
   - If contact exists but is missing title/org/phone: update with discovered data
   - Write a brief summary to the `notes` field: company overview + how you're connected (e.g., "Senior Director, Innovation at Clearwater Seafoods. Connected via Paul Owens (ACOA) for AI adoption discussion, March 2026.")
   - Don't overwrite existing notes — append new info with a date stamp

2. **Supabase contacts table** — If the contact exists in the DB, update title/org/phone/notes. If not, the next Google Contacts sync will pick it up.

3. **Supabase interactions table** — Log a `meeting_prep` interaction for each attendee:
   ```sql
   INSERT INTO interactions (contact_id, interaction_type, source_type, source_id, summary, occurred_at)
   SELECT c.id, 'meeting_prep', 'calendar', '{event_id}', '{meeting_title}', '{target_date}'
   FROM contacts c WHERE c.email = '{attendee_email}';
   ```
   Only log if the contact exists in the DB. Don't create contacts in Supabase directly — let the Google Contacts sync handle that.

### Step 7: Present to User

Display the complete briefing in the conversation. No need to save to a file unless the user asks.

If any first-meeting contacts had particularly thin research results (no email history, no web presence), flag them at the end: "Heads up — limited context found for {meeting}. You may want to ask {attendee} for background before the call."

Briefly note how many contacts were enriched: "Updated {N} Google Contacts with new profile data."

## Edge Cases

- **Recurring internal + external meetings** (like a weekly check-in with a client): These will naturally be "established" tier after a few weeks. The light briefing format is ideal — just show what's new.
- **Meetings with many attendees** (5+): Only do full research on first-meeting attendees. Established contacts just get listed by name.
- **Same-day meetings with the same person**: Consolidate research — one agent can cover both meetings with a single research pass. Show the briefing under the first meeting and reference it from the second.
- **No qualifying meetings found**: Report "No external meetings found for {date}. You have {N} internal meetings." and list them.
- **Mixed-tier meetings** (one first-meeting attendee + one established): The agent runs at the depth of the least-familiar attendee, but only applies full sections to the unfamiliar person. The established person just gets a one-liner.

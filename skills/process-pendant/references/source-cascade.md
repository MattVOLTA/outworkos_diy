# Source Selection Cascade

## Priority Order

When multiple sources cover the same time window, select the best one:

```
1. FIREFLIES  →  Has transcript with speaker IDs, summaries, action items
2. LIMITLESS   →  Has ambient audio transcript (no speaker IDs)
3. CALENDAR    →  Has metadata only (attendees, description, location)
```

## Decision Matrix

| Calendar Event? | Fireflies Transcript? | Limitless Lifelog? | Best Source | Label |
|-----------------|----------------------|-------------------|-------------|-------|
| Yes | Yes | Yes | Fireflies | `meeting_fireflies` |
| Yes | Yes | No | Fireflies | `meeting_fireflies` |
| Yes | No | Yes | Limitless | `meeting_limitless` |
| Yes | No | No | Calendar | `meeting_calendar_only` |
| No | Yes | Yes | Fireflies | `team_fireflies` |
| No | Yes | No | Fireflies | `team_fireflies` |
| No | No | Yes | Limitless | `ambient_limitless` |

## Time Matching Rules

- Use a **5-minute tolerance** when matching across sources
- Calendar event: 09:00-09:45
- Fireflies transcript starting at 09:02 → MATCH
- Limitless lifelog starting at 09:01 → MATCH
- Fireflies timestamps are **UTC** — convert using the user's timezone (from `user_profiles.timezone`)
- Limitless timestamps are in the user's timezone when `timezone={user_timezone}` is passed
- Calendar timestamps are in the user's timezone when `timeZone={user_timezone}` is passed

## What Each Source Provides

### Fireflies (Best for scheduled meetings)
- Speaker-identified transcript
- Pre-generated summary (short_summary)
- Pre-extracted action items with assignees
- Pre-extracted keywords
- Attendee emails (for contact matching)
- Duration in minutes
- Meeting link

### Limitless (Best for gaps)
- Raw transcript (all speakers as "Unknown")
- AI-generated title and headings
- Markdown-formatted content
- Start/end timestamps
- Content nodes with time offsets

### Calendar (Best for metadata)
- Event title and description
- Attendee names and emails
- Location (in-person vs video link)
- Organizer
- Meeting notes/agenda from description field

## High-Value Pendant Captures

These scenarios make the pendant uniquely valuable:

1. **In-person meetings** — Fireflies can't join face-to-face meetings
2. **Missed recordings** — Fireflies bot sometimes fails to join
3. **Hallway conversations** — No calendar event, no video call
4. **Podcast/content consumption** — Morning learning capture
5. **Evening work sessions** — Voice-to-self while coding
6. **Walking meetings** — No screen, no Fireflies
7. **Phone calls on personal phone** — Not on Google Meet

Always highlight pendant-only captures in the summary — this data would be completely lost without the device.

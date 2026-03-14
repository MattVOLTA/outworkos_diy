---
name: log
description: "Records project events and working sessions to log.md. Default mode captures end-of-session accomplishments. 'refresh' mode queries data sources for external events. Use at end of session, when user says 'log this', or to pull in external timeline events."
argument-hint: ["(default)" | "refresh"]
---

# Log Writer

## Runtime Context
All database operations use `auth.uid()` for user scoping. Never hardcode user IDs in queries.

## Data Storage Rules

- **DB is source of truth** via Supabase MCP `execute_sql`. Discover MCP tools via `ToolSearch` at runtime — never hardcode tool names.
- **Use the Supabase MCP tools** to execute SQL against the connected project. The MCP connection already knows which Supabase project to target — do not hardcode a project ID.
- **Project DB IDs** come from the SessionStart manifest (injected into context). Each project entry includes `DB ID`, `Slug`, and `Todoist ID`.
- **If no manifest is present:** Query `SELECT id, slug FROM projects WHERE slug = '{derived-slug}'` via Supabase MCP to look up the project DB ID. Derive the slug from the project name (e.g., "Good Robot" → "good-robot"). Never silently skip the DB write.
- **Dual-write:** Write to both DB (`log_entries` table) and local `log.md`. DB writes use `execute_sql`; local file writes use the existing format.
- **User ID for all DB writes:** Use `auth.uid()` — never hardcode a user ID.
- **Graceful fallback:** If the Supabase MCP tool is completely unavailable (tool not found, auth failure), fall back to file-only I/O and warn the user. Never silently fall back — always report if DB write was skipped.

## Purpose

Maintain a single chronological record (`log.md`) of project events and working sessions. Replaces the former `update-log.md` and `timeline.md` as a unified project log. Newest entries first.

## Modes

| Mode | Trigger | Entry type |
|------|---------|------------|
| `/log` (default) | End of session, "log this" | `session` |
| `/log refresh` | "refresh the log", "pull in events" | `external` |

---

## Entry Format

All entries follow this structure:

```markdown
## YYYY-MM-DD — [Title]

> [1-2 sentence summary]

- **Type**: session | external
- **[Section]**: [content]
- **Sources**: [links to artifacts, tools, messages]
- **Next**: [follow-up if applicable]
```

**Rules:**
- Date format: `YYYY-MM-DD`
- Session entries: prefix title with "Session: " (e.g., `## 2026-02-21 — Session: Labor reports sent`)
- External entries: plain title (e.g., `## 2026-02-20 — ACOA webinar featuring Good Robot`)
- `Type: session | external` discriminator on every entry
- Sections are optional. Omit what doesn't apply.
- `---` separator between entries
- Newest first (prepend after header)

---

## Project Targeting (CRITICAL)

**Always log to the project the work was done for, NOT the project you're running from.**

When invoked from OutworkOS (the cross-project hub), determine the target project from:
1. **Explicit argument**: `/log Sprint: did X` → log to Sprint
2. **Session context**: If the session involved work on a specific project (emails to project contacts, closing project Todoist tasks), log to that project
3. **Multiple projects in one session**: Create separate log entries for each project, using each project's DB ID and local `log.md`

Use the SessionStart manifest to look up each project's DB ID, slug, and path. Write DB entries with the correct `project_id` and local entries to `$OUTWORKOS_PARENT/{ProjectName}/log.md`.

**Never default to the OutworkOS project** unless the work was genuinely about OutworkOS itself (skill development, infrastructure, hooks, etc.).

---

## Default Mode: Session Log (`/log`)

Captures what was accomplished in the current session as a permanent record.

### Step 1: Gather Context

1. **DB-first:** Query `SELECT context_map_md FROM projects WHERE slug = '{project_slug}'` via Supabase MCP to get the project's context map. **Fallback:** Read `context-map.md` in the project root.
2. **DB-first:** Query `SELECT entry_date, session_title, content FROM log_entries WHERE project_id = '{project_db_id}' ORDER BY entry_date DESC LIMIT 5` for recent entries. **Fallback:** Read the existing `log.md` if it exists. Note the last entry date and format for consistency.
3. Review the current session: what files were created, modified, or read; what tools were called; what decisions were made; what the user asked for and what was delivered

### Step 2: Identify Accomplishments

Scan the session for meaningful work products. Categorize each as one of:

| Category | Examples |
|----------|---------|
| **Created** | New files, database records, Todoist tasks, calendar events |
| **Modified** | Edited files, updated records, patched documents |
| **Discovered** | New information from exploration, research findings, data patterns |
| **Decided** | Architectural choices, workflow decisions, scope changes |
| **Resolved** | Bugs fixed, blockers removed, questions answered |

Skip trivial actions (reading files for orientation, failed attempts that led nowhere). Focus on outcomes, not process.

### Step 3: Collect Artifact Links

For every accomplishment, find the most specific reference possible:

| Artifact Type | Link Format |
|---------------|-------------|
| Local file created/modified | `[filename](relative/path/to/file)` |
| Git commit | `[short message](commit-hash)` |
| GitHub PR/issue | `[#number](url)` |
| Database record | `[table.field](record-id)` |
| Supabase record | `[table: description](project-id/table/record-id)` |
| Email/thread | `[subject](message-id or search query)` |
| Calendar event | `[event title](event-id or date)` |
| Todoist task | `[task title](task-id)` |
| External URL | `[page title](url)` |
| Fireflies transcript | `[meeting title](transcript-id)` |
| Sanity document | `[doc title](document-id)` |

If an artifact lives in a system from the project's Data Source Registry (in context-map.md), use the access pattern documented there to construct the reference.

### Step 4: Draft the Entry

```markdown
## YYYY-MM-DD — Session: [Title]

> [1-2 sentence summary of what this session accomplished]

- **Type**: session
- **Created**: [description] → [artifact link]
- **Modified**: [description] → [artifact link]
- **Discovered**: [description]
- **Decided**: [decision and rationale]
- **Resolved**: [what was fixed]
- **Sources**: [source]: [what was pulled] → [link]
- **Next**: [actionable follow-up]
```

Only include categories that have content. Use `→` to visually separate description from artifact link.

### Step 5: Write the Entry (Dual-Write: DB + Local)

**1. Write to Supabase `log_entries` table** (primary):
```sql
INSERT INTO log_entries (user_id, project_id, entry_date, session_title, content, source, metadata)
VALUES (
  auth.uid(),
  '{project_db_id}',
  '{YYYY-MM-DD}',
  '{session title}',
  '{full markdown entry content}',
  '{session|external}',
  '{metadata JSON with artifact links, categories}'
);
```

**2. Write to local `log.md`** (dual-write fallback):
1. If `log.md` does not exist, check for migration (see Migration section below)
2. If creating fresh, write the header:
   ```markdown
   # [Project Name] — Log

   > Chronological record of project events and working sessions. Newest first.

   ---
   ```
3. **Prepend** the new entry after the header (newest first)

### Step 6: Confirm with User

Present the entry to the user before writing. Ask:
- "Does this capture the session accurately?"
- "Anything to add, remove, or rephrase?"

Write only after confirmation. If the user provides `$ARGUMENTS`, use that as a hint for the session title or focus area.

---

## Refresh Mode: External Events (`/log refresh`)

Queries data sources for events since the last log entry and prepends them as `Type: external` entries.

### Step 1: Read Timeline Playbook

Read `context-map.md` and find the **Timeline Playbook** section. This contains the SQL queries, API calls, and data sources to check for timeline events.

If no Timeline Playbook exists, tell the user: "This project's context-map doesn't have a Timeline Playbook section. Add one with `/context-map` to enable event refresh."

### Step 2: Determine Time Window

Read `log.md` and find the date of the most recent entry. Query data sources for events **after** that date.

If no `log.md` exists, check for migration (see Migration section). If no prior log at all, ask the user for a start date.

### Step 3: Query Data Sources

Execute each query/search from the Timeline Playbook. For each source:
- Run the query with the time window filter
- Collect results with dates, descriptions, and source identifiers

Use the project's MCP connections and access patterns from context-map.md. Discover tools via ToolSearch before calling them.

### Step 4: Draft External Entries

For each event discovered, create an entry:

```markdown
## YYYY-MM-DD — [Event Title]

- **Type**: external
- **Source**: [data source] ([record ID or reference])
- **Details**: [what happened, who was involved, key outcomes]
```

Group same-day events into a single entry if they're closely related. Otherwise, create separate entries per event.

### Step 5: Write Entries

Present all drafted entries to the user for review. After confirmation, prepend them to `log.md` (newest first), interleaved correctly with any existing entries by date.

---

## Migration (First Run)

On first invocation of `/log` in a project, if `log.md` does not exist:

1. Check for `timeline.md` and/or `update-log.md` in the project root
2. If found, ask the user: "I found [timeline.md / update-log.md / both]. Want me to merge them into the new log.md format?"
3. If yes:
   - Read all entries from both files
   - Convert each to the new format:
     - `update-log.md` entries → `Type: session`
     - `timeline.md` entries → `Type: external`
   - Interleave chronologically, newest first
   - Write as `log.md`
   - Suggest (but don't automatically delete) the old files
4. If no: create a fresh `log.md` with just the header

---

## Edge Cases

- **No meaningful work done**: If the session was purely exploratory with no tangible output, still log it under "Discovered". Orientation has value.
- **Multiple topics in one session**: Use a general session title and group items by topic.
- **Sensitive information**: Do not log credentials, tokens, or private keys. Reference them abstractly ("refreshed Google OAuth token").
- **First session after setup**: The first entry should reference the context-map creation itself as the primary accomplishment.
- **Multiple sessions same day**: Add a distinguishing detail to the title (e.g., "Session: Morning data pull" vs "Session: Report drafting").

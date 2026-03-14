# Context Map Section Templates

Use these templates as starting points. Adapt structure and content to the specific project.

## Quick Reference

```markdown
## Quick Reference

- **Project**: [Name]
- **Slug**: [lowercase-slug]
- **[Entity] ID**: `[uuid]`
- **[Person] ID**: `[uuid]`
- **[Person] Email**: `[email]`
- **Supabase Project**: `[project-id]`
- **GitHub Repo**: `[owner/repo]`
- **Todoist Project ID**: `[id]`
```

## Project Purpose

```markdown
## Project Purpose

> [1-3 sentences: what this project is, what we're trying to accomplish, and why it matters]
```

## People

Include for each person: their role, relationship to the project, and keys across every data source where they appear.

```markdown
## People

### [Person Name] ([Role])
- **Relationship**: [How they relate to this project]

#### Keys by Data Source

| Source | Key Field | Value |
|--------|-----------|-------|
| [DB] `[table]` | `[field]` | `[value]` |
| [Service] | `email` | `[email]` |

#### Contact Details
- **Email**: [email]
- **Phone**: [phone]
- **LinkedIn**: [url]
- **Cadence**: [meeting rhythm if applicable]
```

## Data Source Registry

The core of the map. For each source: what tool to use, what specific data is relevant, and validated query patterns.

```markdown
## Data Source Registry

### [Source Name] ([Type: Database / API / Files / etc.])
- **Access**: `[mcp tool name or method]` with `[required params]`
- **Project/Connection**: `[project ID, repo, or connection identifier]`

#### Relevant Tables/Resources

| Table/Resource | Purpose | Key Columns/Fields |
|----------------|---------|-------------------|
| `[table]` | [What this data represents] | [important columns] |

#### Validated Query Patterns

\```sql
-- [Description of what this retrieves]
SELECT ...
FROM ...
WHERE [filter using project-specific IDs]
ORDER BY ...;
\```

#### Non-SQL Access Patterns

\```
# [Description]
[mcp_tool_name](param: "value")
\```
```

## Rules & Constraints

Keep this short and specific. Only include rules that Claude would otherwise get wrong.

```markdown
## Rules & Constraints

- [Rule] - e.g., "Always use database X (`project-id`), NOT database Y"
- [Rule] - e.g., "Table name is singular: `interaction` not `interactions`"
- [Rule] - e.g., "Use `mcp__tool_a__*` tools, NOT `mcp__tool_b__*`"
- [Rule] - e.g., "Never modify production data without explicit confirmation"
```

## Timeline Playbook

Only include if the project has temporal data worth tracking across sources.

```markdown
## Timeline Playbook

To reconstruct the chronological history, query these sources and merge by date:

### SQL Queries

\```sql
-- [Source 1: description]
SELECT '[source_label]' as source, [date_field] as event_date,
  [key columns]
FROM [table]
WHERE [project filter]
ORDER BY [date_field];

-- [Source 2: description]
SELECT '[source_label]' as source, [date_field] as event_date,
  [key columns]
FROM [table]
WHERE [project filter]
ORDER BY [date_field];
\```

### Non-SQL Timeline Sources

\```
# [Source] - [what to search for]
[mcp_tool](params)
\```
```

## Refresh Checklist

Step-by-step routine for the start of every session.

```markdown
## Refresh Checklist

When starting a new session, run through this checklist:

1. **Verify Google OAuth** - `./scripts/google-auth.sh --check` (re-auth with `./scripts/google-auth.sh` if expired)
2. **Read this context map** - establishes project context
3. **Read log.md** - review recent activity and session history
4. **[Pull latest state]** - `[specific query or command]`
5. **[Check recent activity]** - `[last N items from key source]`
6. **[Search external source]** - `[specific search command]`
7. **[Check task status]** - `[Todoist query or task list check]`
```

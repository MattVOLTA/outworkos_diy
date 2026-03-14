# Project Scaffolding Templates

## CLAUDE.md Template

The lightweight pointer file. Keep under 60 lines. Reference context-map.md for depth.

```markdown
# [Project Name] - [Short Description]

## Quick Start
Read `context-map.md` at the start of every session. It contains all data source locations, query patterns, and keys needed to pull context.

## Project Purpose
[One-liner description of what this project is and what we're accomplishing]

## Primary Data Sources

| Source | Access Method | Search Key |
|--------|--------------|------------|
| **[Source 1]** | `[mcp_tool]` with `[params]` | [key]: `[value]` |
| **[Source 2]** | `[mcp_tool]` | `[search key]` |

## Key IDs (Copy-Paste Ready)
- **[Entity] ID**: `[uuid]`
- **[Person] ID**: `[uuid]`
- **[Person] Email**: `[email]`
- **[DB Project]**: `[project-id]`

## Rules
- [Critical rule 1]
- [Critical rule 2]

## Google Workspace Tool Tips

### Gmail Attachments
- `get_gmail_messages_content_batch` does **not** return attachment details — only subject, sender, date, body
- `get_gmail_message_content` (single message) returns full attachment metadata: filename, MIME type, size, attachment ID
- `get_gmail_attachment_content` downloads an actual file to disk (requires message_id + attachment_id)

**Attachment workflow:** `search_gmail_messages` → `get_gmail_message_content` (one at a time) → `get_gmail_attachment_content` if needed
```

## .claude/settings.json Template

Adapt model selection based on Phase 1 research findings. Always verify model aliases are current.

```json
{
  "model": "[model-alias]",
  "effortLevel": "high",
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [],
    "deny": [],
    "defaultMode": "default"
  },
  "enableAllProjectMcpServers": true
}
```

### Model Selection Guidance

Choose based on project characteristics. ALWAYS verify current model aliases during Phase 1.

| Project Type | Suggested Starting Point | Rationale |
|-------------|-------------------------|-----------|
| Complex advisory/research | Most capable model | Maximum reasoning for synthesis |
| Mixed planning + implementation | Plan-mode hybrid if available | Strong reasoning for planning, fast for execution |
| Implementation-heavy | Mid-tier model | Fast, capable, cost-effective |
| Simple/lightweight projects | Fastest model | Minimal overhead |

**Important**: Model aliases and capabilities change. Phase 1 research determines actual values.

## Custom Subagent Templates

Place in `.claude/agents/[name].md`. Only create subagents the project actually needs.

### Researcher Agent

For projects needing deep investigation across data sources:

```markdown
---
name: researcher
description: Deep-dive research agent for investigating topics, scanning data sources, and synthesizing findings. Use proactively when exploring unfamiliar data or answering complex questions.
tools: Read, Grep, Glob, Bash, WebSearch, WebFetch
model: [set based on Phase 1 research]
memory: project
---

You are a research specialist for [project name]. Thoroughly investigate topics using all available data sources defined in the project's context-map.md. Return concise, structured summaries with key findings and source references. Update your project memory with patterns discovered across sessions.
```

### Reviewer Agent

For projects where quality review of outputs matters:

```markdown
---
name: reviewer
description: Reviews outputs for accuracy, completeness, and consistency against project context. Use after generating deliverables or before sharing outputs externally.
tools: Read, Grep, Glob
model: [set based on Phase 1 research]
memory: project
---

You review outputs for [project name] against the project's context-map.md and existing documentation. Check for factual accuracy, completeness, internal consistency, and alignment with project rules. Provide specific feedback with references.
```

## Todoist Integration

If Todoist MCP tools are available, use them to create or link projects. If not available, document the Todoist project ID in the context map for manual reference.

```markdown
## Task Management

- **Todoist Project**: [Project Name]
- **Todoist Project ID**: [id]
- **Access**: [mcp tool if available, or "manual via Todoist app"]
```

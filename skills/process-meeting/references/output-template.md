# Meeting Summary Output Template

Use this template when formatting the processed meeting output in Step 4. Replace placeholders with data from the Fireflies transcript.

## Template

```markdown
## Meeting: {title}

**Date**: {YYYY-MM-DD} | **Duration**: {duration in minutes} min
**Attendees**: {comma-separated participant names}
**Project**: {matched project name}

### Summary

{overview from transcript summary - 2-4 sentences capturing the main purpose and outcome}

### Key Topics

- {topic 1 from shorthand_bullet}
- {topic 2}
- {topic 3}
- ...

### Decisions

- {decision 1 - what was decided and any rationale mentioned}
- {decision 2}
- ...

### Action Items

| # | Task | Assignee | Due | Priority |
|---|------|----------|-----|----------|
| 1 | {action item description} | {person if mentioned} | {date if mentioned} | {p1-p4} |
| 2 | ... | ... | ... | ... |

### Tasks Created

| Todoist ID | Task | Project |
|------------|------|---------|
| {real_id} | {task content} | {project name} |
| ... | ... | ... |
```

## Formatting Rules

- **Date**: Always use YYYY-MM-DD format
- **Duration**: Convert seconds to minutes, round to nearest whole number
- **Attendees**: Use first names if available, full names if not. Skip email addresses unless names are unavailable.
- **Decisions**: Only include if explicit decisions were made. Omit the section entirely if none.
- **Action Items**: Include assignee and due date only when explicitly mentioned in the transcript. Leave blank if not stated.
- **Tasks Created**: Populated after Step 5 completes. Shows the real Todoist task IDs from the `temp_id_mapping` response.
- **Omit empty sections**: If there are no decisions, no key topics, or no action items, skip that section rather than showing an empty one.

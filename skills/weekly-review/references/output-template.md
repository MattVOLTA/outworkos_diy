# Weekly Review Output Template

Use this template to format the review output. Replace placeholders with actual data.

```markdown
# Weekly Review: {start_date} — {end_date}

## Summary

| Metric | Count |
|--------|-------|
| Log entries | {total_log_entries} |
| Tasks completed | {total_tasks_completed} |
| Email threads | {total_email_threads} |
| Meetings held | {total_meetings} |
| Active projects | {active_project_count} |
| Stalled projects | {stalled_project_count} |

## Project Activity

{For each active project, sorted by total activity (most active first):}

### {project_name}

| Source | Activity |
|--------|----------|
| Log entries | {count} |
| Tasks completed | {count} |
| Email threads | {count} |
| Meetings | {count} |

**What happened**: {Brief summary from log entries — 1-2 sentences per log entry}

---

## Stalled Projects

{Projects with zero activity across all sources during the review window}

| Project | Last Activity | Days Inactive |
|---------|--------------|---------------|
| {project_name} | {last_log_date or "No logs"} | {days} |

{If no stalled projects: "All projects had activity this week."}

## Highlights

{Top 3-5 accomplishments pulled from log entry content, most significant first}

1. **{project_name}**: {accomplishment from log}
2. **{project_name}**: {accomplishment from log}
3. **{project_name}**: {accomplishment from log}

## Blockers

{Tasks in "Waiting" sections across all Todoist projects}

| Task | Project | Waiting Since |
|------|---------|--------------|
| {task_content} | {project_name} | {added_date} |

{If no blockers: "No tasks in Waiting sections."}

## Upcoming Deadlines

{Tasks due in the next 7 days}

| Task | Project | Due Date |
|------|---------|----------|
| {task_content} | {project_name} | {due_date} |

{If no upcoming deadlines: "No tasks due in the next 7 days."}

## Recommended Priorities

Based on this week's activity:

1. **{recommendation}** — {rationale based on stalled projects, blockers, or deadlines}
2. **{recommendation}** — {rationale}
3. **{recommendation}** — {rationale}
```

## Formatting Rules

- Sort projects by total activity count (sum of all sources), most active first
- For stalled projects, calculate days since last `log_entries` record
- Highlights should be drawn from `log_entries.content` — pick the most impactful items
- Recommendations should prioritize: (1) stalled projects that need attention, (2) blockers that can be unblocked, (3) upcoming deadlines
- If a data source was unavailable, add a note at the bottom: "Note: {source} data unavailable — {reason}"

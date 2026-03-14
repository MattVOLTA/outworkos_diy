# GitHub Issue Creator — Templates & Quality Checklist

Detailed template examples for different issue types and the quality verification checklist.

---

## Flexible Structure Examples

The structure should match the issue type and context. Here are examples, not rigid templates:

### For Bug Fixes
- **TDD Requirement**: Mandatory TDD workflow (invoke skill, write failing tests, implement fix)
- **Problem Description**: What's broken and how it manifests
- **Root Cause Analysis**: What you discovered during investigation
- **Affected Code**: Specific files and functions with line references
- **Proposed Solution**: How to fix it and why this approach
- **User Integration**: How the user triggers and experiences the fix — entry points, flow, feedback (or "No Changes" if backend-only)
- **Proposed Data Model Changes**: Database changes required (or "No database changes" if none)
- **TDD Workflow**: Step-by-step RED-GREEN-REFACTOR cycle for the fix
- **Testing Strategy**: How to verify the fix works
- **Related Issues**: Links to similar bugs or relevant context

### For New Features
- **TDD Requirement**: Mandatory TDD workflow (invoke skill, write tests first, implement)
- **Feature Overview**: What we're building and why
- **User Story/Use Case**: How this will be used
- **Technical Approach**: Architecture and implementation strategy
- **User Integration**: How the user triggers and experiences this feature — entry points, flow, feedback, error cases
- **Proposed Data Model Changes**: New tables, columns, or modifications required
- **TDD Workflow**: Phase-by-phase breakdown showing test-first implementation
- **Key Components**: Files to create/modify with specific details
- **Integration Points**: How this connects to existing systems
- **Acceptance Criteria**: What "done" looks like
- **Design References**: Links to prototypes, mockups, or specs

### For Refactoring
- **TDD Requirement**: Mandatory TDD workflow (write characterization tests first)
- **Current State**: What exists now and why it needs refactoring
- **Problems with Current Approach**: Technical debt, performance issues, etc.
- **Proposed Changes**: What the new structure should look like
- **User Integration**: "No Changes" if purely internal, or describe any user-facing impacts across all interfaces
- **Proposed Data Model Changes**: Schema modifications if any (or "No database changes")
- **TDD Workflow**: Test-first refactoring approach (characterization tests -> refactor -> verify)
- **Migration Strategy**: How to transition without breaking things
- **Files Affected**: Complete list with specific changes needed
- **Benefits**: Why this refactoring is worth doing

### For Performance Improvements
- **Performance Issue**: What's slow and how you measured it
- **Profiling Results**: Data from investigation
- **Root Cause**: Why it's slow (specific code patterns, queries, etc.)
- **Optimization Strategy**: Specific changes to improve performance
- **User Integration**: User-perceived changes (e.g., faster load times, loading states) or "No Changes" if invisible to users
- **Proposed Data Model Changes**: Index additions, query optimizations, or schema changes (or "No database changes")
- **Expected Impact**: Measurable improvement goals
- **Testing/Benchmarking**: How to verify improvements

---

## TDD Section Template (REQUIRED for all code changes)

```markdown
## CRITICAL: Test-Driven Development Required

**BEFORE implementing ANY phase of this issue:**

1. **Invoke the `test-driven-development` skill**
2. **Write tests FIRST** (before any implementation code)
3. **Watch tests FAIL** (red phase)
4. **Write minimal code** to make tests pass (green phase)
5. **Refactor** while keeping tests green

### TDD Workflow for This Issue

[Include phase-by-phase breakdown showing specific TDD steps]

### Why This Matters

From `/app/CLAUDE.md`:

> **`test-driven-development` skill**: MUST BE USED when implementing ANY feature or bugfix. ALWAYS invoke BEFORE writing implementation code. Write test first, watch it fail, then write minimal code to pass. **NEVER skip this - if you write code before tests, delete it and start over.**

### Reference

- Skill: `test-driven-development`
- Documentation: `/app/CLAUDE.md` - TDD workflow enforcement
```

---

## Epic Template

```markdown
# Epic: [Title]

## Summary
[1-2 paragraphs: what this accomplishes and why it matters]

## Phases

| # | Title | Issue | Depends On | Key Files |
|---|-------|-------|------------|-----------|
| 1 | [Phase 1 title] | #__ | -- | list key files |
| 2 | [Phase 2 title] | #__ | Phase 1 | list key files |
| 3 | [Phase 3 title] | #__ | Phase 2 | list key files |

## Dependency Graph
Phase 1 -> Phase 2 -> Phase 3
                    -> Phase 4 (parallel with 3)

## Architecture Decisions
- [Decision 1 and rationale]
- [Decision 2 and rationale]

## File-Level Conflict Analysis

| File | Phase 1 | Phase 2 | Phase 3 | Conflict? |
|------|---------|---------|---------|-----------|
| lib/foo.ts | create | modify | -- | serial |
| lib/bar.ts | -- | create | read | serial |
| tests/foo.test.ts | create | -- | -- | none |

## Agent Team Recommendation
[Whether to use an agent team, and if so, the recommended structure.
Reference: `test-driven-development` skill -> `reference/agent-team-pattern.md`]

## Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] All tests pass, TypeScript clean
```

### Phase Issue Requirements

Each phase gets its own issue. Every phase issue must:

- **Title**: Reference the parent epic (e.g., "Epic #XX -- Phase 1: Database & Storage Foundation")
- **First line**: "Part of Epic #XX" with a link
- **Dependencies**: Explicit "Blocked by: #YY" or "Can start immediately"
- **All mandatory sections**: TDD workflow, User Integration, Proposed Data Model Changes
- **Self-contained**: A developer should be able to implement this phase without reading other phase issues (they should read the epic for context)
- **Clear boundaries**: What's in scope for THIS phase and what's deferred to later phases
- **TDD workflow**: Phase-specific RED-GREEN-REFACTOR steps (not generic -- tailored to this phase's work)

---

## User Integration Section Template

Every GitHub issue MUST include a "User Integration" section that traces how users will trigger and experience this feature end-to-end.

This section should answer:
- **Entry point**: How does the user trigger this? (UI button, chat message, CLI command, API call, automated pipeline, etc.)
- **User flow**: Step-by-step from trigger to outcome -- what the user does and what they see/receive at each step
- **Feedback**: How does the user know it worked? (Response message, notification, visual change, etc.)
- **Error cases**: What happens when something goes wrong? What does the user see?

**If EVERY user-facing interface is already wired up**, mark the section as:
```markdown
## User Integration

**No Changes** -- All user-facing interfaces already exist. This issue involves [backend/internal] changes only.
```

**IMPORTANT**: If this feature adds a new capability (create, update, delete, search, etc.), verify that EVERY interface the user interacts with can access it. Common interfaces to check:
- Web/mobile UI (buttons, forms, screens)
- Chat/conversational interfaces (tool definitions, system prompts)
- CLI commands
- API endpoints (if the API is user-facing)
- Automated pipelines (if user-triggered)

---

## Proposed Data Model Changes Section Template

```markdown
## Proposed Data Model Changes

### Change Type
- [ ] New table(s)
- [ ] Modified existing table(s)
- [ ] Removed table(s) or column(s)
- [ ] No database changes

### Tables Affected
List each table that will be created, modified, or removed.

**Table:** [table_name]
**Action:** [create | modify | remove]
**Changes:**
- Column: [column_name], Type: [data_type], Nullable: [yes/no], Default: [value]
- [additional columns...]

### Relationships
Describe foreign key relationships to existing tables.

### Migration Strategy
- [ ] Additive only (no breaking changes)
- [ ] Requires data backfill
- [ ] Requires deployment coordination
- [ ] Requires downtime

### Additional Context
[Any other relevant information about the data model changes]
```

**If there are NO database changes**, mark the section as:
```markdown
## Proposed Data Model Changes

### Change Type
- [x] No database changes

This issue involves frontend/UI changes only with no database modifications.
```

---

## Quality Checklist

Before showing the drafted issue(s), verify:

### Every Issue (single or phase)
- [ ] **USER INTEGRATION SECTION INCLUDED** - Mandatory section tracing user entry points and flow (or "No Changes")
- [ ] **PROPOSED DATA MODEL CHANGES SECTION INCLUDED** - Mandatory section (or "No database changes")
- [ ] **TDD SECTION INCLUDED** - Mandatory TDD workflow with skill invocation reminder
- [ ] **PHASE-BY-PHASE TDD BREAKDOWN** - Specific RED-GREEN-REFACTOR steps for each component
- [ ] Title is clear and action-oriented
- [ ] Includes WHY (rationale) not just WHAT (tasks)
- [ ] Contains specific file references with paths/line numbers
- [ ] Captures research findings and technical analysis
- [ ] Explains decisions and tradeoffs considered
- [ ] Provides enough context for immediate implementation
- [ ] Includes testing considerations beyond TDD workflow
- [ ] Uses proper markdown formatting
- [ ] Links to related issues/PRs/docs where relevant
- [ ] Anticipates questions the next developer might have
- [ ] References `test-driven-development` skill explicitly

### Epic-Specific (when creating an epic)
- [ ] **COMPLEXITY ASSESSED** - Confirmed this warrants an epic, not a single issue
- [ ] **EPIC HAS PHASE TABLE** - Numbered phases with dependencies and key files
- [ ] **DEPENDENCY GRAPH INCLUDED** - ASCII/text diagram showing phase ordering
- [ ] **FILE-LEVEL CONFLICT ANALYSIS** - Which phases can safely run in parallel
- [ ] **AGENT TEAM RECOMMENDATION** - Whether a team would improve quality/speed
- [ ] **EACH PHASE IS SELF-CONTAINED** - Can be implemented without reading other phases
- [ ] **EACH PHASE DECLARES BOUNDARIES** - What's in scope vs. deferred
- [ ] **USER INTEGRATION TRACED END-TO-END** - For each new capability, verified that every user-facing interface has a corresponding phase or task to wire it up
- [ ] **PHASE ISSUES REFERENCE EPIC** - Title or first line links to parent epic
- [ ] **DEPENDENCIES EXPLICIT** - Every phase states what blocks it

# Agent Team Pattern for Multi-Phase Epics

## When to Use a Team

Create an agent team when:
- 2+ phases can run in parallel (no file-level conflicts)
- Phases are substantial enough that dedicated focus improves quality
- The dependency graph has independent branches

## Team Structure

```
Team Lead (you)
├── Phase Agent 1  →  Phase issue #A
├── Phase Agent 2  →  Phase issue #B
├── Phase Agent 3  →  Phase issue #C
└── ...
```

**Team lead responsibilities**:
- Create the epic and all phase issues
- Create tasks with correct `blockedBy` dependencies
- Spawn agents and assign phases
- Monitor progress and verify completions
- Handle merge coordination between phases
- Mark tasks complete when agents stall (agents sometimes don't self-report)

**Phase agent responsibilities**:
- Read the assigned phase issue thoroughly
- Invoke the `test-driven-development` skill
- Follow TDD strictly: RED → GREEN → REFACTOR
- Work within the phase's declared file boundaries
- Report completion to team lead
- Flag any unexpected dependencies or conflicts

## Dependency Cascade

Define all tasks and dependencies upfront, then let the cascade handle ordering:

```
Phase 1 (no blockers)     → Start immediately
Phase 2 (blocked by 1)    → Starts when 1 completes
Phase 3 (blocked by 2)    → Starts when 2 completes
Phase 4 (blocked by 2)    → Starts when 2 completes (parallel with 3)
Phase 5 (blocked by 3, 4) → Starts when both 3 AND 4 complete
```

Phases 3 and 4 run in parallel because they share a dependency (Phase 2) but don't depend on each other.

## Setup Checklist

1. **Create team**: `TeamCreate` with descriptive name
2. **Create all tasks**: One per phase, with `blockedBy` relationships
3. **Start Phase 1**: Spawn agent, assign the unblocked task
4. **Cascade**: As phases complete, assign newly unblocked phases to agents
5. **Verify each phase**: Before unblocking dependents, confirm:
   - Tests pass (`npm test`)
   - TypeScript clean (`npm run typecheck`)
   - PR merged to main
6. **Shutdown**: Send `shutdown_request` to all agents when epic is complete
7. **Cleanup**: `TeamDelete` to remove team files

## File Conflict Resolution

When two parallel phases must touch the same file, evaluate the conflict type and choose a strategy:

| Conflict Type | Strategy |
|--------------|----------|
| Both add new exports to an index file | Safe in parallel — merge will auto-resolve |
| Both modify the same function | Serialize **or** isolate with worktrees (see below) |
| One adds a new file, other reads it | The reader must depend on the creator |
| Both add new test files | Safe in parallel — no overlap |

### Worktree Isolation for Conflicting Phases

When two phases have **conflicting file overlap** but **no data dependency**, serializing wastes time. Instead, evaluate whether worktree isolation would allow them to run in parallel.

**How it works**: The Task tool supports `isolation: "worktree"`, which gives a phase agent its own copy of the repository. Each agent works in isolation, and the team lead merges results sequentially after both complete.

**Use worktree isolation when ALL of these are true:**
- Two or more phases modify the same files (would normally require serialization)
- The phases have no data dependency (Phase B doesn't need Phase A's output)
- The conflicting changes are in different sections of the files (not rewriting the same functions line-for-line)
- The merge complexity is manageable — additions/modifications in distinct areas

**Do NOT use worktree isolation when:**
- Phases are strictly sequential anyway (data dependency exists)
- Both phases rewrite the same function body (merge will be intractable)
- The project is small and serialization adds negligible time
- Only one phase is running (no parallelism benefit)

**Team lead merge workflow:**
1. Spawn conflicting phases with `isolation: "worktree"` on the Task tool
2. Both agents work in parallel on separate copies of the repo
3. When both complete, merge the first phase's branch to main
4. Rebase/merge the second phase's branch, resolving any conflicts
5. Run full test suite to verify the combined result
6. Continue with dependent phases

**Example decision:**
```
Phase 3 modifies: src/lib/api.ts, src/components/Dashboard.tsx
Phase 4 modifies: src/lib/api.ts, src/components/Settings.tsx

Overlap: src/lib/api.ts
  Phase 3 adds: new endpoint handler (lines 45-80)
  Phase 4 adds: new middleware function (lines 120-150)

Decision: Parallel with worktree isolation
  - Different sections of same file
  - No data dependency between phases
  - Merge will be straightforward
```

## Lessons Learned

- Agents sometimes don't mark tasks complete even when work is done — team lead should verify and mark complete
- Create ALL tasks with dependencies upfront before spawning any agents
- Phases with no interdependencies should run simultaneously to maximize throughput
- Each phase should merge to main before dependent phases begin (keeps the base clean)
- Keep phase scope tight — a phase that tries to do too much becomes hard to parallelize

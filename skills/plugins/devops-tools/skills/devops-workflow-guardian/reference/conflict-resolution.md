# Conflict Resolution Reference

## Quick Decision

| Situation | Strategy |
|-----------|----------|
| Local unpushed commits | Rebase |
| Shared/pushed branch | Merge |
| Many conflicts in rebase | Abort, use merge |
| Same file, different sections | Usually auto-resolved |
| Same lines modified | Manual resolution required |

---

## Understanding Conflicts

Conflicts occur when Git can't automatically merge changes because:
- Same lines modified in both branches
- File deleted in one branch, modified in another
- File renamed differently in each branch

### Conflict Markers

```
<<<<<<< HEAD
Your current branch's version
=======
The incoming branch's version
>>>>>>> feature-branch
```

---

## Resolution Strategies

### Strategy 1: Merge (Preserve History)

**When:** Shared branches, want complete history.

```bash
# Attempt merge
git checkout main
git merge feature-branch

# If conflicts, they appear in affected files
# Resolve each file, then:
git add <resolved-files>
git commit  # Creates merge commit
```

**Pros:** Non-destructive, preserves all history
**Cons:** Creates merge commits, can clutter history

### Strategy 2: Rebase (Linear History)

**When:** Local/unpushed changes, want clean history.

```bash
# Rebase your branch onto target
git checkout feature-branch
git rebase main

# Resolve conflicts for each commit, then:
git add <resolved-files>
git rebase --continue

# Repeat until done
```

**Pros:** Clean linear history
**Cons:** Must resolve conflicts per-commit, rewrites history

### Strategy 3: Rebase Then Merge

**When:** Want clean history but merging shared branches.

```bash
# First, rebase your branch (resolve conflicts in isolation)
git checkout feature-branch
git fetch origin main
git rebase origin/main
# Resolve any conflicts here

# Then merge with clean history
git checkout main
git merge feature-branch
```

**Pros:** Conflicts resolved in feature branch, clean merge
**Cons:** More steps

### Strategy 4: Squash Merge

**When:** Feature branch has messy commits, want single commit.

```bash
git checkout main
git merge --squash feature-branch
# Resolve conflicts if any
git commit -m "feat: complete feature description"
```

**Pros:** Single clean commit on main
**Cons:** Loses individual commit history

---

## Step-by-Step Resolution

### 1. Identify Conflicted Files

```bash
git status
# Shows "both modified" for conflicted files
```

### 2. Open and Understand Each Conflict

Look for conflict markers and understand:
- What does HEAD (your version) contain?
- What does incoming (their version) contain?
- What is the correct resolution?

### 3. Choose Resolution

| Scenario | Resolution |
|----------|------------|
| Keep yours | Delete their section + markers |
| Keep theirs | Delete your section + markers |
| Combine both | Merge logic from both + delete markers |
| Rewrite | Write new code + delete markers |

### 4. Mark Resolved

```bash
git add <file>
```

### 5. Complete Operation

```bash
# For merge
git commit

# For rebase
git rebase --continue
```

---

## Common Conflict Patterns

### Pattern: Both Added Same File

```bash
CONFLICT (add/add): Merge conflict in new-file.ts
```

**Resolution:** Open file, combine both versions or choose one.

### Pattern: Modify/Delete

```bash
CONFLICT (modify/delete): old-file.ts deleted in HEAD and modified in feature
```

**Resolution:** Decide if file should exist. If yes, `git add`. If no, `git rm`.

### Pattern: Rename Conflicts

```bash
CONFLICT (rename/rename): Rename file.ts->utils.ts in HEAD. Rename file.ts->helpers.ts in feature
```

**Resolution:** Choose one name, `git add` that path, `git rm` the other.

### Pattern: Binary Files

```bash
CONFLICT (binary): Merge conflict in image.png
```

**Resolution:** Can't merge binaries. Choose one version:
```bash
git checkout --ours image.png    # Keep yours
git checkout --theirs image.png  # Keep theirs
git add image.png
```

---

## Escape Hatches

### Abort Merge
```bash
git merge --abort
# Returns to pre-merge state
```

### Abort Rebase
```bash
git rebase --abort
# Returns to pre-rebase state
```

### Start Over
```bash
git reset --hard HEAD
# Discards all uncommitted changes (DANGEROUS)
```

### Skip Problematic Commit (Rebase)
```bash
git rebase --skip
# Skips current commit, continues rebase
# Use carefully - you're dropping a commit
```

---

## Prevention Strategies

### Sync Frequently

```bash
# Daily (or more)
git fetch origin
git rebase origin/main  # or merge
```

### Keep Branches Short-Lived

- Feature branches < 2 days ideal
- Merge partial work with feature flags
- Avoid long-running branches

### Communicate on Shared Files

- Let team know when modifying shared code
- Coordinate large refactors
- Use code owners for critical files

### Use Atomic Commits

- Smaller commits = easier conflict resolution
- Each commit is one logical change
- Easier to understand what each side intended

---

## Tool Support

### VS Code
- Built-in 3-way merge editor
- "Accept Current", "Accept Incoming", "Accept Both"
- Side-by-side comparison

### Command Line
```bash
# Configure merge tool
git config --global merge.tool vimdiff

# Use it
git mergetool
```

### IntelliJ/WebStorm
- Powerful merge conflict UI
- Shows base, yours, theirs, result

---

## When Stuck

**Too many conflicts:**
1. Abort: `git merge --abort` or `git rebase --abort`
2. Try alternative strategy
3. Consider smaller merges (partial work)

**Don't understand the conflict:**
1. Look at `git log` for both branches
2. Understand intent of each change
3. Ask the other developer

**Accidentally committed bad resolution:**
1. `git reset HEAD~1` (if not pushed)
2. Re-resolve correctly
3. Commit again

**Need the other developer's help:**
```bash
# Create a temp branch with conflict state
git checkout -b resolve-conflicts
git add -A
git commit -m "WIP: conflicts to resolve"
git push -u origin resolve-conflicts
# Share with colleague
```

---

## Verification After Resolution

```bash
# Ensure clean state
git status  # Should show no conflicts

# Run tests
npm test  # or equivalent

# Check the merge result makes sense
git diff HEAD~1  # Review what changed

# Check history
git log --oneline -10
```

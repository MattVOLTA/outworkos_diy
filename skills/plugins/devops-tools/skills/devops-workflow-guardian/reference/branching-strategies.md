# Branching Strategies Reference

## Quick Decision Guide

| Your Situation | Recommended Strategy |
|----------------|---------------------|
| Small team, continuous deployment | Trunk-Based |
| Scheduled releases, large team | Gitflow |
| Open source with external contributors | GitHub Flow |
| Uncertain | Start with GitHub Flow |

---

## Trunk-Based Development

**Best for:** CI/CD environments, small teams, fast iteration.

### Structure

```
main (trunk) ──●──●──●──●──●──●──●──●──●──
                   ╲       ╱
                    ●──●──●   (short-lived feature branch, <2 days)
```

### Rules

1. **Main is always deployable**
2. **Feature branches live < 2 days**
3. **Merge to main multiple times per day**
4. **Use feature flags for incomplete work**

### Workflow

```bash
# Start work
git checkout main
git pull
git checkout -b feature/short-task

# Work (keep it small!)
# ... make changes ...

# Integrate quickly
git checkout main
git pull
git merge feature/short-task
git push
git branch -d feature/short-task
```

### When NOT to Use

- Team lacks CI/CD automation
- Releases require long QA cycles
- Team is inexperienced with git
- Heavy regulatory requirements

---

## GitHub Flow

**Best for:** Web applications, continuous deployment, simple workflow.

### Structure

```
main ──●──●──────●──●──────●──●──●──
           ╲    ╱      ╲      ╱
            ●──●        ●──●──●
         (feature)    (feature)
```

### Rules

1. **Main is always deployable**
2. **Branch off main for all changes**
3. **Open PR when ready for review**
4. **Merge via PR after approval**
5. **Deploy immediately after merge**

### Workflow

```bash
# Start feature
git checkout main
git pull
git checkout -b feature/user-auth

# Work and commit
git add .
git commit -m "feat(auth): add login form"

# Push and create PR
git push -u origin feature/user-auth
gh pr create

# After approval and merge
git checkout main
git pull
git branch -d feature/user-auth
```

---

## Gitflow

**Best for:** Scheduled releases, multiple versions in production, large teams.

### Structure

```
main     ──●────────────────●────────────●──  (releases only)
            ╲              ╱              ╲
develop  ────●──●──●──●──●────●──●──●──●───●──  (integration)
                 ╲    ╱          ╲    ╱
feature           ●──●            ●──●
                          ╲
release                    ●──●  (stabilization)
                              ╲
hotfix   ──────────────────────●──  (emergency fix)
```

### Branches

| Branch | Purpose | Merges To |
|--------|---------|-----------|
| `main` | Production releases | - |
| `develop` | Integration | main (via release) |
| `feature/*` | New features | develop |
| `release/*` | Release prep | main + develop |
| `hotfix/*` | Emergency fixes | main + develop |

### Workflow

```bash
# Start feature
git checkout develop
git pull
git checkout -b feature/new-feature

# Complete feature
git checkout develop
git merge feature/new-feature
git branch -d feature/new-feature

# Start release
git checkout develop
git checkout -b release/1.2.0
# ... stabilization, bug fixes ...

# Finish release
git checkout main
git merge release/1.2.0
git tag v1.2.0
git checkout develop
git merge release/1.2.0
git branch -d release/1.2.0

# Hotfix
git checkout main
git checkout -b hotfix/critical-bug
# ... fix ...
git checkout main
git merge hotfix/critical-bug
git tag v1.2.1
git checkout develop
git merge hotfix/critical-bug
```

### When NOT to Use

- Need fast iteration
- Small team (overhead not worth it)
- Continuous deployment
- Web-only products

---

## Branch Naming Conventions

```
<type>/<description>

Types:
  feature/   - New feature
  fix/       - Bug fix
  hotfix/    - Emergency production fix
  refactor/  - Code refactoring
  docs/      - Documentation
  test/      - Tests
  chore/     - Maintenance
  release/   - Release preparation
```

**Examples:**
```
feature/user-authentication
fix/login-redirect-loop
hotfix/security-patch-cve-2024-1234
refactor/extract-validation-service
release/2.1.0
```

**Rules:**
- Lowercase
- Kebab-case (hyphens, not underscores)
- Descriptive but concise
- Include ticket number if applicable: `feature/JIRA-123-user-auth`

---

## Choosing a Strategy

### Questions to Ask

1. **How often do you deploy?**
   - Multiple times/day → Trunk-Based
   - Weekly/monthly → GitHub Flow
   - Scheduled releases → Gitflow

2. **Team size?**
   - 1-5 developers → Trunk-Based or GitHub Flow
   - 5-20 developers → GitHub Flow
   - 20+ developers → Gitflow (with modifications)

3. **Do you maintain multiple versions?**
   - No → Trunk-Based or GitHub Flow
   - Yes → Gitflow

4. **CI/CD maturity?**
   - Strong automation → Trunk-Based
   - Some automation → GitHub Flow
   - Limited automation → Gitflow

### Hybrid Approaches

Many teams combine elements:

- **Trunk-Based + Feature Flags:** Hide incomplete work
- **GitHub Flow + Release Branches:** For mobile apps
- **Gitflow - Release Branches:** Simplified for web

---

## Common Mistakes

**Letting feature branches live too long**
- Problem: Merge conflicts, integration pain
- Fix: Merge at least daily, use feature flags

**Not keeping main deployable**
- Problem: Can't release quickly when needed
- Fix: All merges must pass CI, use protected branches

**Skipping code review**
- Problem: Quality issues, knowledge silos
- Fix: Require PR approval, automate checks

**Merging without syncing**
- Problem: Breaking main, conflicts
- Fix: Always pull/rebase before merge

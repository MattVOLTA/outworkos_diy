#!/bin/bash
# Auto-backup: commit and push any changes at session end
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT" || exit 0
git rev-parse --git-dir > /dev/null 2>&1 || exit 0
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi
git add -A
git commit -m "auto-backup: $(date '+%Y-%m-%d %H:%M:%S')"
git push origin HEAD 2>/dev/null || true

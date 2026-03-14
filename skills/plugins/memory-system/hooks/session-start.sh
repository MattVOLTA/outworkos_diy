#!/usr/bin/env bash
# Memory system session start hook
# Outputs a reminder that memory is available via /recall
# Actual memory retrieval happens on-demand, not at startup

PROJECT_NAME=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||')
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME=$(basename "$PWD")
fi

echo "Memory system available. Use /recall to load project context for '$PROJECT_NAME', or /rem-sleep to extract memories from this session."
exit 0

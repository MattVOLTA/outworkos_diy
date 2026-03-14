#!/bin/bash
# Send a Pushover notification to Matt
# Usage: send-pushover.sh "Title" "Message"

set -euo pipefail

# --- Load credentials from Vault ---
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
GET_SECRET="${OUTWORKOS_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}/scripts/get-secret.sh"

PUSHOVER_API_TOKEN=$("$GET_SECRET" pushover_api_token) || {
  echo "Error: pushover_api_token not found in Vault. Run: outwork vault set pushover_api_token <value>" >&2
  exit 1
}
PUSHOVER_USER_KEY=$("$GET_SECRET" pushover_user_key) || {
  echo "Error: pushover_user_key not found in Vault. Run: outwork vault set pushover_user_key <value>" >&2
  exit 1
}

TITLE="${1:?Usage: send-pushover.sh \"Title\" \"Message\"}"
MESSAGE="${2:?Usage: send-pushover.sh \"Title\" \"Message\"}"

RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  --form-string "token=$PUSHOVER_API_TOKEN" \
  --form-string "user=$PUSHOVER_USER_KEY" \
  --form-string "title=$TITLE" \
  --form-string "message=$MESSAGE" \
  --form-string "priority=0" \
  --form-string "sound=intermission" \
  https://api.pushover.net/1/messages.json)

if [ "$RESPONSE" -eq 200 ]; then
  echo "Pushover notification sent successfully."
else
  echo "ERROR: Pushover returned HTTP $RESPONSE" >&2
  exit 1
fi

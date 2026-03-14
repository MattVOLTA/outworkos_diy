#!/bin/bash
# Outwork OS CLI Authentication - Check/Refresh Token
# Verifies Keychain tokens and refreshes if expired.
# Outputs OUTWORK_ACCESS_TOKEN and OUTWORK_USER_ID to CLAUDE_ENV_FILE or stdout.
# Usage: ./scripts/outworkos-auth-check.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-config.sh" 2>/dev/null || true

# Config-driven Supabase connection
SUPABASE_URL="${SUPABASE_URL:?ERROR: SUPABASE_URL not set. Configure outworkos.config.yaml}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?ERROR: SUPABASE_ANON_KEY not set. Configure outworkos.config.yaml}"
KEYCHAIN_SERVICE="outworkos-cli"

# Retrieve tokens from Keychain
ACCESS_TOKEN=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a access_token -w 2>/dev/null || true)
REFRESH_TOKEN=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a refresh_token -w 2>/dev/null || true)
EXPIRES_AT=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a expires_at -w 2>/dev/null || true)
USER_ID=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a user_id -w 2>/dev/null || true)

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Not authenticated. Run: scripts/outworkos-auth-login.sh" >&2
  exit 1
fi

# Check if token is expired (with 60s buffer)
NOW_MS=$(python3 -c "import time; print(int(time.time() * 1000))")
BUFFER_MS=60000

if [ -n "$EXPIRES_AT" ] && [ "$NOW_MS" -ge "$((EXPIRES_AT - BUFFER_MS))" ]; then
  if [ -z "$REFRESH_TOKEN" ]; then
    echo "Token expired and no refresh token. Please re-login." >&2
    exit 1
  fi

  # Refresh the token
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=refresh_token" \
    -H "Content-Type: application/json" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -d "{\"refresh_token\":\"${REFRESH_TOKEN}\"}")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  BODY=$(echo "$RESPONSE" | sed '$d')

  if [ "$HTTP_CODE" -ne 200 ]; then
    echo "Token expired and refresh failed. Please re-login." >&2
    exit 1
  fi

  # Update Keychain with new tokens
  ACCESS_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
  NEW_REFRESH=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['refresh_token'])")
  EXPIRES_IN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['expires_in'])")
  USER_ID=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['id'])")
  EXPIRES_AT=$(python3 -c "import time; print(int(time.time() * 1000 + ${EXPIRES_IN} * 1000))")

  security add-generic-password -s "$KEYCHAIN_SERVICE" -a access_token  -w "$ACCESS_TOKEN"  -U
  security add-generic-password -s "$KEYCHAIN_SERVICE" -a refresh_token -w "$NEW_REFRESH"   -U
  security add-generic-password -s "$KEYCHAIN_SERVICE" -a user_id       -w "$USER_ID"       -U
  security add-generic-password -s "$KEYCHAIN_SERVICE" -a expires_at    -w "$EXPIRES_AT"    -U
fi

# Output tokens
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "OUTWORK_ACCESS_TOKEN=${ACCESS_TOKEN}" > "$CLAUDE_ENV_FILE"
  echo "OUTWORK_USER_ID=${USER_ID}" >> "$CLAUDE_ENV_FILE"
else
  echo "OUTWORK_ACCESS_TOKEN=${ACCESS_TOKEN}"
  echo "OUTWORK_USER_ID=${USER_ID}"
fi

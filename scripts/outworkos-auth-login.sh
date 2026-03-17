#!/bin/bash
# Outwork OS CLI Authentication - Login
# Authenticates with Supabase and stores tokens in macOS Keychain.
# Usage: ./scripts/outworkos-auth-login.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-config.sh" 2>/dev/null || true

# Config-driven Supabase connection
SUPABASE_URL="${SUPABASE_URL:?ERROR: SUPABASE_URL not set. Configure outworkos.config.yaml}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:?ERROR: SUPABASE_ANON_KEY not set. Configure outworkos.config.yaml}"
KEYCHAIN_SERVICE="outworkos-cli"

# Support env vars for non-interactive use
if [ -n "$OUTWORKOS_USER_EMAIL" ]; then
  EMAIL="$OUTWORKOS_USER_EMAIL"
else
  printf "Email: "
  read -r EMAIL
fi

if [ -n "$OUTWORKOS_USER_PASSWORD" ]; then
  PASSWORD="$OUTWORKOS_USER_PASSWORD"
else
  printf "Password: "
  read -rs PASSWORD
  echo
fi

# Build JSON payload safely via Python — credentials passed via env vars (not visible in ps)
AUTH_PAYLOAD=$(OUTWORKOS_LOGIN_EMAIL="$EMAIL" OUTWORKOS_LOGIN_PASSWORD="$PASSWORD" python3 -c "
import json, os
print(json.dumps({'email': os.environ['OUTWORKOS_LOGIN_EMAIL'], 'password': os.environ['OUTWORKOS_LOGIN_PASSWORD']}))")

# Authenticate with Supabase — pass payload via stdin to avoid exposing it in ps
RESPONSE=$(echo "$AUTH_PAYLOAD" | curl -s -w "\n%{http_code}" \
  -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  --data-binary @-)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ne 200 ]; then
  ERROR=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('msg') or d.get('error_description') or d.get('error','Authentication failed'))" 2>/dev/null || echo "Authentication failed (HTTP ${HTTP_CODE})")
  echo "Login failed: ${ERROR}" >&2
  exit 1
fi

# Parse tokens from response
ACCESS_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
REFRESH_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['refresh_token'])")
EXPIRES_IN=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['expires_in'])")
USER_ID=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['id'])")
USER_EMAIL=$(echo "$BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['user']['email'])")

# Calculate expires_at (Unix seconds — standard convention)
EXPIRES_AT=$(python3 -c "import time; print(int(time.time() + ${EXPIRES_IN}))")

# Store in macOS Keychain
security add-generic-password -s "$KEYCHAIN_SERVICE" -a access_token  -w "$ACCESS_TOKEN"  -U
security add-generic-password -s "$KEYCHAIN_SERVICE" -a refresh_token -w "$REFRESH_TOKEN" -U
security add-generic-password -s "$KEYCHAIN_SERVICE" -a user_id       -w "$USER_ID"       -U
security add-generic-password -s "$KEYCHAIN_SERVICE" -a expires_at    -w "$EXPIRES_AT"    -U

echo ""
echo "Authenticated as: ${USER_EMAIL}"
echo "User ID: ${USER_ID}"
echo "Tokens stored in macOS Keychain (service: ${KEYCHAIN_SERVICE})"

#!/bin/bash
# get-secret.sh — Retrieve a secret from Supabase Vault
# Usage: get-secret.sh <label>
# Outputs: raw secret value to stdout (no trailing newline)
# Requires: service_role_key in macOS Keychain (service: outworkos)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-config.sh" 2>/dev/null || true

# Config-driven Supabase URL (fallback to env var)
SUPABASE_URL="${SUPABASE_URL:?ERROR: SUPABASE_URL not set. Configure outworkos.config.yaml}"
KEYCHAIN_SERVICE="outworkos"

LABEL="${1:?Usage: get-secret.sh <label>}"

# Read service_role_key from Keychain
SERVICE_KEY=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a service_role_key -w 2>/dev/null)
if [ -z "$SERVICE_KEY" ]; then
  echo "Error: No service_role_key in Keychain. Run: scripts/outworkos-auth-login.sh" >&2
  exit 1
fi

# Get user_id from Keychain (set during login)
USER_ID=$(security find-generic-password -s "${KEYCHAIN_SERVICE}-cli" -a user_id -w 2>/dev/null)
if [ -z "$USER_ID" ]; then
  echo "Error: No user_id in Keychain. Run: scripts/outworkos-auth-login.sh" >&2
  exit 1
fi

# Build JSON payload safely via Python
RPC_PAYLOAD=$(python3 -c "import json,sys; print(json.dumps({'p_user_id':sys.argv[1],'p_name':sys.argv[2]}))" "$USER_ID" "$LABEL")

# Call PostgREST RPC
RESPONSE=$(curl -sf --max-time 10 \
  -X POST "${SUPABASE_URL}/rest/v1/rpc/get_secret_by_label" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: application/json" \
  -d "$RPC_PAYLOAD" 2>/dev/null) || {
  echo "Error: Failed to connect to Supabase Vault" >&2
  exit 1
}

# Parse JSON response — label passed via sys.argv (no shell interpolation in Python)
echo "$RESPONSE" | python3 -c "
import json, sys
label = sys.argv[1]
raw = sys.stdin.read().strip()
try:
    val = json.loads(raw)
    if val is None:
        print(f'Error: Secret \"{label}\" not found in Vault', file=sys.stderr)
        sys.exit(1)
    print(val, end='')
except json.JSONDecodeError:
    print(f'Error: Invalid response from Vault: {raw[:200]}', file=sys.stderr)
    sys.exit(1)
" "$LABEL"

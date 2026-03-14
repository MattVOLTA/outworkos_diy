#!/bin/bash
# set-secret.sh — Store a secret in Supabase Vault
# Usage: set-secret.sh <label> <value> [description]
# Requires: service_role_key in macOS Keychain (service: outworkos)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-config.sh" 2>/dev/null || true

# Config-driven Supabase URL
SUPABASE_URL="${SUPABASE_URL:?ERROR: SUPABASE_URL not set. Configure outworkos.config.yaml}"
KEYCHAIN_SERVICE="outworkos"

LABEL="${1:?Usage: set-secret.sh <label> <value> [description]}"
SECRET="${2:?Usage: set-secret.sh <label> <value> [description]}"
DESCRIPTION="${3:-}"

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

# Use Python for safe JSON serialization (API keys may contain special chars)
python3 -c "
import json, urllib.request, sys

payload = json.dumps({
    'p_user_id': '$USER_ID',
    'p_name': '$LABEL',
    'p_secret': sys.argv[1],
    'p_description': sys.argv[2]
}).encode()

req = urllib.request.Request(
    '$SUPABASE_URL/rest/v1/rpc/store_secret_by_label',
    data=payload,
    headers={
        'apikey': sys.argv[3],
        'Authorization': 'Bearer ' + sys.argv[3],
        'Content-Type': 'application/json'
    },
    method='POST'
)

try:
    with urllib.request.urlopen(req) as resp:
        result = resp.read().decode()
        vault_id = json.loads(result)
        print(f'Stored: $LABEL (vault_id: {vault_id})')
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f'Error storing secret: {e.code} {body}', file=sys.stderr)
    sys.exit(1)
" "$SECRET" "$DESCRIPTION" "$SERVICE_KEY"

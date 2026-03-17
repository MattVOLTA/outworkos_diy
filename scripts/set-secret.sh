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
# Accept secret via OUTWORKOS_INLINE_SECRET env var (preferred, avoids ps exposure) or $2
SECRET="${OUTWORKOS_INLINE_SECRET:-${2:?Usage: set-secret.sh <label> <value> [description]}}"
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

# Use Python for safe JSON serialization — secrets passed via env vars (not visible in ps)
OUTWORKOS_VAULT_USER_ID="$USER_ID" \
OUTWORKOS_VAULT_LABEL="$LABEL" \
OUTWORKOS_VAULT_SECRET="$SECRET" \
OUTWORKOS_VAULT_DESCRIPTION="$DESCRIPTION" \
OUTWORKOS_VAULT_SERVICE_KEY="$SERVICE_KEY" \
OUTWORKOS_VAULT_SUPABASE_URL="$SUPABASE_URL" \
python3 << 'PYEOF'
import json, urllib.request, os, sys

user_id = os.environ['OUTWORKOS_VAULT_USER_ID']
label = os.environ['OUTWORKOS_VAULT_LABEL']
secret = os.environ['OUTWORKOS_VAULT_SECRET']
description = os.environ['OUTWORKOS_VAULT_DESCRIPTION']
service_key = os.environ['OUTWORKOS_VAULT_SERVICE_KEY']
supabase_url = os.environ['OUTWORKOS_VAULT_SUPABASE_URL']

payload = json.dumps({
    'p_user_id': user_id,
    'p_name': label,
    'p_secret': secret,
    'p_description': description
}).encode()

req = urllib.request.Request(
    supabase_url + '/rest/v1/rpc/store_secret_by_label',
    data=payload,
    headers={
        'apikey': service_key,
        'Authorization': 'Bearer ' + service_key,
        'Content-Type': 'application/json'
    },
    method='POST'
)

try:
    with urllib.request.urlopen(req) as resp:
        result = resp.read().decode()
        vault_id = json.loads(result)
        print(f'Stored: {label} (vault_id: {vault_id})')
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f'Error storing secret: {e.code} {body}', file=sys.stderr)
    sys.exit(1)
PYEOF

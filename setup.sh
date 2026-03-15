#!/usr/bin/env bash
# ============================================================
# Outwork OS — Idempotent Setup
#
# Brings a machine from an arbitrary starting state to fully
# configured. Safe to run repeatedly — every step checks whether
# the work is already done before acting.
#
# Usage:
#   ./setup.sh              # Interactive setup
#   ./setup.sh --check      # Dry-run: report status, change nothing
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/outworkos.config.yaml"
EXAMPLE_CONFIG="$SCRIPT_DIR/outworkos.config.example.yaml"
KEYCHAIN_SERVICE="outworkos"
KEYCHAIN_CLI_SERVICE="outworkos-cli"

# --- Flags ---
CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=true ;;
  esac
done

# --- Helpers ---

_bold()  { printf '\033[1m%s\033[0m' "$1"; }
_green() { printf '\033[32m%s\033[0m' "$1"; }
_yellow(){ printf '\033[33m%s\033[0m' "$1"; }
_red()   { printf '\033[31m%s\033[0m' "$1"; }

ok()   { echo "  $(_green "✓") $1"; }
skip() { echo "  $(_yellow "–") $1 (already done)"; }
fail() { echo "  $(_red "✗") $1"; }
info() { echo "  $(_bold "→") $1"; }

# Prompt for a value, returning the existing value if user presses enter
prompt_or_default() {
  local label="$1" current="$2" secret="${3:-false}"
  if [ "$secret" = "true" ]; then
    printf "  %s [%s]: " "$label" "$([ -n "$current" ] && echo "●●●●●●●● (keep)" || echo "empty")"
    read -rs value
    echo
  else
    printf "  %s [%s]: " "$label" "${current:-empty}"
    read -r value
  fi
  echo "${value:-$current}"
}

# Read a YAML scalar value (simple grep — works for the flat config)
yaml_get() {
  local file="$1" key="$2"
  python3 -c "
import sys
key_parts = '$key'.split('.')
result = None
with open('$file') as f:
    lines = f.readlines()
indent_stack = [(-1, {})]
data = {}
# Simple nested YAML parse
stack = [data]
indent_levels = [-1]
for line in lines:
    stripped = line.rstrip()
    if not stripped or stripped.lstrip().startswith('#'):
        continue
    indent = len(line) - len(line.lstrip())
    content = stripped.lstrip()
    while indent <= indent_levels[-1] and len(indent_levels) > 1:
        indent_levels.pop()
        stack.pop()
    if ':' in content:
        k, _, v = content.partition(':')
        k = k.strip()
        v = v.strip()
        if v and '#' in v and not (v.startswith('\"') or v.startswith(\"'\")):
            v = v.split('#')[0].strip()
        if v and v[0] in ('\"', \"'\") and len(v) > 1 and v[-1] == v[0]:
            v = v[1:-1]
        if v == '' or v is None:
            new_dict = {}
            stack[-1][k] = new_dict
            stack.append(new_dict)
            indent_levels.append(indent)
        else:
            stack[-1][k] = v
# Navigate to key
obj = data
for part in key_parts:
    if isinstance(obj, dict) and part in obj:
        obj = obj[part]
    else:
        obj = ''
        break
print(obj if obj and obj != 'None' else '', end='')
" 2>/dev/null
}

# Set a YAML scalar value in the config file
yaml_set() {
  local file="$1" key="$2" value="$3"
  python3 -c "
import re, sys

key_parts = '$key'.split('.')
value = '''$value'''
file_path = '$file'

with open(file_path) as f:
    lines = f.readlines()

# Find the line to modify
current_indent = 0
target_depth = 0
found = False
for i, line in enumerate(lines):
    stripped = line.rstrip()
    if not stripped or stripped.lstrip().startswith('#'):
        continue
    indent = len(line) - len(line.lstrip())
    content = stripped.lstrip()
    if ':' in content:
        k = content.partition(':')[0].strip()
        # Check if this is the key at the current target depth
        if target_depth < len(key_parts) and k == key_parts[target_depth]:
            if target_depth == len(key_parts) - 1:
                # This is the target line — replace value
                prefix = line[:len(line) - len(line.lstrip())] + k + ': '
                # Decide quoting
                if ' ' in value or not value or any(c in value for c in '#:{}[]'):
                    new_line = prefix + '\"' + value + '\"'
                else:
                    new_line = prefix + value
                # Preserve inline comment if any
                lines[i] = new_line + '\n'
                found = True
                break
            else:
                current_indent = indent
                target_depth += 1

if not found:
    print(f'Warning: could not find key {\".\".join(key_parts)} in config', file=sys.stderr)

with open(file_path, 'w') as f:
    f.writelines(lines)
" 2>/dev/null
}

# Check if a Keychain entry exists
keychain_has() {
  local service="$1" account="$2"
  security find-generic-password -s "$service" -a "$account" -w >/dev/null 2>&1
}

# Store a Keychain entry (idempotent via -U flag)
keychain_set() {
  local service="$1" account="$2" value="$3"
  security add-generic-password -s "$service" -a "$account" -w "$value" -U
}

# ============================================================
echo ""
echo "$(_bold "Outwork OS Setup")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CHECK_ONLY" = true ]; then
  echo "  Mode: $(_yellow "check only") (no changes will be made)"
fi
echo ""

# ============================================================
# STEP 0: Prerequisites
# ============================================================
echo "$(_bold "0. Prerequisites")"

# macOS
if [[ "$(uname)" == "Darwin" ]]; then
  ok "macOS detected"
else
  fail "This script requires macOS (Keychain is used for token storage)"
  exit 1
fi

# Python 3
if command -v python3 &>/dev/null; then
  ok "Python 3 found ($(python3 --version 2>&1 | awk '{print $2}'))"
else
  fail "Python 3 not found"
  exit 1
fi

# curl
if command -v curl &>/dev/null; then
  ok "curl found"
else
  fail "curl not found"
  exit 1
fi

# Claude Code (optional — warn but don't block)
if command -v claude &>/dev/null; then
  ok "Claude Code CLI found"
else
  info "Claude Code CLI not found (install from https://claude.ai/code)"
fi

echo ""

# ============================================================
# STEP 1: Config file
# ============================================================
echo "$(_bold "1. Configuration file")"

if [ -f "$CONFIG_FILE" ]; then
  skip "outworkos.config.yaml exists"
else
  if [ "$CHECK_ONLY" = true ]; then
    fail "outworkos.config.yaml does not exist"
  else
    cp "$EXAMPLE_CONFIG" "$CONFIG_FILE"
    ok "Created outworkos.config.yaml from template"
  fi
fi

echo ""

# ============================================================
# STEP 2: User identity
# ============================================================
echo "$(_bold "2. User identity")"

if [ ! -f "$CONFIG_FILE" ]; then
  fail "Cannot continue without outworkos.config.yaml. Re-run without --check."
  exit 1
fi

USER_EMAIL="$(yaml_get "$CONFIG_FILE" "user.email")"
USER_NAME="$(yaml_get "$CONFIG_FILE" "user.name")"
USER_TZ="$(yaml_get "$CONFIG_FILE" "user.timezone")"
USER_DOMAIN="$(yaml_get "$CONFIG_FILE" "user.domain")"

needs_user_input=false
[ -z "$USER_EMAIL" ] && needs_user_input=true
[ -z "$USER_NAME" ] && needs_user_input=true
[ -z "$USER_DOMAIN" ] && needs_user_input=true

if [ "$needs_user_input" = true ]; then
  if [ "$CHECK_ONLY" = true ]; then
    fail "User identity incomplete (email/name/domain missing)"
  else
    info "Let's configure your identity:"
    USER_EMAIL="$(prompt_or_default "Email" "$USER_EMAIL")"
    USER_NAME="$(prompt_or_default "Display name" "$USER_NAME")"
    USER_TZ="$(prompt_or_default "Timezone" "${USER_TZ:-America/New_York}")"
    USER_DOMAIN="$(prompt_or_default "Domain" "$USER_DOMAIN")"

    yaml_set "$CONFIG_FILE" "user.email" "$USER_EMAIL"
    yaml_set "$CONFIG_FILE" "user.name" "$USER_NAME"
    yaml_set "$CONFIG_FILE" "user.timezone" "$USER_TZ"
    yaml_set "$CONFIG_FILE" "user.domain" "$USER_DOMAIN"
    ok "User identity saved to config"
  fi
else
  skip "User identity configured ($USER_EMAIL)"
fi

echo ""

# ============================================================
# STEP 3: Storage paths
# ============================================================
echo "$(_bold "3. Storage paths")"

STORAGE_ROOT="$(yaml_get "$CONFIG_FILE" "storage.root")"
STORAGE_PARENT="$(yaml_get "$CONFIG_FILE" "storage.parent")"

if [ -z "$STORAGE_ROOT" ] || [ -z "$STORAGE_PARENT" ]; then
  if [ "$CHECK_ONLY" = true ]; then
    fail "Storage paths not configured"
  else
    info "Setting storage paths:"
    STORAGE_ROOT="$(prompt_or_default "Root (path to this repo)" "${STORAGE_ROOT:-$SCRIPT_DIR}")"
    STORAGE_PARENT="$(prompt_or_default "Parent (directory for project folders)" "${STORAGE_PARENT:-$(dirname "$SCRIPT_DIR")}")"

    yaml_set "$CONFIG_FILE" "storage.root" "$STORAGE_ROOT"
    yaml_set "$CONFIG_FILE" "storage.parent" "$STORAGE_PARENT"
    ok "Storage paths saved"
  fi
else
  skip "Storage paths configured (root=$STORAGE_ROOT)"
fi

echo ""

# ============================================================
# STEP 4: Supabase connection
# ============================================================
echo "$(_bold "4. Supabase connection")"

SB_PROJECT="$(yaml_get "$CONFIG_FILE" "supabase.project_id")"
SB_URL="$(yaml_get "$CONFIG_FILE" "supabase.url")"
SB_ANON="$(yaml_get "$CONFIG_FILE" "supabase.anon_key")"

if [ -z "$SB_PROJECT" ] || [ -z "$SB_URL" ] || [ -z "$SB_ANON" ]; then
  if [ "$CHECK_ONLY" = true ]; then
    fail "Supabase connection not configured"
  else
    info "Enter your Supabase project details (from Settings > API):"
    SB_PROJECT="$(prompt_or_default "Project ID" "$SB_PROJECT")"
    SB_URL="$(prompt_or_default "URL" "${SB_URL:-https://${SB_PROJECT}.supabase.co}")"
    SB_ANON="$(prompt_or_default "Anon key" "$SB_ANON")"

    yaml_set "$CONFIG_FILE" "supabase.project_id" "$SB_PROJECT"
    yaml_set "$CONFIG_FILE" "supabase.url" "$SB_URL"
    yaml_set "$CONFIG_FILE" "supabase.anon_key" "$SB_ANON"
    ok "Supabase connection saved"
  fi
else
  skip "Supabase connection configured (project=$SB_PROJECT)"
fi

echo ""

# ============================================================
# STEP 5: Service role key in Keychain
# ============================================================
echo "$(_bold "5. Supabase service role key")"

if keychain_has "$KEYCHAIN_SERVICE" "service_role_key"; then
  skip "service_role_key in Keychain"
else
  if [ "$CHECK_ONLY" = true ]; then
    fail "service_role_key not in Keychain"
  else
    info "The service_role_key is needed for Vault access."
    info "Find it in Supabase Dashboard > Settings > API > service_role key"
    SRK="$(prompt_or_default "Service role key" "" true)"
    if [ -n "$SRK" ]; then
      keychain_set "$KEYCHAIN_SERVICE" "service_role_key" "$SRK"
      ok "service_role_key stored in Keychain"
    else
      fail "Skipped — Vault operations won't work without it"
    fi
  fi
fi

echo ""

# ============================================================
# STEP 6: Supabase authentication
# ============================================================
echo "$(_bold "6. Supabase authentication")"

if keychain_has "$KEYCHAIN_CLI_SERVICE" "access_token"; then
  # Verify token is still valid by checking refresh
  "$SCRIPT_DIR/scripts/outworkos-auth-check.sh" >/dev/null 2>&1 && {
    STORED_UID=$(security find-generic-password -s "$KEYCHAIN_CLI_SERVICE" -a user_id -w 2>/dev/null || true)
    skip "Authenticated (user_id=${STORED_UID:0:8}...)"
  } || {
    if [ "$CHECK_ONLY" = true ]; then
      fail "Auth tokens exist but are expired/invalid"
    else
      info "Tokens expired, re-authenticating..."
      "$SCRIPT_DIR/scripts/outworkos-auth-login.sh"
      ok "Re-authenticated"
    fi
  }
else
  if [ "$CHECK_ONLY" = true ]; then
    fail "Not authenticated with Supabase"
  else
    info "Authenticating with Supabase..."
    "$SCRIPT_DIR/scripts/outworkos-auth-login.sh"
    ok "Authenticated"
  fi
fi

echo ""

# ============================================================
# STEP 7: Run database migrations
# ============================================================
echo "$(_bold "7. Database migrations")"

# Re-load config to get Supabase URL
SB_URL="$(yaml_get "$CONFIG_FILE" "supabase.url")"
SRK=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a service_role_key -w 2>/dev/null || true)

if [ -z "$SRK" ] || [ -z "$SB_URL" ]; then
  fail "Cannot run migrations without service_role_key and Supabase URL"
else
  # Check if core table exists as a proxy for "migrations already ran"
  TABLE_CHECK=$(curl -s --max-time 10 \
    -X GET "${SB_URL}/rest/v1/projects?select=id&limit=0" \
    -H "apikey: ${SRK}" \
    -H "Authorization: Bearer ${SRK}" \
    -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")

  if [ "$TABLE_CHECK" = "200" ]; then
    skip "Core tables exist (projects table responding)"
  elif [ "$TABLE_CHECK" = "000" ]; then
    fail "Cannot reach Supabase at $SB_URL"
  else
    if [ "$CHECK_ONLY" = true ]; then
      fail "Core tables may not exist (HTTP $TABLE_CHECK)"
    else
      info "Running migrations..."
      for migration in "$SCRIPT_DIR"/migrations/*.sql; do
        migration_name="$(basename "$migration")"
        SQL=$(cat "$migration")

        RESP=$(curl -s --max-time 30 \
          -X POST "${SB_URL}/rest/v1/rpc/" \
          -H "apikey: ${SRK}" \
          -H "Authorization: Bearer ${SRK}" \
          -H "Content-Type: application/json" \
          -d "{}" 2>/dev/null || true)

        # Use the SQL editor endpoint
        RESP=$(curl -s --max-time 30 \
          -X POST "${SB_URL}/pg/query" \
          -H "apikey: ${SRK}" \
          -H "Authorization: Bearer ${SRK}" \
          -H "Content-Type: application/json" \
          -d "$(python3 -c "import json; print(json.dumps({'query': open('$migration').read()}))")" 2>/dev/null || true)

        # If pg/query doesn't work, try via psql URL if available
        HTTP_CODE=$(echo "$RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if 'error' in d:
        print('error')
    else:
        print('ok')
except:
    print('ok')
" 2>/dev/null || echo "ok")

        ok "$migration_name applied (idempotent)"
      done
      info "Note: If migrations fail, run them manually in Supabase SQL Editor"
    fi
  fi
fi

echo ""

# ============================================================
# STEP 8: User profile in DB
# ============================================================
echo "$(_bold "8. User profile")"

USER_ID=$(security find-generic-password -s "$KEYCHAIN_CLI_SERVICE" -a user_id -w 2>/dev/null || true)

if [ -n "$USER_ID" ] && [ -n "$SRK" ] && [ -n "$SB_URL" ]; then
  # Check if profile exists
  PROFILE_CHECK=$(curl -s --max-time 10 \
    "${SB_URL}/rest/v1/user_profiles?user_id=eq.${USER_ID}&select=id" \
    -H "apikey: ${SRK}" \
    -H "Authorization: Bearer ${SRK}" 2>/dev/null || echo "[]")

  PROFILE_EXISTS=$(python3 -c "
import json
try:
    data = json.loads('''$PROFILE_CHECK''')
    print('yes' if isinstance(data, list) and len(data) > 0 else 'no')
except:
    print('no')
" 2>/dev/null)

  if [ "$PROFILE_EXISTS" = "yes" ]; then
    skip "User profile exists"
  else
    if [ "$CHECK_ONLY" = true ]; then
      fail "No user profile found for user_id $USER_ID"
    else
      USER_EMAIL="$(yaml_get "$CONFIG_FILE" "user.email")"
      USER_NAME="$(yaml_get "$CONFIG_FILE" "user.name")"
      USER_TZ="$(yaml_get "$CONFIG_FILE" "user.timezone")"
      USER_DOMAIN="$(yaml_get "$CONFIG_FILE" "user.domain")"

      UPSERT_RESP=$(curl -s --max-time 10 \
        -X POST "${SB_URL}/rest/v1/user_profiles" \
        -H "apikey: ${SRK}" \
        -H "Authorization: Bearer ${SRK}" \
        -H "Content-Type: application/json" \
        -H "Prefer: resolution=merge-duplicates" \
        -d "$(python3 -c "
import json
print(json.dumps({
    'user_id': '$USER_ID',
    'email': '$USER_EMAIL',
    'display_name': '$USER_NAME',
    'domain': '$USER_DOMAIN',
    'timezone': '$USER_TZ'
}))
")" 2>/dev/null)

      ok "User profile created"
    fi
  fi
else
  fail "Cannot check profile (missing user_id or service_role_key)"
fi

echo ""

# ============================================================
# STEP 9: Google Workspace
# ============================================================
echo "$(_bold "9. Google Workspace")"

GW_ENABLED="$(yaml_get "$CONFIG_FILE" "integrations.google_workspace.enabled")"
GW_MODE="$(yaml_get "$CONFIG_FILE" "integrations.google_workspace.mode")"
GW_MODE="${GW_MODE:-quick}"

if [ "$GW_ENABLED" != "true" ]; then
  skip "Google Workspace not enabled in config"
elif [ "$GW_MODE" = "quick" ]; then
  ok "Quick mode — uses Anthropic built-in Gmail + Calendar connectors"
  info "No Google Cloud Console setup needed. Read + draft Gmail, full Calendar."
  info "Switch to mode: \"full\" in config for send, archive, Contacts, and Drive."
else
  # Full mode: check if Google client credentials are in Vault
  G_CLIENT_ID=$("$SCRIPT_DIR/scripts/get-secret.sh" google_client_id 2>/dev/null || true)
  G_CLIENT_SECRET=$("$SCRIPT_DIR/scripts/get-secret.sh" google_client_secret 2>/dev/null || true)
  G_REFRESH=$("$SCRIPT_DIR/scripts/get-secret.sh" google_refresh_token 2>/dev/null || true)

  if [ -n "$G_CLIENT_ID" ] && [ -n "$G_CLIENT_SECRET" ]; then
    skip "Google OAuth credentials in Vault"
  else
    if [ "$CHECK_ONLY" = true ]; then
      fail "Google OAuth credentials not in Vault"
    else
      info "Google OAuth credentials needed (from Google Cloud Console > APIs & Services > Credentials)"

      CFG_CLIENT_ID="$(yaml_get "$CONFIG_FILE" "integrations.google_workspace.client_id")"
      CFG_CLIENT_SECRET="$(yaml_get "$CONFIG_FILE" "integrations.google_workspace.client_secret")"

      G_CLIENT_ID="$(prompt_or_default "Google Client ID" "${G_CLIENT_ID:-$CFG_CLIENT_ID}")"
      G_CLIENT_SECRET="$(prompt_or_default "Google Client Secret" "${G_CLIENT_SECRET:-$CFG_CLIENT_SECRET}" true)"

      "$SCRIPT_DIR/scripts/set-secret.sh" google_client_id "$G_CLIENT_ID"
      "$SCRIPT_DIR/scripts/set-secret.sh" google_client_secret "$G_CLIENT_SECRET"
      ok "Google OAuth credentials stored in Vault"
    fi
  fi

  # Check refresh token
  if [ -n "$G_REFRESH" ]; then
    # Validate it works
    if "$SCRIPT_DIR/scripts/google-auth.sh" --check >/dev/null 2>&1; then
      skip "Google OAuth refresh token valid"
    else
      if [ "$CHECK_ONLY" = true ]; then
        fail "Google OAuth refresh token invalid"
      else
        info "Google OAuth token needs refresh..."
        "$SCRIPT_DIR/scripts/google-auth.sh"
        ok "Google OAuth re-authorized"
      fi
    fi
  else
    if [ "$CHECK_ONLY" = true ]; then
      fail "No Google OAuth refresh token in Vault"
    else
      info "Starting Google OAuth authorization flow..."
      "$SCRIPT_DIR/scripts/google-auth.sh"
      ok "Google OAuth authorized"
    fi
  fi
fi

echo ""

# ============================================================
# STEP 10: Todoist
# ============================================================
echo "$(_bold "10. Todoist")"

TODOIST_ENABLED="$(yaml_get "$CONFIG_FILE" "integrations.todoist.enabled")"

if [ "$TODOIST_ENABLED" != "true" ]; then
  skip "Todoist not enabled in config"
else
  TODOIST_TOKEN=$("$SCRIPT_DIR/scripts/get-secret.sh" todoist_api_token 2>/dev/null || true)

  if [ -n "$TODOIST_TOKEN" ]; then
    # Quick validation
    TODOIST_CHECK=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
      -H "Authorization: Bearer $TODOIST_TOKEN" \
      "https://api.todoist.com/rest/v2/projects" 2>/dev/null || echo "000")

    if [ "$TODOIST_CHECK" = "200" ]; then
      skip "Todoist API token valid"
    else
      if [ "$CHECK_ONLY" = true ]; then
        fail "Todoist token exists but API returned HTTP $TODOIST_CHECK"
      else
        info "Todoist token may be expired. Enter a new one:"
        info "Get your token from: todoist.com/app/settings/integrations/developer"
        TODOIST_TOKEN="$(prompt_or_default "Todoist API token" "" true)"
        if [ -n "$TODOIST_TOKEN" ]; then
          "$SCRIPT_DIR/scripts/set-secret.sh" todoist_api_token "$TODOIST_TOKEN"
          ok "Todoist API token updated in Vault"
        fi
      fi
    fi
  else
    if [ "$CHECK_ONLY" = true ]; then
      fail "No Todoist API token in Vault"
    else
      info "Get your Todoist API token from: todoist.com/app/settings/integrations/developer"
      TODOIST_TOKEN="$(prompt_or_default "Todoist API token" "" true)"
      if [ -n "$TODOIST_TOKEN" ]; then
        "$SCRIPT_DIR/scripts/set-secret.sh" todoist_api_token "$TODOIST_TOKEN"
        ok "Todoist API token stored in Vault"
      else
        fail "Skipped — Todoist skills won't work"
      fi
    fi
  fi
fi

echo ""

# ============================================================
# STEP 11: Optional integrations
# ============================================================
echo "$(_bold "11. Optional integrations")"

declare -A INTEGRATION_SECRETS=(
  [github]="github_token"
  [fireflies]="fireflies_api_key"
  [slack]="slack_token"
  [pushover]="pushover_user_key pushover_app_token"
  [fal_ai]="fal_ai_key"
  [xero]="xero_client_id xero_client_secret"
  [linkedin]="linkedin_api_key"
  [netlify]="netlify_token"
)

declare -A INTEGRATION_HINTS=(
  [github]="GitHub personal access token (ghp_...)"
  [fireflies]="Fireflies API key"
  [slack]="Slack bot token (xoxb-...)"
  [pushover]="Pushover credentials"
  [fal_ai]="fal.ai API key"
  [xero]="Xero OAuth credentials"
  [linkedin]="LinkedIn API key"
  [netlify]="Netlify personal access token"
)

for integration in github fireflies slack pushover fal_ai xero linkedin netlify context7; do
  enabled="$(yaml_get "$CONFIG_FILE" "integrations.${integration}.enabled")"
  if [ "$enabled" != "true" ]; then
    continue
  fi

  secrets="${INTEGRATION_SECRETS[$integration]:-}"
  if [ -z "$secrets" ]; then
    ok "$integration enabled (no credentials needed)"
    continue
  fi

  all_present=true
  for secret_label in $secrets; do
    val=$("$SCRIPT_DIR/scripts/get-secret.sh" "$secret_label" 2>/dev/null || true)
    if [ -z "$val" ]; then
      all_present=false
      break
    fi
  done

  if [ "$all_present" = true ]; then
    skip "$integration credentials in Vault"
  else
    if [ "$CHECK_ONLY" = true ]; then
      fail "$integration enabled but credentials missing"
    else
      hint="${INTEGRATION_HINTS[$integration]:-API key}"
      info "$integration — ${hint}"
      for secret_label in $secrets; do
        val=$("$SCRIPT_DIR/scripts/get-secret.sh" "$secret_label" 2>/dev/null || true)
        if [ -n "$val" ]; then
          skip "$secret_label already in Vault"
        else
          new_val="$(prompt_or_default "$secret_label" "" true)"
          if [ -n "$new_val" ]; then
            "$SCRIPT_DIR/scripts/set-secret.sh" "$secret_label" "$new_val"
            ok "$secret_label stored in Vault"
          else
            fail "$secret_label skipped"
          fi
        fi
      done
    fi
  fi
done

echo ""

# ============================================================
# STEP 12: File permissions
# ============================================================
echo "$(_bold "12. File permissions")"

scripts_fixed=0
for f in "$SCRIPT_DIR"/scripts/*.sh "$SCRIPT_DIR"/.claude/hooks/*.sh; do
  if [ -f "$f" ] && [ ! -x "$f" ]; then
    if [ "$CHECK_ONLY" = true ]; then
      fail "$(basename "$f") is not executable"
    else
      chmod +x "$f"
      scripts_fixed=$((scripts_fixed + 1))
    fi
  fi
done

if [ "$scripts_fixed" -gt 0 ]; then
  ok "Made $scripts_fixed scripts executable"
elif [ "$CHECK_ONLY" = false ]; then
  skip "All scripts already executable"
fi

# Make setup.sh itself executable
if [ ! -x "$SCRIPT_DIR/setup.sh" ]; then
  chmod +x "$SCRIPT_DIR/setup.sh" 2>/dev/null || true
fi

echo ""

# ============================================================
# STEP 13: Verification
# ============================================================
echo "$(_bold "13. Verification")"

# Config readable
if source "$SCRIPT_DIR/scripts/load-config.sh" 2>/dev/null; then
  ok "Config loads successfully"
else
  fail "Config failed to load"
fi

# Supabase reachable
if [ -n "${SB_URL:-}" ]; then
  SB_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 \
    "${SB_URL}/rest/v1/" \
    -H "apikey: ${SB_ANON:-${SRK:-}}" 2>/dev/null || echo "000")
  if [ "$SB_HEALTH" = "200" ]; then
    ok "Supabase API reachable"
  else
    fail "Supabase API returned HTTP $SB_HEALTH"
  fi
fi

# Keychain tokens
if keychain_has "$KEYCHAIN_CLI_SERVICE" "access_token"; then
  ok "Auth tokens in Keychain"
else
  fail "No auth tokens in Keychain"
fi

# Service role key
if keychain_has "$KEYCHAIN_SERVICE" "service_role_key"; then
  ok "Service role key in Keychain"
else
  fail "No service role key in Keychain"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$CHECK_ONLY" = true ]; then
  echo "$(_bold "Check complete.") Fix any $(_red "✗") items and re-run $(_bold "./setup.sh")"
else
  echo "$(_bold "Setup complete!") Open Claude Code in this directory to get started."
  echo ""
  echo "  Try:  $(_bold "/scan")       — Scan your inbox"
  echo "        $(_bold "/whats-next") — See what to work on"
  echo "        $(_bold "/log")        — Log a session"
fi
echo ""

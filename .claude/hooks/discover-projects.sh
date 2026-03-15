#!/bin/bash
# Outwork OS: Dynamic project discovery (DB-first with filesystem fallback)
# Queries Supabase get_project_manifest() RPC first; falls back to filesystem scan if unavailable
# Outputs a manifest for Claude Code session context injection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load config for OUTWORKOS_ROOT, OUTWORKOS_PARENT, SUPABASE_URL
source "$REPO_ROOT/scripts/load-config.sh" 2>/dev/null || true

SD="${OUTWORKOS_PARENT:-$(cd "$REPO_ROOT/.." && pwd)}"
_OUTWORKOS_ROOT="${OUTWORKOS_ROOT:-$REPO_ROOT}"
MANIFEST=""
COUNT=0
SOURCE="filesystem"

# Export key env vars so they're available in-session
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo "OUTWORKOS_ROOT=${_OUTWORKOS_ROOT}" >> "$CLAUDE_ENV_FILE"
  echo "OUTWORKOS_PARENT=${SD}" >> "$CLAUDE_ENV_FILE"
fi

# --- Attempt DB-first discovery via Supabase PostgREST ---
_SUPABASE_URL="${SUPABASE_URL:-}"
KEYCHAIN_SERVICE="outworkos"
_SUPABASE_KEY=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -a service_role_key -w 2>/dev/null) || true

if [ -n "$_SUPABASE_KEY" ] && [ -n "$_SUPABASE_URL" ]; then
    DB_RESP=$(curl -s --max-time 5 \
      -X POST "${_SUPABASE_URL}/rest/v1/rpc/get_project_manifest" \
      -H "apikey: ${_SUPABASE_KEY}" \
      -H "Authorization: Bearer ${_SUPABASE_KEY}" \
      -H "Content-Type: application/json" \
      -d '{}' 2>/dev/null)

    # Parse DB response — if valid JSON array with at least one entry, use it
    DB_MANIFEST=$(python3 -c "
import json, sys, os
try:
    projects = json.loads('''$DB_RESP''')
    if not isinstance(projects, list) or len(projects) == 0:
        sys.exit(1)
    sd = '$SD'
    count = 0
    for p in projects:
        name = p.get('name', '')
        slug = p.get('slug', '')
        db_id = p.get('id', '')
        todoist_id = p.get('todoist_project_id', '') or ''
        desc = p.get('description', '') or ''
        project_path = os.path.join(sd, name)

        has_claude_md = 'yes' if os.path.isfile(os.path.join(project_path, 'CLAUDE.md')) else 'no'
        has_log = 'yes' if os.path.isfile(os.path.join(project_path, 'log.md')) else 'no'
        has_env = 'yes' if os.path.isfile(os.path.join(project_path, '.env')) else 'no'
        has_mcp = 'yes' if os.path.isfile(os.path.join(project_path, '.mcp.json')) else 'no'

        print(f'''
## {name}
**DB ID:** {db_id}
**Slug:** {slug}
**Path:** {project_path}
**Todoist ID:** {todoist_id if todoist_id else 'none'}
**Has:** CLAUDE.md={has_claude_md} | log={has_log} | .env={has_env} | .mcp.json={has_mcp}
{desc[:200] if desc else ''}
---''')
        count += 1
    print(f'COUNT={count}', file=sys.stderr)
except Exception as e:
    sys.exit(1)
" 2>/tmp/_outwork_db_count)

    if [ $? -eq 0 ] && [ -n "$DB_MANIFEST" ]; then
      MANIFEST="$DB_MANIFEST"
      COUNT=$(grep -o 'COUNT=[0-9]*' /tmp/_outwork_db_count 2>/dev/null | cut -d= -f2)
      COUNT=${COUNT:-0}
      SOURCE="supabase"
    fi
    rm -f /tmp/_outwork_db_count
fi

# --- Fallback: filesystem scan (original behavior) ---
if [ "$SOURCE" = "filesystem" ]; then
  while IFS= read -r cmfile; do
    project_dir="$(dirname "$cmfile")"
    project_name="$(basename "$project_dir")"

    summary=$(sed '/^$/d' "$cmfile" | head -8)

    has_claude_md="no"
    has_log="no"
    has_env="no"
    has_mcp="no"
    [ -f "$project_dir/CLAUDE.md" ] && has_claude_md="yes"
    [ -f "$project_dir/log.md" ] && has_log="yes"
    [ -f "$project_dir/.env" ] && has_env="yes"
    [ -f "$project_dir/.mcp.json" ] && has_mcp="yes"

    MANIFEST+="
## ${project_name}
**Path:** ${project_dir}
**Has:** CLAUDE.md=${has_claude_md} | log=${has_log} | .env=${has_env} | .mcp.json=${has_mcp}
${summary}
---"

    COUNT=$((COUNT + 1))
  done < <(find "$SD" -maxdepth 2 -name "context-map.md" -type f 2>/dev/null | sort)
fi

echo "# Outwork OS — Project Manifest"
echo "**Discovered ${COUNT} projects** (source: ${SOURCE}, as of $(date '+%Y-%m-%d %H:%M'))"
echo ""
echo "You have full read access to all files in any of these projects."
echo "Use Read/Glob/Grep to drill into any project for details."
echo "${MANIFEST}"

# --- Google OAuth Token Health Check (full mode only) ---
_GW_MODE="${GOOGLE_WORKSPACE_MODE:-quick}"
if [ "$_GW_MODE" = "full" ]; then
  GET_SECRET="${_OUTWORKOS_ROOT}/scripts/get-secret.sh"
  if [ -x "$GET_SECRET" ]; then
    _G_CLIENT_ID=$("$GET_SECRET" google_client_id 2>/dev/null) || true
    _G_CLIENT_SECRET=$("$GET_SECRET" google_client_secret 2>/dev/null) || true
    _G_REFRESH_TOKEN=$("$GET_SECRET" google_refresh_token 2>/dev/null) || true

    if [ -n "$_G_CLIENT_ID" ] && [ -n "$_G_CLIENT_SECRET" ] && [ -n "$_G_REFRESH_TOKEN" ]; then
      _TOKEN_RESP=$(curl -s --max-time 5 -X POST https://oauth2.googleapis.com/token \
        -d "client_id=$_G_CLIENT_ID" \
        -d "client_secret=$_G_CLIENT_SECRET" \
        -d "refresh_token=$_G_REFRESH_TOKEN" \
        -d "grant_type=refresh_token" 2>/dev/null)

      if echo "$_TOKEN_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'access_token' in d" 2>/dev/null; then
        echo "Google OAuth: OK"
      else
        echo "Google OAuth token may be expired or invalid. Run: scripts/google-auth.sh"
      fi
    fi
  fi
fi

exit 0

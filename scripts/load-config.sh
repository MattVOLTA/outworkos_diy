#!/usr/bin/env bash
# Load outworkos.config.yaml and export values as environment variables.
# Source this file: source scripts/load-config.sh
#
# Requires: python3 + pyyaml (or falls back to inline python yaml parser)
#
# Exports:
#   OUTWORKOS_USER_EMAIL, OUTWORKOS_USER_NAME, OUTWORKOS_USER_TIMEZONE,
#   OUTWORKOS_USER_DOMAIN, OUTWORKOS_SCHEDULING_LINK, OUTWORKOS_ACCOUNTING_EMAIL,
#   SUPABASE_PROJECT_ID, SUPABASE_URL, SUPABASE_ANON_KEY,
#   OUTWORKOS_ROOT, OUTWORKOS_PARENT,
#   GOOGLE_OAUTH_CLIENT_ID, GOOGLE_OAUTH_CLIENT_SECRET, GOOGLE_OAUTH_REDIRECT_PORT,
#   OUTWORKOS_INTEGRATION_* (enabled flags for each integration)

set -euo pipefail

# Find config file — check repo root relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${OUTWORKOS_CONFIG_FILE:-$REPO_ROOT/outworkos.config.yaml}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Config file not found at $CONFIG_FILE" >&2
  echo "Copy outworkos.config.example.yaml to outworkos.config.yaml and fill in your values." >&2
  return 1 2>/dev/null || exit 1
fi

# Parse YAML with Python (available on macOS by default)
# NOTE: heredoc is written to a temp file first, then executed inside $(),
# because bash 3.2 (macOS default) has a bug where the $() parser tries to
# balance quotes inside heredoc content even when the delimiter is quoted.
_OUTWORKOS_PYPARSER=$(mktemp)
cat > "$_OUTWORKOS_PYPARSER" << 'PYEOF'
import sys, json, re

config_path = sys.argv[1]

# Minimal YAML parser — handles the flat/nested structure of outworkos.config.yaml
# without requiring pyyaml to be installed
def parse_yaml(path):
    """Parse simple YAML (scalars, nested objects) without external dependencies."""
    result = {}
    stack = [result]
    indent_stack = [-1]

    with open(path) as f:
        for line in f:
            stripped = line.rstrip()
            if not stripped or stripped.startswith('#'):
                continue

            indent = len(line) - len(line.lstrip())
            content = stripped.lstrip()

            # Pop stack for dedented lines
            while indent <= indent_stack[-1] and len(indent_stack) > 1:
                indent_stack.pop()
                stack.pop()

            if ':' in content:
                key, _, value = content.partition(':')
                key = key.strip()
                value = value.strip()

                # Remove inline comments
                if value and '#' in value:
                    # Don't strip # inside quotes
                    if not (value.startswith('"') or value.startswith("'")):
                        value = value.split('#')[0].strip()

                # Remove quotes
                if value and value[0] in ('"', "'") and value[-1] == value[0]:
                    value = value[1:-1]

                if value == '' or value is None:
                    # Nested object
                    new_dict = {}
                    stack[-1][key] = new_dict
                    stack.append(new_dict)
                    indent_stack.append(indent)
                elif value.lower() == 'true':
                    stack[-1][key] = True
                elif value.lower() == 'false':
                    stack[-1][key] = False
                else:
                    stack[-1][key] = value

    return result

config = parse_yaml(config_path)

def emit(env_var, value):
    if value is not None and value != '':
        # Validate env var name to prevent injection
        if not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', env_var):
            return
        # Escape single quotes in value
        safe = str(value).replace("'", "'\"'\"'")
        print(f"export {env_var}='{safe}'")

# User
user = config.get('user', {})
emit('OUTWORKOS_USER_EMAIL', user.get('email'))
emit('OUTWORKOS_USER_NAME', user.get('name'))
emit('OUTWORKOS_USER_TIMEZONE', user.get('timezone'))
emit('OUTWORKOS_USER_DOMAIN', user.get('domain'))

# Supabase
sb = config.get('supabase', {})
emit('SUPABASE_PROJECT_ID', sb.get('project_id'))
emit('SUPABASE_URL', sb.get('url'))
emit('SUPABASE_ANON_KEY', sb.get('anon_key'))

# Storage
storage = config.get('storage', {})
emit('OUTWORKOS_HOME', storage.get('home') or storage.get('root'))
emit('OUTWORKOS_PARENT', storage.get('parent'))

# Google Workspace
integrations = config.get('integrations', {})
gw = integrations.get('google_workspace', {})
emit('GOOGLE_WORKSPACE_MODE', gw.get('mode', 'quick'))
emit('GOOGLE_OAUTH_CLIENT_ID', gw.get('client_id'))
emit('GOOGLE_OAUTH_CLIENT_SECRET', gw.get('client_secret'))
emit('GOOGLE_OAUTH_REDIRECT_PORT', gw.get('redirect_port'))

# Optional settings
emit('OUTWORKOS_SCHEDULING_LINK', config.get('scheduling_link'))
emit('OUTWORKOS_ACCOUNTING_EMAIL', config.get('accounting_email'))

# Integration enabled flags
for name, settings in integrations.items():
    if isinstance(settings, dict):
        enabled = settings.get('enabled', False)
        env_name = f'OUTWORKOS_INTEGRATION_{name.upper()}'
        emit(env_name, str(enabled).lower())
        # Emit extra settings for specific integrations
        if name == 'fal_ai' and settings.get('download_path'):
            emit('FAL_DOWNLOAD_PATH', settings['download_path'])
PYEOF
eval "$(python3 "$_OUTWORKOS_PYPARSER" "$CONFIG_FILE")" 2>/dev/null
rm -f "$_OUTWORKOS_PYPARSER"

# OUTWORKOS_ROOT always points to the repo (where scripts/, skills/, etc. live)
export OUTWORKOS_ROOT="$REPO_ROOT"
# OUTWORKOS_HOME is the data directory (defaults to repo root if not configured)
export OUTWORKOS_HOME="${OUTWORKOS_HOME:-$REPO_ROOT}"

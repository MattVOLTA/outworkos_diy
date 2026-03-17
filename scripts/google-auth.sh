#!/bin/bash
# Google OAuth2 - Check token validity and re-authenticate if needed
# Uses configurable port for local OAuth callback
#
# Usage:
#   ./scripts/google-auth.sh           # Test token, re-auth if invalid
#   ./scripts/google-auth.sh --force   # Force re-authentication
#   ./scripts/google-auth.sh --check   # Test only, no re-auth

set -e

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
source "$SCRIPT_DIR/load-config.sh" 2>/dev/null || true

PORT="${GOOGLE_OAUTH_REDIRECT_PORT:-5555}"
REDIRECT_URI="http://localhost:${PORT}/oauth/callback"
SCOPES="https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/gmail.settings.basic https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/contacts https://www.googleapis.com/auth/drive"

GET_SECRET="$SCRIPT_DIR/get-secret.sh"
SET_SECRET="$SCRIPT_DIR/set-secret.sh"

# --- Load credentials (env vars take precedence, then Vault) ---
if [ -z "$GOOGLE_CLIENT_ID" ]; then
  GOOGLE_CLIENT_ID=$("$GET_SECRET" google_client_id 2>/dev/null) || {
    echo "Error: google_client_id not found in Vault. Run: scripts/set-secret.sh google_client_id <value>"
    exit 1
  }
fi
if [ -z "$GOOGLE_CLIENT_SECRET" ]; then
  GOOGLE_CLIENT_SECRET=$("$GET_SECRET" google_client_secret 2>/dev/null) || {
    echo "Error: google_client_secret not found in Vault. Run: scripts/set-secret.sh google_client_secret <value>"
    exit 1
  }
fi
GOOGLE_REFRESH_TOKEN=$("$GET_SECRET" google_refresh_token 2>/dev/null) || true

# --- Parse flags ---
FORCE=false
CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --check) CHECK_ONLY=true ;;
  esac
done

# --- Validate credentials ---
if [ -z "$GOOGLE_CLIENT_ID" ] || [ -z "$GOOGLE_CLIENT_SECRET" ]; then
  echo "Error: google_client_id and google_client_secret not found in Vault"
  echo ""
  echo "Store them with: scripts/set-secret.sh google_client_id <value>"
  echo "Get values from: https://console.cloud.google.com/apis/credentials"
  exit 1
fi

# --- Test current refresh token ---
test_refresh_token() {
  if [ -z "$GOOGLE_REFRESH_TOKEN" ]; then
    echo "No google_refresh_token found in Vault"
    return 1
  fi

  echo "Testing refresh token..."
  RESPONSE=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
    -d "client_id=$GOOGLE_CLIENT_ID" \
    -d "client_secret=$GOOGLE_CLIENT_SECRET" \
    -d "refresh_token=$GOOGLE_REFRESH_TOKEN" \
    -d "grant_type=refresh_token")

  ACCESS_TOKEN=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

  if [ -n "$ACCESS_TOKEN" ]; then
    GMAIL_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      "https://www.googleapis.com/gmail/v1/users/me/profile")

    if [ "$GMAIL_CHECK" = "200" ]; then
      echo "Refresh token is valid. Gmail API responding."
      return 0
    else
      echo "Refresh token exchanged but Gmail API returned HTTP $GMAIL_CHECK"
      return 1
    fi
  else
    ERROR=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error_description','Unknown error'))" 2>/dev/null)
    echo "Refresh token invalid: $ERROR"
    return 1
  fi
}

# --- Store new refresh token in Vault ---
update_env_token() {
  local NEW_TOKEN="$1"
  local TODAY=$(date +%Y-%m-%d)

  if "$SET_SECRET" google_refresh_token "$NEW_TOKEN" "Google refresh token generated ${TODAY} with Gmail + Gmail Settings + Calendar + Contacts + Drive scopes" 2>/dev/null; then
    echo "Stored new refresh token in Vault (generated $TODAY)"
  else
    echo ""
    echo "Warning: Could not store refresh token in Vault."
    echo "Vault functions may be missing — run migration 003_vault_functions.sql"
    echo ""
    echo "Your refresh token (save it manually):"
    echo "  $NEW_TOKEN"
    echo ""
    echo "Store it with: scripts/set-secret.sh google_refresh_token \"$NEW_TOKEN\""
    exit 1
  fi
}

# --- Re-authentication flow ---
run_reauth() {
  echo ""
  echo "=== Google OAuth Re-Authentication ==="
  echo ""
  echo "Prerequisites:"
  echo "  - http://localhost:${PORT}/oauth/callback must be registered as an"
  echo "    authorized redirect URI in Google Cloud Console:"
  echo "    https://console.cloud.google.com/apis/credentials"
  echo ""

  if lsof -i :$PORT -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Error: Port $PORT is already in use."
    echo "Kill the process using it or wait for it to finish."
    exit 1
  fi

  ENCODED_SCOPES=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SCOPES'))")
  AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth?client_id=${GOOGLE_CLIENT_ID}&redirect_uri=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$REDIRECT_URI'))")&response_type=code&scope=${ENCODED_SCOPES}&access_type=offline&prompt=consent"

  AUTH_CODE_FILE=$(mktemp)
  trap "rm -f '$AUTH_CODE_FILE'" EXIT

  CALLBACK_SCRIPT=$(mktemp)
  cat > "$CALLBACK_SCRIPT" << PYEOF
import http.server
import urllib.parse
import sys
import threading

AUTH_CODE_FILE = "$AUTH_CODE_FILE"
PORT = $PORT

class CallbackHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if not parsed.path == "/oauth/callback":
            self.send_response(404)
            self.end_headers()
            return

        params = urllib.parse.parse_qs(parsed.query)

        if "code" in params:
            code = params["code"][0]
            with open(AUTH_CODE_FILE, "w") as f:
                f.write(code)
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(b"""<html>
<body style="font-family:system-ui;text-align:center;padding:60px;background:#f8f9fa">
  <div style="max-width:400px;margin:0 auto;padding:40px;background:white;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.1)">
    <h1 style="color:#16a34a;margin-bottom:16px">Authorization Successful</h1>
    <p style="color:#6b7280">You can close this tab and return to your terminal.</p>
  </div>
</body></html>""")
            threading.Thread(target=lambda: self.server.shutdown()).start()
        elif "error" in params:
            error = params.get("error", ["unknown"])[0]
            desc = params.get("error_description", [""])[0]
            with open(AUTH_CODE_FILE, "w") as f:
                f.write("")
            self.send_response(400)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(f"""<html>
<body style="font-family:system-ui;text-align:center;padding:60px">
  <h1 style="color:#dc2626">Authorization Failed</h1>
  <p>{error}: {desc}</p>
</body></html>""".encode())
            threading.Thread(target=lambda: self.server.shutdown()).start()

    def log_message(self, format, *args):
        pass

server = http.server.HTTPServer(("localhost", PORT), CallbackHandler)
print(f"Listening on port {PORT}...", flush=True)
server.serve_forever()
PYEOF

  python3 "$CALLBACK_SCRIPT" &
  SERVER_PID=$!
  sleep 1

  if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "Error: Failed to start callback server on port $PORT"
    rm -f "$CALLBACK_SCRIPT"
    exit 1
  fi

  echo "Opening browser for authorization..."
  echo ""
  echo "If the browser doesn't open, visit this URL:"
  echo ""
  echo "$AUTH_URL"
  echo ""
  open "$AUTH_URL" 2>/dev/null || true

  echo "Waiting for authorization callback..."
  wait $SERVER_PID
  rm -f "$CALLBACK_SCRIPT"

  AUTH_CODE=$(cat "$AUTH_CODE_FILE")

  if [ -z "$AUTH_CODE" ]; then
    echo ""
    echo "Error: No authorization code received."
    echo "The authorization may have been denied or timed out."
    exit 1
  fi

  echo ""
  echo "Authorization code received. Exchanging for tokens..."

  TOKEN_RESPONSE=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
    -d "client_id=$GOOGLE_CLIENT_ID" \
    -d "client_secret=$GOOGLE_CLIENT_SECRET" \
    -d "code=$AUTH_CODE" \
    -d "grant_type=authorization_code" \
    -d "redirect_uri=$REDIRECT_URI")

  NEW_REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('refresh_token',''))" 2>/dev/null)
  NEW_ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

  if [ -z "$NEW_REFRESH_TOKEN" ]; then
    echo ""
    echo "Error: No refresh token in response."
    echo "Full response:"
    echo "$TOKEN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TOKEN_RESPONSE"
    echo ""
    echo "Common causes:"
    echo "  1. The authorization code was already used (they're single-use)"
    echo "  2. The authorization code expired (valid ~10 minutes)"
    echo "  3. The redirect URI doesn't match what's registered in Cloud Console"
    exit 1
  fi

  VERIFY=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $NEW_ACCESS_TOKEN" \
    "https://www.googleapis.com/gmail/v1/users/me/profile")

  if [ "$VERIFY" != "200" ]; then
    echo "Warning: New token obtained but Gmail API returned HTTP $VERIFY"
    echo "The token may have insufficient scopes."
  fi

  update_env_token "$NEW_REFRESH_TOKEN"

  echo ""
  echo "=== Re-Authentication Complete ==="
  echo ""
  echo "New refresh token saved to Vault"
  echo "All Google API connections should now work."
}

# --- Main flow ---
echo "=== Google OAuth Token Check ==="
echo ""

if [ "$FORCE" = true ]; then
  echo "Forcing re-authentication (--force flag)"
  run_reauth
elif test_refresh_token; then
  echo ""
  echo "All good! No action needed."
else
  if [ "$CHECK_ONLY" = true ]; then
    echo ""
    echo "Token is invalid. Run without --check to re-authenticate."
    exit 1
  fi
  run_reauth
fi

#!/bin/bash
# LinkedIn OAuth2 - Authenticate and store tokens
# Uses port 5556 for local OAuth callback (5555=Google, 8749=Xero)
#
# Usage:
#   ./scripts/linkedin-auth.sh           # Auth (or re-auth if token invalid)
#   ./scripts/linkedin-auth.sh --force   # Force re-authentication
#   ./scripts/linkedin-auth.sh --check   # Test token only, no re-auth

set -e

PORT=5556
REDIRECT_URI="http://localhost:${PORT}/callback"
SCOPES="openid profile w_member_social"

# --- Resolve script directory for get-secret.sh / set-secret.sh ---
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
GET_SECRET="${OUTWORKOS_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}/scripts/get-secret.sh"
SET_SECRET="${OUTWORKOS_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}/scripts/set-secret.sh"

# --- Load credentials from Vault ---
LINKEDIN_CLIENT_ID=$("$GET_SECRET" linkedin_client_id) || {
  echo "Error: linkedin_client_id not found in Vault. Run: outwork vault set linkedin_client_id <value>"
  exit 1
}
LINKEDIN_CLIENT_SECRET=$("$GET_SECRET" linkedin_client_secret) || {
  echo "Error: linkedin_client_secret not found in Vault. Run: outwork vault set linkedin_client_secret <value>"
  exit 1
}
LINKEDIN_ACCESS_TOKEN=$("$GET_SECRET" linkedin_access_token 2>/dev/null) || true
LINKEDIN_REFRESH_TOKEN=$("$GET_SECRET" linkedin_refresh_token 2>/dev/null) || true
LINKEDIN_PERSON_URN=$("$GET_SECRET" linkedin_person_urn 2>/dev/null) || true

echo "Credentials loaded from Vault"

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
if [ -z "$LINKEDIN_CLIENT_ID" ] || [ -z "$LINKEDIN_CLIENT_SECRET" ]; then
  echo "Error: linkedin_client_id and linkedin_client_secret not found in Vault"
  echo ""
  echo "Store them with: outwork vault set linkedin_client_id <value>"
  echo "Get values from: https://developer.linkedin.com/ -> Your App -> Auth tab"
  exit 1
fi

# --- Test current access token ---
test_access_token() {
  if [ -z "$LINKEDIN_ACCESS_TOKEN" ]; then
    echo "No linkedin_access_token found in Vault"
    return 1
  fi

  echo "Testing access token..."
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $LINKEDIN_ACCESS_TOKEN" \
    "https://api.linkedin.com/v2/userinfo")

  if [ "$HTTP_CODE" = "200" ]; then
    echo "Access token is valid."
    return 0
  else
    echo "Access token invalid (HTTP $HTTP_CODE). Attempting refresh..."
    return 1
  fi
}

# --- Try refreshing the token ---
try_refresh() {
  if [ -z "$LINKEDIN_REFRESH_TOKEN" ]; then
    echo "No refresh token available."
    return 1
  fi

  echo "Refreshing token..."
  RESPONSE=$(curl -s -X POST "https://www.linkedin.com/oauth/v2/accessToken" \
    --data-urlencode "grant_type=refresh_token" \
    --data-urlencode "refresh_token=$LINKEDIN_REFRESH_TOKEN" \
    --data-urlencode "client_id=$LINKEDIN_CLIENT_ID" \
    --data-urlencode "client_secret=$LINKEDIN_CLIENT_SECRET")

  NEW_ACCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
  NEW_REFRESH=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('refresh_token',''))" 2>/dev/null)

  if [ -n "$NEW_ACCESS" ] && [ "$NEW_ACCESS" != "" ]; then
    update_env_token "LINKEDIN_ACCESS_TOKEN" "$NEW_ACCESS"
    if [ -n "$NEW_REFRESH" ] && [ "$NEW_REFRESH" != "" ]; then
      update_env_token "LINKEDIN_REFRESH_TOKEN" "$NEW_REFRESH"
    fi
    echo "Token refreshed successfully."
    LINKEDIN_ACCESS_TOKEN="$NEW_ACCESS"
    return 0
  else
    ERROR=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error_description','Unknown error'))" 2>/dev/null)
    echo "Refresh failed: $ERROR"
    return 1
  fi
}

# --- Store a token in Vault ---
update_env_token() {
  local KEY="$1"
  local VALUE="$2"
  local TODAY=$(date +%Y-%m-%d)

  # Convert KEY to lowercase Vault label (e.g., LINKEDIN_ACCESS_TOKEN -> linkedin_access_token)
  local LABEL=$(echo "$KEY" | tr '[:upper:]' '[:lower:]')
  "$SET_SECRET" "$LABEL" "$VALUE" "LinkedIn token updated ${TODAY}"
}

# --- OAuth authorization flow ---
run_auth() {
  echo ""
  echo "=== LinkedIn OAuth Authorization ==="
  echo ""
  echo "Prerequisites:"
  echo "  - http://localhost:${PORT}/callback must be set as a redirect URL"
  echo "    in your LinkedIn app: https://developer.linkedin.com/"
  echo ""

  # Check if port is available
  if lsof -i :$PORT -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Error: Port $PORT is already in use."
    echo "Kill the process using it: lsof -i :$PORT"
    exit 1
  fi

  # Build auth URL
  ENCODED_SCOPES=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SCOPES'))")
  ENCODED_REDIRECT=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$REDIRECT_URI'))")
  AUTH_URL="https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=${LINKEDIN_CLIENT_ID}&redirect_uri=${ENCODED_REDIRECT}&scope=${ENCODED_SCOPES}"

  # Create temp file for auth code
  AUTH_CODE_FILE=$(mktemp)
  trap "rm -f '$AUTH_CODE_FILE'" EXIT

  # Callback server
  CALLBACK_SCRIPT=$(mktemp)
  cat > "$CALLBACK_SCRIPT" << PYEOF
import http.server
import urllib.parse
import threading

AUTH_CODE_FILE = "$AUTH_CODE_FILE"
PORT = $PORT

class CallbackHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path != "/callback":
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
    <h1 style="color:#0077B5;margin-bottom:16px">LinkedIn Connected</h1>
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

  # Start server
  python3 "$CALLBACK_SCRIPT" &
  SERVER_PID=$!
  sleep 1

  if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "Error: Failed to start callback server on port $PORT"
    rm -f "$CALLBACK_SCRIPT"
    exit 1
  fi

  # Open browser
  echo "Opening browser for LinkedIn authorization..."
  echo ""
  echo "If the browser doesn't open, visit:"
  echo ""
  echo "$AUTH_URL"
  echo ""
  open "$AUTH_URL" 2>/dev/null || true

  echo "Waiting for authorization callback..."
  wait $SERVER_PID
  rm -f "$CALLBACK_SCRIPT"

  # Read auth code
  AUTH_CODE=$(cat "$AUTH_CODE_FILE")

  if [ -z "$AUTH_CODE" ]; then
    echo ""
    echo "Error: No authorization code received."
    exit 1
  fi

  echo ""
  echo "Authorization code received. Exchanging for tokens..."

  # Exchange code for tokens (use --data-urlencode for secret with special chars)
  TOKEN_RESPONSE=$(curl -s -X POST "https://www.linkedin.com/oauth/v2/accessToken" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=authorization_code" \
    --data-urlencode "code=$AUTH_CODE" \
    --data-urlencode "client_id=$LINKEDIN_CLIENT_ID" \
    --data-urlencode "client_secret=$LINKEDIN_CLIENT_SECRET" \
    --data-urlencode "redirect_uri=$REDIRECT_URI")

  NEW_ACCESS=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
  NEW_REFRESH=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('refresh_token',''))" 2>/dev/null)

  if [ -z "$NEW_ACCESS" ]; then
    echo ""
    echo "Error: No access token in response."
    echo "Response:"
    echo "$TOKEN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TOKEN_RESPONSE"
    exit 1
  fi

  # Save tokens
  update_env_token "LINKEDIN_ACCESS_TOKEN" "$NEW_ACCESS"
  if [ -n "$NEW_REFRESH" ]; then
    update_env_token "LINKEDIN_REFRESH_TOKEN" "$NEW_REFRESH"
  fi

  # Fetch person URN
  echo "Fetching LinkedIn profile..."
  USERINFO=$(curl -s -H "Authorization: Bearer $NEW_ACCESS" \
    "https://api.linkedin.com/v2/userinfo")

  PERSON_SUB=$(echo "$USERINFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sub',''))" 2>/dev/null)
  PERSON_NAME=$(echo "$USERINFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('name',''))" 2>/dev/null)

  if [ -n "$PERSON_SUB" ]; then
    update_env_token "LINKEDIN_PERSON_URN" "urn:li:person:$PERSON_SUB"
    echo "Profile: $PERSON_NAME (urn:li:person:$PERSON_SUB)"
  else
    echo "Warning: Could not fetch Person URN. You may need to set LINKEDIN_PERSON_URN manually."
  fi

  echo ""
  echo "=== LinkedIn Authorization Complete ==="
  echo ""
  echo "Tokens saved to Vault"
  echo "Access token expires in ~60 days."
  echo "Refresh token expires in ~1 year."
}

# --- Main flow ---
echo "=== LinkedIn OAuth Token Check ==="
echo ""

if [ "$FORCE" = true ]; then
  echo "Forcing re-authentication (--force flag)"
  run_auth
elif test_access_token; then
  echo ""
  echo "All good! No action needed."
elif try_refresh; then
  echo ""
  echo "Token refreshed. All good!"
else
  if [ "$CHECK_ONLY" = true ]; then
    echo ""
    echo "Token is invalid. Run without --check to re-authenticate."
    exit 1
  fi
  run_auth
fi

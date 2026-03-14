# API Test Patterns

Curl patterns for validating each testable secret. All tests are read-only, lightweight, and return only HTTP status codes.

**Pattern:** Each test retrieves the secret, makes a single API call, and checks the HTTP status code. A `200` response means the token is valid.

---

## Runtime Context

Before running the Supabase Service Role Key test, resolve the Supabase project reference dynamically:

```bash
SUPABASE_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" supabase_access_token)
PROJECT_REF=$(curl -s -H "Authorization: Bearer $SUPABASE_TOKEN" \
  https://api.supabase.com/v1/projects | python3 -c "
import json, sys
projects = json.load(sys.stdin)
if projects:
    print(projects[0]['id'])
")
```

Use `PROJECT_REF` in any URL that requires the Supabase project reference.

---

## Simple API Key Tests

### Fireflies
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" fireflies_token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ user { name } }"}' \
  https://api.fireflies.ai/graphql)
# Pass: 200
```
**On failure:** Regenerate at https://app.fireflies.ai/integrations/custom/fireflies — copy the new API key and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh fireflies_token <new_key>
```

### Supabase Management API
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" supabase_access_token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  https://api.supabase.com/v1/projects)
# Pass: 200
```
**On failure:** Regenerate at https://supabase.com/dashboard/account/tokens — create a new access token and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh supabase_access_token <new_token>
```

### Supabase Service Role Key
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" supabase_service_role_key)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $TOKEN" \
  -H "Authorization: Bearer $TOKEN" \
  "https://${PROJECT_REF}.supabase.co/rest/v1/")
# Pass: 200
```
**On failure:** Find the service role key at `https://supabase.com/dashboard/project/${PROJECT_REF}/settings/api` and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh supabase_service_role_key <new_key>
```

### Netlify
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" netlify_auth_token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  https://api.netlify.com/api/v1/user)
# Pass: 200
```
**On failure:** Regenerate at https://app.netlify.com/user/applications#personal-access-tokens and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh netlify_auth_token <new_token>
```

### Todoist
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sync_token":"*","resource_types":["user"]}' \
  https://api.todoist.com/api/v1/sync)
# Pass: 200
```
**On failure:** Find your token at https://app.todoist.com/app/settings/integrations/developer and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh todoist_api_token <new_token>
```

### ElevenLabs
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" elevenlabs_api_key)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "xi-api-key: $TOKEN" \
  https://api.elevenlabs.io/v1/user)
# Pass: 200
```
**On failure:** Regenerate at https://elevenlabs.io/app/settings/api-keys and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh elevenlabs_api_key <new_key>
```

### Anthropic
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" anthropic_api_key)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "x-api-key: $TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  https://api.anthropic.com/v1/models)
# Pass: 200
```
**On failure:** Regenerate at https://console.anthropic.com/settings/keys and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh anthropic_api_key <new_key>
```

### ScrapingDog
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" scrapingdog_api_key)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://api.scrapingdog.com/account?api_key=$TOKEN")
# Pass: 200
```
**On failure:** Check your dashboard at https://www.scrapingdog.com/dashboard and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh scrapingdog_api_key <new_key>
```

### fal.ai
```bash
TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" fal_api_key)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Key $TOKEN" \
  https://queue.fal.run/fal-ai/flux/schnell)
# Pass: 200 or 422 (422 = auth OK, missing params)
```
**On failure:** Check your key at https://fal.ai/dashboard/keys and run:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh fal_api_key <new_key>
```

---

## Paired Token Tests

### Pushover (requires both app token + user key)
```bash
APP_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" pushover_api_token)
USER_KEY=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" pushover_user_key)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -d "token=$APP_TOKEN&user=$USER_KEY" \
  https://api.pushover.net/1/users/validate.json)
# Pass: 200
```
**On failure:** Check your app and user credentials at https://pushover.net/apps and https://pushover.net/dashboard. Update with:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh pushover_api_token <new_app_token>
$OUTWORKOS_ROOT/scripts/set-secret.sh pushover_user_key <new_user_key>
```

---

## OAuth Refresh Tests

### Google OAuth
```bash
CLIENT_ID=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" google_client_id)
CLIENT_SECRET=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" google_client_secret)
REFRESH_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" google_refresh_token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -d "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&refresh_token=$REFRESH_TOKEN&grant_type=refresh_token" \
  https://oauth2.googleapis.com/token)
# Pass: 200
```
**On failure (400/401 — refresh token expired or revoked):**
1. Run the Google OAuth flow: `$OUTWORKOS_ROOT/scripts/google-auth.sh`
2. This opens a browser for re-authorization and stores the new refresh token automatically
3. If the script itself fails, check that `http://localhost:5555/oauth/callback` is registered in Google Cloud Console

### LinkedIn API
```bash
ACCESS_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" linkedin_access_token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  https://api.linkedin.com/v2/userinfo)
# Pass: 200
```
**On failure (401 — access token expired):**
1. Go to https://www.linkedin.com/developers/apps
2. Select your app and navigate to the Auth tab
3. Generate a new access token with the required scopes (r_liteprofile, r_emailaddress, w_member_social)
4. Store the new tokens:
```bash
$OUTWORKOS_ROOT/scripts/set-secret.sh linkedin_access_token <new_access_token>
$OUTWORKOS_ROOT/scripts/set-secret.sh linkedin_refresh_token <new_refresh_token>
```

### LinkedIn Refresh Token
```bash
CLIENT_ID=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" linkedin_client_id)
CLIENT_SECRET=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" linkedin_client_secret)
REFRESH_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" linkedin_refresh_token)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -d "grant_type=refresh_token&refresh_token=$REFRESH_TOKEN&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET" \
  https://www.linkedin.com/oauth/v2/accessToken)
# Pass: 200
```
**On failure:** Same re-auth steps as LinkedIn API above.

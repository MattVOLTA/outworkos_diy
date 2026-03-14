# Secret Registry

All secrets stored in Supabase Vault for the Outwork OS platform. Each secret is retrieved at runtime via `$OUTWORKOS_ROOT/scripts/get-secret.sh <label>`.

## Full Registry

| # | Label | Purpose | Testable? | Service |
|---|-------|---------|-----------|---------|
| 1 | `google_client_id` | Google OAuth app ID | No (used in OAuth flows) | Google |
| 2 | `google_client_secret` | Google OAuth app secret | No (used in OAuth flows) | Google |
| 3 | `google_refresh_token` | Google OAuth refresh token | Yes (token refresh) | Google |
| 4 | `google_redirect_uri` | OAuth callback URL | No (configuration value) | Google |
| 5 | `google_token_uri` | Token endpoint URL | No (configuration value) | Google |
| 6 | `linkedin_client_id` | LinkedIn OAuth app ID | No (used in OAuth flows) | LinkedIn |
| 7 | `linkedin_client_secret` | LinkedIn OAuth app secret | No (used in OAuth flows) | LinkedIn |
| 8 | `linkedin_refresh_token` | LinkedIn OAuth refresh token | Yes (token refresh) | LinkedIn |
| 9 | `linkedin_access_token` | LinkedIn API access token | Yes (API call) | LinkedIn |
| 10 | `linkedin_person_urn` | LinkedIn user URN identifier | No (configuration value) | LinkedIn |
| 11 | `fireflies_token` | Fireflies API key | Yes (GraphQL ping) | Fireflies |
| 12 | `supabase_access_token` | Supabase Management API token | Yes (list projects) | Supabase |
| — | ~~`supabase_service_role_key`~~ | Lives in macOS Keychain, not Vault (bootstrap dependency) | Excluded | Supabase |
| 14 | `netlify_auth_token` | Netlify API token | Yes (user endpoint) | Netlify |
| 15 | `anthropic_api_key` | Anthropic/Claude API key | Yes (models list) | Anthropic |
| 16 | `todoist_api_token` | Todoist Sync API token | Yes (sync call) | Todoist |
| 17 | `elevenlabs_api_key` | ElevenLabs TTS API key | Yes (user endpoint) | ElevenLabs |
| 18 | `pushover_user_key` | Pushover notification user key | No (needs both keys together) | Pushover |
| 19 | `pushover_api_token` | Pushover notification app token | Yes (validate call with user key) | Pushover |
| 20 | `scrapingdog_api_key` | ScrapingDog web scraper API key | Yes (usage endpoint) | ScrapingDog |
| 21 | `fal_api_key` | fal.ai image/video generation API key | Yes (API call) | fal.ai |

## Service Groupings

### Google (5 secrets)
OAuth-based access to Gmail, Calendar, Drive, and other Google Workspace APIs. The refresh token is the critical testable credential — if it works, the entire Google integration is healthy. Re-auth via `$OUTWORKOS_ROOT/scripts/google-auth.sh`.

### LinkedIn (5 secrets)
OAuth-based access to LinkedIn posting and profile APIs. Both the access token (short-lived) and refresh token (longer-lived) should be tested. Re-auth requires visiting the LinkedIn Developer Portal.

### Fireflies (1 secret)
API key for meeting transcript retrieval. Tested via a simple GraphQL query.

### Supabase (1 secret in Vault + 1 in Keychain)
- `supabase_access_token`: Management API — used for project-level operations. Stored in Vault.
- `supabase_service_role_key`: Service role — used for Vault access, RPC calls, and bypassing RLS. **Stored in macOS Keychain** (not Vault) because it's the bootstrap credential needed to access Vault itself. Excluded from vault-health checks.

### Netlify (1 secret)
Personal access token for site deploys (audio briefs, project sites).

### Anthropic (1 secret)
API key for direct Claude API access outside of Claude Code sessions.

### Todoist (1 secret)
Sync API token for task management across all projects.

### ElevenLabs (1 secret)
API key for text-to-speech audio brief generation.

### Pushover (2 secrets)
Notification delivery. The validate endpoint requires both the app token and user key together.

### ScrapingDog (1 secret)
Web scraping API for LinkedIn profile data and other web content.

### fal.ai (1 secret)
API key for AI image and video generation (FLUX, Ideogram, Recraft, Imagen, etc.). Used by the `/generate-image` and `/generate-video` skills.

## Maintenance

When adding a new secret:
1. Store it via `$OUTWORKOS_ROOT/scripts/set-secret.sh <label> <value> [description]`
2. Add a row to the registry table above
3. If testable, add a curl pattern to `test-patterns.md`
4. Run `/vault-health` to verify

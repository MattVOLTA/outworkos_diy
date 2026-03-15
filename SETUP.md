# Outwork OS Setup Guide

## Prerequisites

- **macOS** (Keychain is used for token storage)
- **Claude Code** CLI installed
- **Python 3** (ships with macOS)
- **Supabase** account (free tier works)
- **Google Cloud** account (for Gmail, Calendar, Contacts, Drive APIs)
- **Todoist** account

## Step 1: Clone and Configure

```bash
git clone https://github.com/yourorg/outworkos_diy.git
cd outworkos_diy
cp outworkos.config.example.yaml outworkos.config.yaml
```

Edit `outworkos.config.yaml` with your details:

```yaml
user:
  email: "you@company.com"
  name: "Your Name"
  timezone: "America/New_York"
  domain: "company.com"

supabase:
  project_id: "your-project-id"
  url: "https://your-project-id.supabase.co"
  anon_key: "your-anon-key"

storage:
  root: "/path/to/outworkos_diy"
  parent: "/path/to/your/projects"
```

## Step 2: Set Up Supabase

### Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your **Project ID**, **URL**, and **anon key** from Settings > API
3. Add these to your `outworkos.config.yaml`

### Enable Vault

1. In Supabase Dashboard, go to **Database > Extensions**
2. Enable the `supabase_vault` extension

### Run Migrations

Run the migrations in order via the Supabase SQL Editor (Dashboard > SQL Editor):

1. Paste and run `migrations/001_core_schema.sql`
2. Paste and run `migrations/002_rls_policies.sql`
3. Paste and run `migrations/003_vault_functions.sql`

### Create Your User

1. In Supabase Dashboard, go to **Authentication > Users**
2. Click "Add User" and create your account with email/password
3. Note your **User ID** from the user details

### Store Service Role Key

The service role key allows scripts to access Vault. Find it in Settings > API > `service_role` key.

```bash
security add-generic-password -s outworkos -a service_role_key -w "your-service-role-key" -U
```

## Step 3: Authenticate

```bash
./scripts/outworkos-auth-login.sh
```

Enter your Supabase email and password. Tokens are stored in macOS Keychain.

## Step 4: Create Your User Profile

Open Claude Code in the `outworkos_diy` directory and run:

```
Use the Supabase MCP to insert a row into user_profiles with my email, name, timezone, and domain from the config.
```

Or run this SQL in the Supabase SQL Editor (replace values):

```sql
INSERT INTO user_profiles (user_id, email, display_name, domain, timezone)
VALUES (
  'your-user-id',
  'you@company.com',
  'Your Name',
  'company.com',
  'America/New_York'
);
```

## Step 5: Set Up Google Workspace

### Choose Your Mode

Outwork OS supports two Google Workspace modes. Set `mode` in your config:

```yaml
integrations:
  google_workspace:
    enabled: true
    mode: "quick"    # or "full"
```

| | Quick Mode | Full Mode |
|---|---|---|
| **Setup** | None — uses Anthropic's built-in connectors | Google Cloud Console OAuth app required |
| **Gmail read** | Yes (search, read, threads) | Yes |
| **Gmail draft** | Yes (create drafts) | Yes (with signature auto-append) |
| **Gmail send** | No — draft only, send from Gmail | Yes (programmatic send) |
| **Gmail archive** | No — /scan reports noise but can't auto-archive | Yes (auto-archive noise and resolved emails) |
| **Calendar** | Full (list, create, update, delete, find times) | Full |
| **Contacts** | No | Yes (read + write-back enrichment) |
| **Drive** | No | Yes |

### Quick Mode (Recommended for Getting Started)

No setup needed. The built-in Anthropic Gmail and Calendar connectors are available automatically in Claude Code. **Skip to Step 6.**

You can upgrade to full mode at any time by completing the full mode steps below and changing `mode: "full"` in your config.

### Full Mode

#### Create OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (or use an existing one)
3. Enable these APIs:
   - Gmail API
   - Google Calendar API
   - People API (Contacts)
   - Google Drive API
4. Go to **APIs & Services > Credentials**
5. Create an **OAuth 2.0 Client ID** (type: Desktop app)
6. Add `http://localhost:5555/oauth/callback` as an authorized redirect URI
7. Note the **Client ID** and **Client Secret**

#### Store Google Credentials in Vault

```bash
./scripts/set-secret.sh google_client_id "your-client-id"
./scripts/set-secret.sh google_client_secret "your-client-secret"
```

#### Authorize Google

```bash
./scripts/google-auth.sh
```

This opens your browser for OAuth consent. The refresh token is stored in Vault automatically.

#### Add Google Workspace MCP

Add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "google-workspace": {
      "command": "npx",
      "args": ["-y", "@anthropic/google-workspace-mcp"],
      "env": {
        "GOOGLE_OAUTH_CLIENT_ID": "${GOOGLE_OAUTH_CLIENT_ID}",
        "GOOGLE_OAUTH_CLIENT_SECRET": "${GOOGLE_OAUTH_CLIENT_SECRET}"
      }
    }
  }
}
```

## Step 6: Set Up Todoist

1. Get your Todoist API token from [todoist.com/app/settings/integrations/developer](https://todoist.com/app/settings/integrations/developer)
2. Store it in Vault:

```bash
./scripts/set-secret.sh todoist_api_token "your-todoist-api-token"
```

## Step 7: Optional Integrations

Enable any of these in `outworkos.config.yaml` and store their API keys in Vault:

### GitHub

```bash
./scripts/set-secret.sh github_token "ghp_your-token"
```

Update `.mcp.json` to reference `${GITHUB_TOKEN}` environment variable.

### Fireflies

```bash
./scripts/set-secret.sh fireflies_api_key "your-api-key"
```

### Pushover (Push Notifications)

```bash
./scripts/set-secret.sh pushover_user_key "your-user-key"
./scripts/set-secret.sh pushover_app_token "your-app-token"
```

### Other Integrations

For each integration, store the API key in Vault using `set-secret.sh` and update the `.mcp.json` if an MCP server is needed.

## Step 8: Verify

Open Claude Code in the `outworkos_diy` directory. You should see the project manifest load at session start. Try:

- `/scan` — Scan your inbox
- `/whats-next` — See what to work on
- `/log` — Log a session

## Troubleshooting

### "Not authenticated" error
Run `./scripts/outworkos-auth-login.sh` to re-authenticate.

### "No service_role_key in Keychain" error
Store the Supabase service role key:
```bash
security add-generic-password -s outworkos -a service_role_key -w "your-key" -U
```

### Google OAuth token expired
Run `./scripts/google-auth.sh` to re-authorize.

### Skills can't find user profile
Ensure you created a row in `user_profiles` (Step 4).

# Outwork OS

A personal operating system for knowledge workers. Manages projects, email triage, task prioritization, meeting prep, and cross-project awareness — all powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## What It Does

Outwork OS turns Claude Code into a full productivity system by connecting your email, calendar, tasks, meetings, and projects through a database-first architecture. Instead of switching between apps, you use slash commands:

- **`/scan`** — Scans your Gmail and Slack, filters noise, routes signals to projects, creates tasks for anything that needs follow-up, and ranks your priorities
- **`/whats-next`** — Syncs Todoist, Gmail, Calendar, and Fireflies to recommend exactly what to work on next
- **`/email-composer`** — Drafts and sends emails with your natural writing style, proper threading, and signature handling
- **`/meeting-prep`** — Researches attendees, pulls email history and past meetings, and produces a briefing before your call
- **`/risk`** — Finds open tasks where you've dropped follow-through by cross-referencing sent mail, logs, and calendar
- **`/log`** — Records what you accomplished in a session to a persistent timeline

Every skill reads from and writes to a shared Supabase database, so context carries across sessions, machines, and projects.

## Architecture

```
You ──► Claude Code ──► Skills (30+ slash commands)
                            │
                            ├── Supabase (database, auth, secrets vault)
                            ├── Google Workspace (Gmail, Calendar, Contacts, Drive)
                            ├── Todoist (task management)
                            └── Optional: GitHub, Fireflies, Slack, Pushover, etc.
```

**Database-first:** All project data, signals, logs, memory, and config live in Supabase. Local files are generated artifacts. Secrets are stored in Supabase Vault — never in `.env` files or plaintext.

**Config-driven:** Your identity, preferences, and integrations are defined in a single `outworkos.config.yaml` file. No hardcoded emails, IDs, or paths.

**Session hooks:** A SessionStart hook authenticates, loads your projects from the database, and injects a manifest into Claude's context. A SessionEnd hook auto-commits and pushes changes.

## Prerequisites

- **macOS** (uses Keychain for token storage)
- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** CLI installed
- **Python 3** (ships with macOS)
- **[Supabase](https://supabase.com)** account (free tier works)
- **[Google Cloud](https://console.cloud.google.com)** account (for Gmail, Calendar, Contacts, Drive APIs)
- **[Todoist](https://todoist.com)** account

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/MattVOLTA/outworkos_diy.git
cd outworkos_diy
cp outworkos.config.example.yaml outworkos.config.yaml
```

Edit `outworkos.config.yaml`:

```yaml
user:
  email: "you@company.com"
  name: "Your Name"
  timezone: "America/New_York"    # IANA timezone
  domain: "company.com"           # Your org's email domain

supabase:
  project_id: "your-project-id"   # From Supabase dashboard
  url: "https://your-project-id.supabase.co"
  anon_key: "your-anon-key"       # Public key from Settings > API

storage:
  root: "/path/to/outworkos_diy"  # Absolute path to this repo
  parent: "/path/to/projects"     # Parent dir for all project folders
```

### 2. Set up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. Enable the **Vault** extension (Database > Extensions > `supabase_vault`)
3. Run the three migration files in order via the SQL Editor:
   - `migrations/001_core_schema.sql` — Tables
   - `migrations/002_rls_policies.sql` — Row-level security
   - `migrations/003_vault_functions.sql` — Vault wrapper functions + project manifest RPC
4. Create a user account (Authentication > Users > Add User)
5. Store the service role key in Keychain:

```bash
security add-generic-password -s outworkos -a service_role_key -w "your-service-role-key" -U
```

### 3. Authenticate

```bash
./scripts/outworkos-auth-login.sh
```

### 4. Create your user profile

Run this in the Supabase SQL Editor (replace the values):

```sql
INSERT INTO user_profiles (user_id, email, display_name, domain, timezone)
VALUES ('your-user-id', 'you@company.com', 'Your Name', 'company.com', 'America/New_York');
```

### 5. Set up Google Workspace

1. In [Google Cloud Console](https://console.cloud.google.com), create OAuth 2.0 credentials (Desktop app type)
2. Enable: Gmail API, Calendar API, People API, Drive API
3. Add `http://localhost:5555/oauth/callback` as an authorized redirect URI
4. Store credentials and authorize:

```bash
./scripts/set-secret.sh google_client_id "your-client-id"
./scripts/set-secret.sh google_client_secret "your-client-secret"
./scripts/google-auth.sh
```

### 6. Set up Todoist

```bash
./scripts/set-secret.sh todoist_api_token "your-api-token"
```

Get your token from [Todoist Integrations > Developer](https://todoist.com/app/settings/integrations/developer).

### 7. Verify

Open Claude Code in the `outworkos_diy` directory. The SessionStart hook should load your project manifest. Try:

```
/scan
/whats-next
/log
```

See [SETUP.md](SETUP.md) for detailed setup instructions, optional integrations, and troubleshooting.

## Skills

### Daily Workflow

| Command | What it does |
|---------|-------------|
| `/scan` | Cross-project inbox scan — filters noise, routes signals to projects, creates Todoist tasks for gaps, ranks priorities |
| `/whats-next` | Syncs Todoist, Gmail, Calendar, and Fireflies to recommend the next task to work on |
| `/email-composer` | Drafts and sends emails with natural writing style, proper threading, and signature handling |
| `/log` | Records session accomplishments to the database timeline |
| `/risk` | Finds open tasks where follow-through is missing by cross-referencing sent mail, logs, and calendar |
| `/risk-review` | Interactive walkthrough of top 5 risk items — reply, close, reschedule, or delegate each one |
| `/weekly-review` | Gain-based weekly reflection — narrative prose measuring progress against where you were, not where you wish you were |

### Meetings & Communication

| Command | What it does |
|---------|-------------|
| `/meeting-prep` | Researches attendees, email history, and past meetings to produce a pre-call briefing |
| `/process-meeting` | Converts a Fireflies recording into a structured summary with Todoist action items |
| `/process-pendant` | Reviews Limitless Pendant conversations, cross-references with Calendar and Fireflies |

### Project Management

| Command | What it does |
|---------|-------------|
| `/context-map` | Maps a project by interviewing you about data sources, people, and systems of record |
| `/setup-project` | Bootstraps a new project directory with config files, MCP servers, and template skills |
| `/receipts` | Scans Gmail for purchase emails, uploads to Google Drive, and forwards to accounting |

### Development

| Command | What it does |
|---------|-------------|
| `/start-work` | Begins working on a GitHub issue (creates branch, sets up environment) |
| `/ship-it` | Commits, pushes, and creates a PR |
| `/test-driven-development` | TDD workflow — write the test first, watch it fail, then write code to pass |
| `/define-requirements` | Jobs-to-be-Done discovery to define feature requirements before implementation |
| `/github-issue-creator` | Creates comprehensive GitHub issues that capture all research and implementation context |
| `/document` | Converts a conversation into a GitHub issue |

### Content & Publishing

| Command | What it does |
|---------|-------------|
| `/post-linkedin` | Drafts and publishes LinkedIn posts via the official API |
| `/substack-drafter` | Drafts Substack articles (markdown to Tiptap JSON) |
| `/scrape-linkedin` | Fetches and summarizes a LinkedIn profile |
| `/build-spotify-playlist` | Generates Spotify playlists by mood, genre, or similar artists |

### Infrastructure & Utilities

| Command | What it does |
|---------|-------------|
| `/vault-health` | Audits Supabase Vault — tests token validity, checks for expired credentials |
| `/notify-user` | Sends a Pushover push notification (useful when Claude is blocked and needs input) |
| `/local-automation` | Creates persistent macOS launchd jobs for recurring automations |
| `/xero-connect` | Sets up Xero accounting OAuth integration |
| `/cleanup-branches` | Cleans up merged git branches and orphaned worktrees |

### Plugin Skills

Grouped under `skills/plugins/`, these provide specialized capabilities:

- **Memory System** — `/memory`, `/recall`, `/rem-sleep`, `/memory-init` for persistent user memory
- **Product Tools** — SVPG-style product requirements and discovery frameworks
- **QA Tools** — Test orchestration, risk assessment, and coverage analysis
- **DevOps Tools** — Git workflow guardian, branching strategies, conventional commits
- **Frontend Tools** — Frontend design and mobile responsive analysis
- **Senior Dev** — Senior developer consultation and code review
- **Writing Tools** — Writing style reference and blog drafting

## Optional Integrations

Enable in `outworkos.config.yaml` and store API keys in Vault:

| Integration | What it enables | Setup |
|------------|-----------------|-------|
| **GitHub** | `/start-work`, `/ship-it`, `/github-issue-creator` | `set-secret.sh github_token "ghp_..."` |
| **Fireflies** | `/process-meeting`, meeting data in `/scan` | `set-secret.sh fireflies_api_key "..."` |
| **Slack** | Slack DMs as signal source in `/scan` | `set-secret.sh slack_token "..."` |
| **Pushover** | `/notify-user` push notifications | `set-secret.sh pushover_user_key "..."` |
| **Limitless Pendant** | `/process-pendant` ambient meeting capture | `set-secret.sh limitless_api_key "..."` |
| **fal.ai** | Image/video generation skills | `set-secret.sh fal_api_key "..."` |
| **Xero** | `/xero-connect` accounting integration | Run `/xero-connect` for guided setup |
| **LinkedIn** | `/post-linkedin`, `/scrape-linkedin` | `set-secret.sh linkedin_access_token "..."` |
| **Netlify** | Deployment management | `set-secret.sh netlify_auth_token "..."` |

## Database Schema

All tables have row-level security (RLS) scoped to the authenticated user.

| Table | Purpose |
|-------|---------|
| `projects` | Project registry with name, slug, description, Todoist ID, context map |
| `project_members` | Team membership (owner/member roles) |
| `signals` | Email, meeting, and Slack signals with classification and routing |
| `log_entries` | Session logs and event timeline per project |
| `skill_state` | Per-skill persistent state (caches, dedup tracking, timestamps) |
| `memories` | User memory/context persistence across sessions |
| `user_profiles` | Identity, email, timezone, domain, preferences |
| `scan_rules` | Noise filters, routing overrides, priority modifiers |
| `config` | Per-user settings |
| `user_secrets` | Maps user to Vault-encrypted secrets |

Vault wrapper functions provide secure secret storage:
- `store_user_secret(name, secret, description)` — Create or update
- `get_user_secret(name)` — Retrieve
- `delete_user_secret(name)` — Delete
- `list_user_secrets()` — List labels (not values)

## Project Structure

```
outworkos_diy/
├── outworkos.config.example.yaml  # Copy this → outworkos.config.yaml
├── CLAUDE.md                      # Claude Code project instructions
├── SETUP.md                       # Detailed installation guide
├── README.md                      # This file
│
├── migrations/                    # Supabase schema (run once)
│   ├── 001_core_schema.sql
│   ├── 002_rls_policies.sql
│   └── 003_vault_functions.sql
│
├── scripts/                       # Auth, secrets, and config
│   ├── load-config.sh             # YAML config → env vars
│   ├── outworkos-auth-login.sh    # Supabase authentication
│   ├── outworkos-auth-check.sh    # Token refresh
│   ├── get-secret.sh              # Read from Vault
│   ├── set-secret.sh              # Write to Vault
│   └── google-auth.sh             # Google OAuth flow
│
├── skills/                        # 30+ slash commands
│   ├── scan/                      # Cross-project inbox scan
│   ├── whats-next/                # Priority recommendation
│   ├── email-composer/            # Email drafting
│   ├── log/                       # Session logging
│   ├── ...
│   └── plugins/                   # Plugin-based skill groups
│
├── .claude/
│   ├── settings.json              # Hook configuration
│   └── hooks/
│       ├── discover-projects.sh   # SessionStart: load projects
│       └── backup.sh              # SessionEnd: git commit + push
│
├── .mcp.json                      # MCP server config (env var references)
└── todoist_api_reference.md       # Todoist Sync API patterns
```

## How It Works

### Session Lifecycle

1. **SessionStart** — `discover-projects.sh` runs: loads `outworkos.config.yaml`, authenticates with Supabase, fetches your active projects, checks Google OAuth health, and injects a project manifest into Claude's context
2. **During session** — You use slash commands. Each skill reads/writes to Supabase, queries Gmail/Calendar/Todoist as needed, and maintains state in the `skill_state` table
3. **SessionEnd** — `backup.sh` commits and pushes any file changes to git

### Cross-Project Awareness

Every session starts with a manifest of all your projects. Claude has read access to files across all project directories. You can ask cross-cutting questions like:

- "Which projects have overdue tasks?"
- "What happened across all projects this week?"
- "Find all emails from Sarah across any project"

### Signal Processing (`/scan`)

```
Gmail inbox ──┐
Slack DMs ────┤──► Noise filter ──► Route to project ──► Create Todoist task
Fireflies ────┘    (scan_rules)     (5-tier cascade)     (if gap detected)
```

Noise rules, routing overrides, and priority modifiers are stored in the `scan_rules` table and evolve based on your feedback.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Not authenticated" | `./scripts/outworkos-auth-login.sh` |
| "No service_role_key in Keychain" | `security add-generic-password -s outworkos -a service_role_key -w "your-key" -U` |
| Google OAuth expired | `./scripts/google-auth.sh` |
| Skills can't find user profile | Create a row in `user_profiles` (see Quick Start step 4) |
| SessionStart hook fails | Check `outworkos.config.yaml` exists and has valid Supabase credentials |

## License

Private. Contact the maintainer for access.

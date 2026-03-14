# Outwork OS

A personal operating system for knowledge workers. Manages projects, email triage, task prioritization, meeting prep, and cross-project awareness — all powered by Claude Code.

## Getting Started

See [SETUP.md](SETUP.md) for installation and first-run instructions.

## Architecture

### Database-First

Outwork OS uses **Supabase as the single source of truth** for all project data, signals, logs, memory, credentials, and configuration. Local files are generated artifacts, not primary storage.

### How It Works

1. **Config**: `outworkos.config.yaml` holds non-secret settings (email, timezone, Supabase connection)
2. **Auth**: CLI login via `scripts/outworkos-auth-login.sh` stores tokens in macOS Keychain
3. **SessionStart hook** (`discover-projects.sh`): Loads config, authenticates, fetches project manifest from Supabase, injects into Claude context
4. **Skills**: Read/write data via Supabase MCP (`execute_sql`). Never write project data to local files.
5. **SessionEnd hook** (`backup.sh`): Git commit + push for repo changes only
6. **Secrets**: API keys stored in Supabase Vault via `scripts/set-secret.sh` / `scripts/get-secret.sh`

### Data Layer

| Data | Storage | Access Pattern |
|------|---------|----------------|
| Projects, context maps | `projects` table | SessionStart generates manifest; skills query DB |
| Inbox/meeting signals | `signals` table | `/scan` routes inline |
| Session logs | `log_entries` table | `/log` writes |
| Skill state | `skill_state` table | Each skill reads/writes its own state |
| Memory | `memories` table | Memory skills read/write |
| User profile | `user_profiles` table | Email, timezone, preferences |
| Scan rules | `scan_rules` table | Noise filters, routing overrides |
| API keys & secrets | Supabase Vault | Via `get_user_secret()` / `store_user_secret()` |
| Auth tokens | macOS Keychain | SessionStart hook reads; refresh on expiry |
| Non-secret config | `outworkos.config.yaml` | Loaded by `scripts/load-config.sh` |

### Key Details

- **RLS**: Every table has row-level security scoped by `user_id` or `project_members`
- **Vault**: Secrets stored per-user via wrapper functions, never in `.env` or plaintext
- **Config**: `outworkos.config.yaml` is never committed (in `.gitignore`)

## Cross-Project Awareness

A **SessionStart hook** runs at the start of every session. It loads config, authenticates with Supabase, fetches all active projects, and injects a manifest into context.

### What You Can Do

You have full read access to all files across every discovered project:

- **Cross-project queries**: "Which projects use Supabase?" / "What's happening across my projects?"
- **Status overviews**: Read logs and context-maps across all projects
- **Find connections**: Identify shared contacts, overlapping timelines, or dependencies
- **Aggregate information**: Pull data from multiple projects into a single summary
- **Drill down**: Read any file in any project

### Conventions

- **Read-only by default.** Do not modify files in other project directories unless explicitly asked.
- **Use the manifest first.** Check the injected manifest before scanning the filesystem.
- **Drill down on demand.** The manifest has summaries; use `Read` to get full context when needed.
- **Respect project boundaries.** Each project has its own CLAUDE.md with its own rules.

## Preferences

- **Database-first**: All project data, signals, logs, memory, and config live in Supabase. Local files are generated artifacts.
- **Vault for secrets**: Never store API keys or tokens in `.env` files or plaintext. Use `scripts/get-secret.sh <label>` to retrieve secrets at runtime. Use `scripts/set-secret.sh <label> <value> [description]` to store new secrets.
- **Config-driven**: User identity, Supabase connection, and integration settings come from `outworkos.config.yaml`. Never hardcode emails, user IDs, project IDs, or file paths.
- **Use environment variables** `$OUTWORKOS_ROOT` and `$OUTWORKOS_PARENT` — never hardcode absolute paths.

## Core Integrations (Required)

- **Supabase** — Database, auth, Vault
- **Google Workspace** — Gmail, Calendar, Contacts, Drive
- **Todoist** — Task management

## Optional Integrations

Enable any of these in `outworkos.config.yaml`:

- GitHub, Fireflies, Slack, Pushover, Limitless Pendant, fal.ai, Xero, LinkedIn, Netlify, Context7

## File Structure

```
outworkos_diy/
├── CLAUDE.md                        ← This file
├── SETUP.md                         ← Installation guide
├── outworkos.config.example.yaml    ← Config template (copy and fill in)
├── outworkos.config.yaml            ← Your config (gitignored)
├── .mcp.json                        ← MCP server config (minimal, env-var based)
├── migrations/
│   ├── 001_core_schema.sql          ← Tables
│   ├── 002_rls_policies.sql         ← Row-level security
│   └── 003_vault_functions.sql      ← Vault wrapper functions
├── scripts/
│   ├── load-config.sh               ← Parse config YAML → env vars
│   ├── outworkos-auth-login.sh      ← Supabase auth (stores in Keychain)
│   ├── outworkos-auth-check.sh      ← Token refresh
│   ├── get-secret.sh                ← Read from Vault
│   ├── set-secret.sh                ← Write to Vault
│   └── google-auth.sh               ← Google OAuth flow
├── skills/                          ← All skills
│   ├── context-map/                 ← Template (copied to new projects)
│   ├── log/                         ← Template (copied to new projects)
│   ├── todoist/                     ← Template (copied to new projects)
│   ├── setup-project/               ← Project bootstrapper
│   ├── scan/                        ← Cross-project inbox scan
│   ├── whats-next/                  ← Priority recommendation
│   ├── email-composer/              ← Email drafting
│   └── ...
└── .claude/
    ├── settings.json                ← Hook configs
    └── hooks/
        ├── discover-projects.sh     ← DB-first project discovery
        └── backup.sh               ← Git auto-commit + push
```

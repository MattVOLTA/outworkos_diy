# Scan — API Patterns & Credentials

Quick reference for Gmail REST API, Todoist Sync API, Slack MCP, and credential handling.

**API-first principle:** Use REST APIs directly via Python (`urllib.request`) for Gmail and Todoist. Use MCP tools for Slack, Calendar, Fireflies, and Contacts. MCP tools are the fallback for Gmail if API calls fail (401 auth errors).

**IMPORTANT: Use pure Python (`urllib.request`) for all Todoist and Gmail REST API calls.** Never save API responses to bash variables — task content contains quotes, backslashes, control characters, and non-ASCII that bash mangles during variable expansion. Always fetch, parse, and process within a single Python script.

---

## Google Workspace Mode

The `GOOGLE_WORKSPACE_MODE` environment variable (set by `load-config.sh`) determines which Gmail tools are available. Default: `quick`.

| Capability | Quick Mode (built-in MCP) | Full Mode (REST API + self-hosted MCP) |
|------------|--------------------------|---------------------------------------|
| Search inbox | `gmail_search_messages` (built-in, up to 500 results) | REST `messages.list` with OAuth token |
| Read message | `gmail_read_message` (built-in) | REST `messages.get` with OAuth token |
| Read thread | `gmail_read_thread` (built-in) | REST via thread_id |
| Create draft | `gmail_create_draft` (built-in) | `draft_gmail_message` (self-hosted MCP) |
| Send email | **NOT AVAILABLE** | `send_gmail_message` (self-hosted MCP) |
| Archive (batchModify) | **NOT AVAILABLE** | REST `messages.batchModify` |
| Contacts | **NOT AVAILABLE** | `manage_contact` (self-hosted MCP) |
| Calendar | `gcal_list_events`, etc. (built-in, full CRUD) | Same tools via self-hosted MCP |

**Quick mode limitations for /scan:**
- Archive noise + filtered (Phase 1a step 5): **SKIP.** Report noise counts but leave messages in inbox. Set `"archive_skipped": true` in output.
- Archive resolved Gmail (Phase 5c): **SKIP.** Same.
- Reply detection (Phase 1a step 3): Works normally — `gmail_search_messages` with `from:{USER_EMAIL}` is read-only.

**Quick mode detection at runtime:**
```bash
source "$OUTWORKOS_ROOT/scripts/load-config.sh"
if [ "$GOOGLE_WORKSPACE_MODE" = "full" ]; then
  # Use REST API patterns below
else
  # Use ToolSearch to find built-in Gmail/Calendar MCP tools
fi
```

---

## Credentials — Phase 0c

### Gmail OAuth Token Refresh

**Note:** `$OUTWORKOS_ROOT` is exported via `$CLAUDE_ENV_FILE` by the session-start hook. It must be set in the environment.

```bash
CLIENT_ID=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" google_client_id)
CLIENT_SECRET=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" google_client_secret)
REFRESH_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" google_refresh_token)

ACCESS_TOKEN=$(curl -s -X POST "https://oauth2.googleapis.com/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&refresh_token=$REFRESH_TOKEN&grant_type=refresh_token" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['access_token'])")
```

**Base URL:** `https://gmail.googleapis.com/gmail/v1/users/me`
**Auth header:** `Authorization: Bearer $ACCESS_TOKEN`
**MCP Fallback:** If API returns 401, use `ToolSearch: "+google gmail"` to discover MCP tools.

**Quick mode:** The OAuth token refresh above is not needed. The built-in MCP connectors handle their own authentication. Skip directly to using `gmail_search_messages` (built-in) via `ToolSearch: "+gmail"`.

### Todoist Token

```bash
TODOIST_API_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" todoist_api_token)
```

**CRITICAL: REST v2 is DEAD.** `https://api.todoist.com/rest/v2/*` returns HTTP 410 Gone. NEVER use it. Use Sync API (`/api/v1/sync`) for writes and REST v1 (`/api/v1/tasks`) for reads.

### Contacts Cache

Cache file: `${CLAUDE_SKILL_DIR}/.contacts-cache.json`

Refresh if older than 24 hours or missing. Use Google Workspace MCP tools (`ToolSearch: "+google contact"`).

```json
{
  "fetched_at": "2026-02-28T10:00:00-04:00",
  "emails": ["alice@example.com", "bob@company.com"]
}
```

Build a Set from cached emails for O(1) known-contact detection.

---

## Gmail REST API

### Signal Agent Queries

All queries below use `USER_EMAIL` from the Runtime Context lookup (see SKILL.md). Never hardcode a sender email address.

| Purpose | Query |
|---------|-------|
| Signal emails | `in:inbox newer_than:Nd -category:promotions -category:social -category:forums -category:updates` |
| Promotions | `category:promotions newer_than:Nd` |
| Social | `category:social newer_than:Nd` |
| Forums | `category:forums newer_than:Nd` |
| Updates | `category:updates newer_than:Nd` |
| Sent mail (reply check) | `from:{USER_EMAIL} newer_than:Nd` |

**IMPORTANT:** Do NOT use `category:primary` — it returns 0 results via the API. Use the exclusion query above.

### Message Fetching

```bash
# Metadata only (fast)
curl -s "https://gmail.googleapis.com/gmail/v1/users/me/messages/$MSG_ID?format=metadata&metadataHeaders=Subject&metadataHeaders=From&metadataHeaders=Date" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

- Use `format=metadata` for headers-only
- Use `format=full` only when body content is needed
- Add 0.1s delay between requests to avoid 429 rate limits
- **Write Python scripts** for bulk fetching

### Batch Label Modification (Archiving)

```bash
curl -s -X POST "https://gmail.googleapis.com/gmail/v1/users/me/messages/batchModify" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ids": ["msg1", "msg2"], "removeLabelIds": ["INBOX", "UNREAD"]}'
```

- **Archive** = remove `INBOX` label
- **Mark read** = remove `UNREAD` label
- Max **1,000 message IDs per call**
- **Empty response body = success**

**Quick mode:** `batchModify` is not available. The Signal Agent should still count noise and filtered emails but skip the archival API call. Include `"archive_skipped": true` in the output JSON and set `"archive_skipped_reason": "quick mode — no Gmail modify access"`.

### Reply Detection — Bulk Approach

1. One query: `from:{USER_EMAIL} newer_than:Nd` (where `USER_EMAIL` is from the Runtime Context lookup)
2. Fetch metadata for all results (batches of 25)
3. Extract thread_ids into a Set
4. For each signal email: `thread_id in Set` -> `replied: true`

---

## Slack MCP Tools

Discover at runtime via `ToolSearch: "+slack"`. Key tools:

| Tool | Purpose |
|------|---------|
| `slack_search_public_and_private` | Search DMs with `channel_types: "im"`, `to:me`, `after:` timestamp |
| `slack_read_channel` | Read full DM channel by D-prefixed channel_id |
| `slack_read_thread` | Read thread replies in a DM |
| `slack_read_user_profile` | Resolve user_id -> email for project routing |
| `slack_search_users` | Find user by name |

### DM Search Pattern

```
slack_search_public_and_private(
  query: "to:me",
  channel_types: "im",
  sort: "timestamp",
  sort_dir: "desc",
  after: "{last_scan_unix_timestamp}",
  include_bots: false,
  limit: 20
)
```

Paginate via `cursor` if more results exist.

### Resolving Sender Identity

For each unique sender user_id from DM results:
```
slack_read_user_profile(user_id: "{user_id}")
```

Extract `Email` field. This email address is used for project routing in Phase 2 (same routing table as Gmail senders).

---

## Google Calendar MCP

Discover via `ToolSearch: "+google calendar"`. Fetch events for today + tomorrow:

```
get_events(calendar_id: "primary", time_min: "{today_iso}", time_max: "{day_after_tomorrow_iso}")
```

Save events with `htmlLink` to `/tmp/scan-calendar-events.json` for source linking in task descriptions.

---

## Fireflies MCP

Discover via `ToolSearch: "+fireflies"`. Non-fatal — if unavailable, workers skip this source.

```
fireflies_search(participant: "{stakeholder_email}", limit: 10)
```

For results from the last 7 days, pull summaries to extract action items and decisions.

---

## Shell Escaping Gotchas

- **Never use inline `$(uuidgen)` in JSON strings** — causes escaping issues
- **Never use `!=` in Python inside bash heredocs** — bash escapes it as `\!=`
- **Always build JSON payloads in standalone Python**, write to a temp file, then `curl -d @file.json`
- **Use `str(uuid.uuid4())` in Python** instead of shell-level UUID generation

---

## Signal Agent Output Schema

**Output path:** `/tmp/scan-signal.json`

```json
{
  "total_found": 126,
  "filtered_out": 57,
  "non_signal_archived": 57,
  "noise_counts": {"promotions": 23, "social": 8, "forums": 12, "updates": 15},
  "noise_archived": {"promotions": 23, "social": 8, "forums": 12, "updates": 15},
  "filter_reasons": {"noise_sender": 5, "noise_domain": 3, "self_send": 24},
  "inbox_remaining_after_cleanup": 3,
  "signal_emails": [
    {
      "message_id": "19c7a...",
      "thread_id": "19c7a...",
      "subject": "Re: Sprint discovery call",
      "from_name": "Robert Newcombe",
      "from_email": "robert@company.com",
      "date": "2026-02-28",
      "is_known_contact": true,
      "is_important": true,
      "replied": false
    }
  ],
  "filtered_emails": [
    {"message_id": "...", "from_email": "...", "subject": "...", "filter_rule_id": "..."}
  ]
}
```

**IMPORTANT:** `inbox_remaining_after_cleanup` is the count from a final `in:inbox` query (no filters) run AFTER all archival operations. The main scan uses this to verify inbox state. If this number is higher than the signal_emails count, the agent missed something.

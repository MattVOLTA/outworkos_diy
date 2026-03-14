# Limitless API Reference

## Base URL
```
https://api.limitless.ai
```

## Authentication
```
X-API-Key: {key from Vault label: limitless_api_key}
```

Retrieve at runtime via Supabase MCP `execute_sql`:
```sql
SELECT decrypted_secret FROM vault.decrypted_secrets
WHERE name = 'user_' || '{user_id}' || '_limitless_api_key' LIMIT 1;
```
Where `{user_id}` is resolved from `auth.uid()` at the start of the session.

## Rate Limits
- 180 requests/minute per API key
- Exceeded: `429` with `{"error": "API key is rate limited", "retryAfter": "60"}`

## Endpoints

### GET /v1/lifelogs

List/search lifelogs with filtering & pagination.

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `timezone` | string | UTC | IANA timezone (use the user's timezone from `user_profiles.timezone`) |
| `date` | string | - | `YYYY-MM-DD` for a specific date |
| `start` | string | - | ISO-8601 datetime range start |
| `end` | string | - | ISO-8601 datetime range end |
| `cursor` | string | - | Pagination cursor |
| `direction` | string | `desc` | `asc` or `desc` |
| `limit` | integer | 10 | Max entries (cap: 10) |
| `search` | string | - | Natural language search query |
| `includeMarkdown` | boolean | true | Include raw markdown |
| `includeHeadings` | boolean | true | Include headings |
| `includeContents` | boolean | false | Include content nodes |
| `isStarred` | boolean | false | Filter starred only |

**Response:**
```json
{
  "data": {
    "lifelogs": [
      {
        "id": "string",
        "title": "string",
        "markdown": "string",
        "startTime": "ISO-8601 with timezone",
        "endTime": "ISO-8601 with timezone",
        "isStarred": false,
        "updatedAt": "ISO-8601",
        "contents": [
          {
            "type": "heading1 | heading2 | heading3 | blockquote | paragraph",
            "content": "string",
            "startTime": "ISO-8601",
            "endTime": "ISO-8601",
            "startOffsetMs": 0,
            "endOffsetMs": 3000,
            "speakerName": "string | null",
            "speakerIdentifier": "string | null"
          }
        ]
      }
    ],
    "meta": {
      "nextCursor": "string | null",
      "count": 10
    }
  }
}
```

### GET /v1/lifelogs/{lifelog_id}

Get a specific lifelog by ID. Same query params as list endpoint (for include flags).

### GET /v1/download-audio

Download audio as Ogg Opus format.

| Param | Type | Description |
|-------|------|-------------|
| `audioSource` | string | Default: `pendant` |
| `startMs` | integer | Start time in milliseconds |
| `endMs` | integer | End time in milliseconds |

Max duration: 2 hours (7,200,000ms) per request.

## Known Limitations

- **Pendant recordings only** — web and desktop meetings not supported
- **Max 10 lifelogs per request** — no reliable pagination cursor
- **Speaker names often "Unknown"** — pendant doesn't identify speakers well
- **API is in beta** — endpoints may change
- **Workaround for 10-item limit**: Fetch both `direction=asc` and `direction=desc`, then deduplicate by `id`. This captures up to 20 lifelogs. Mid-day entries on very busy days may still be missed.

## Example: Fetch Full Day

```bash
# Resolve user timezone from user_profiles at runtime
LIMITLESS_API_KEY=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" limitless_api_key)

# Ascending (oldest first) — substitute {user_timezone} with the value from user_profiles.timezone
curl -s -X GET "https://api.limitless.ai/v1/lifelogs?date=2026-02-27&timezone={user_timezone}&includeMarkdown=true&includeHeadings=true&includeContents=true&limit=10&direction=asc" \
  -H "X-API-Key: $LIMITLESS_API_KEY"

# Descending (newest first)
curl -s -X GET "https://api.limitless.ai/v1/lifelogs?date=2026-02-27&timezone={user_timezone}&includeMarkdown=true&includeHeadings=true&includeContents=true&limit=10&direction=desc" \
  -H "X-API-Key: $LIMITLESS_API_KEY"
```

Merge both results, deduplicate by `id`, sort by `startTime`.

# Fireflies GraphQL API Reference

## Endpoint

```
POST https://api.fireflies.ai/graphql
```

## Authentication

```
Authorization: Bearer <token>
```

Token stored in Vault with label `fireflies_token`. Retrieve at runtime:
```bash
FIREFLIES_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" fireflies_token)
```

## URL Parsing

Fireflies transcript URLs follow this format:
```
https://app.fireflies.ai/view/MEETING-TITLE::TRANSCRIPT_ID
```

Extract the transcript ID by splitting on `::` and taking the last segment:
```python
url = "https://app.fireflies.ai/view/My-Meeting-Title::abc123def456"
transcript_id = url.split("::")[-1]  # "abc123def456"
```

## Query: Fetch Transcript by ID

```graphql
query Transcript($id: String!) {
  transcript(id: $id) {
    title
    date
    duration
    participants
    sentences {
      text
      speaker_name
    }
    summary {
      action_items
      overview
      shorthand_bullet
    }
  }
}
```

### Field Reference

| Field | Type | Description |
|-------|------|-------------|
| `title` | String | Meeting title (from calendar or auto-generated) |
| `date` | String | ISO timestamp of the meeting |
| `duration` | Float | Duration in seconds |
| `participants` | [String] | List of participant names/emails |
| `sentences` | [Object] | Full transcript as speaker-attributed segments |
| `sentences.text` | String | What was said |
| `sentences.speaker_name` | String | Who said it |
| `summary.action_items` | String | Extracted action items (newline-separated) |
| `summary.overview` | String | AI-generated meeting overview |
| `summary.shorthand_bullet` | String | Key topics as bullet points |

## Example: curl

```bash
FIREFLIES_TOKEN=$("$OUTWORKOS_ROOT/scripts/get-secret.sh" fireflies_token)

curl -s -X POST https://api.fireflies.ai/graphql \
  -H "Authorization: Bearer $FIREFLIES_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { transcript(id: \"TRANSCRIPT_ID\") { title date duration participants sentences { text speaker_name } summary { action_items overview shorthand_bullet } } }"
  }' | python3 -m json.tool
```

## Example: Search Recent Transcripts

```graphql
query RecentTranscripts {
  transcripts(limit: 10) {
    id
    title
    date
    duration
    participants
  }
}
```

```bash
curl -s -X POST https://api.fireflies.ai/graphql \
  -H "Authorization: Bearer $FIREFLIES_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "query { transcripts(limit: 10) { id title date duration participants } }"}' \
  | python3 -m json.tool
```

## MCP Fallback

If the API call fails (e.g., auth issues), discover Fireflies MCP tools:
```
ToolSearch: "fireflies transcript"
```

MCP tools may provide `fireflies_get_transcript`, `fireflies_search`, etc. These are alternative access paths to the same data.

## Error Handling

| HTTP Status | Meaning | Action |
|-------------|---------|--------|
| 200 + `errors` in body | GraphQL error (bad ID, missing field) | Check `errors[0].message` |
| 401 | Token expired or invalid | Re-store token via `set-secret.sh fireflies_token <new_token>` |
| 429 | Rate limited | Back off and retry after delay |

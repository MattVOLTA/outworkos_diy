# LinkedIn API Reference

Quick reference for the Posts API, image uploads, and OAuth token management.

---

## Authentication

### Required Scopes

| Scope | Purpose | Approval |
|-------|---------|----------|
| `openid` | Get Person URN via userinfo | Auto-approved (Sign In with LinkedIn) |
| `profile` | Basic profile info | Auto-approved |
| `w_member_social` | Create posts as yourself | Auto-approved (Share on LinkedIn) |

### OAuth Endpoints

| Endpoint | Purpose |
|----------|---------|
| `https://www.linkedin.com/oauth/v2/authorization` | Authorization (browser) |
| `https://www.linkedin.com/oauth/v2/accessToken` | Token exchange + refresh |
| `https://api.linkedin.com/v2/userinfo` | Get Person URN (`sub` field) |

### Token Lifetimes

| Token | Lifetime |
|-------|----------|
| Access token | 60 days |
| Refresh token | ~1 year |

### Token Refresh

```bash
curl -s -X POST "https://www.linkedin.com/oauth/v2/accessToken" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=$LINKEDIN_REFRESH_TOKEN" \
  -d "client_id=$LINKEDIN_CLIENT_ID" \
  -d "client_secret=$LINKEDIN_CLIENT_SECRET"
```

Response:
```json
{
  "access_token": "new_token",
  "expires_in": 5184000,
  "refresh_token": "new_refresh_token",
  "refresh_token_expires_in": 31536000
}
```

**Important**: Refresh tokens are single-use. Each refresh returns a new refresh token. Always save both the new access token and new refresh token to Vault via `$OUTWORKOS_ROOT/scripts/set-secret.sh`.

---

## Posts API

### Base URL

```
https://api.linkedin.com/rest/posts
```

### Required Headers

```
Authorization: Bearer {access_token}
LinkedIn-Version: 202501
X-Restli-Protocol-Version: 2.0.0
Content-Type: application/json
```

### Text Post

```json
{
  "author": "urn:li:person:{id}",
  "commentary": "Your post text here.\n\nLine breaks work like this.",
  "visibility": "PUBLIC",
  "distribution": {
    "feedDistribution": "MAIN_FEED",
    "targetEntities": [],
    "thirdPartyDistributionChannels": []
  },
  "lifecycleState": "PUBLISHED",
  "isReshareDisabledByAuthor": false
}
```

**Success**: HTTP 201, `x-restli-id` header has the post URN (e.g., `urn:li:share:7123456789`).

### Post with Link Preview (Article)

```json
{
  "author": "urn:li:person:{id}",
  "commentary": "Check out this article",
  "visibility": "PUBLIC",
  "distribution": {
    "feedDistribution": "MAIN_FEED",
    "targetEntities": [],
    "thirdPartyDistributionChannels": []
  },
  "content": {
    "article": {
      "source": "https://example.com/article",
      "title": "Article Title",
      "description": "Brief description of the article"
    }
  },
  "lifecycleState": "PUBLISHED",
  "isReshareDisabledByAuthor": false
}
```

Note: `title` and `description` in the article block are optional — LinkedIn will scrape the URL if omitted. But providing them gives you control over the preview card.

### Post with Image

Two-step process: upload the image first, then reference it in the post.

**Step 1: Initialize Upload**

```bash
curl -s -X POST "https://api.linkedin.com/rest/images?action=initializeUpload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "LinkedIn-Version: 202501" \
  -H "X-Restli-Protocol-Version: 2.0.0" \
  -H "Content-Type: application/json" \
  -d '{
    "initializeUploadRequest": {
      "owner": "urn:li:person:{id}"
    }
  }'
```

Response:
```json
{
  "value": {
    "uploadUrlExpiresAt": 1234567890000,
    "uploadUrl": "https://www.linkedin.com/dms-uploads/...",
    "image": "urn:li:image:C4E..."
  }
}
```

**Step 2: Upload Binary**

```bash
curl -s -X PUT "$UPLOAD_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @/path/to/image.jpg
```

**Step 3: Create Post with Image**

```json
{
  "author": "urn:li:person:{id}",
  "commentary": "Post text here",
  "visibility": "PUBLIC",
  "distribution": {
    "feedDistribution": "MAIN_FEED",
    "targetEntities": [],
    "thirdPartyDistributionChannels": []
  },
  "content": {
    "media": {
      "id": "urn:li:image:C4E...",
      "title": "Optional image title"
    }
  },
  "lifecycleState": "PUBLISHED",
  "isReshareDisabledByAuthor": false
}
```

### Mentions

Format: Include in `commentary` field with annotation.

The commentary contains the text with the mention name inline, and a separate `socialMetadata` block maps character positions to URNs. This is complex — for simple posts, just write the person's name without a formal mention.

### Hashtags

Include directly in `commentary`:
```
"Post text here\n\n#AI #Leadership #Halifax"
```

No special API treatment needed — LinkedIn auto-links hashtags.

---

## Rate Limits

- Application-level daily limits (reset at midnight UTC)
- HTTP 429 returned when exceeded
- Low-volume personal posting (1-3/day) is well within limits
- No official per-post frequency documented

---

## Error Codes

| HTTP | Meaning | Fix |
|------|---------|-----|
| 201 | Success (post created) | — |
| 401 | Token expired or invalid | Refresh token or re-auth |
| 403 | Insufficient scope | Check `w_member_social` is granted |
| 422 | Invalid post body | Check required fields, URN format |
| 429 | Rate limited | Wait and retry |

---

## Vault Labels

All LinkedIn credentials are stored in Supabase Vault. Retrieve via `$OUTWORKOS_ROOT/scripts/get-secret.sh`:

| Vault Label | Value |
|---|---|
| `linkedin_client_id` | OAuth client ID |
| `linkedin_client_secret` | OAuth client secret |
| `linkedin_access_token` | Current access token |
| `linkedin_refresh_token` | Current refresh token |
| `linkedin_person_urn` | `urn:li:person:<sub-value>` |

Token port: **5556** (avoids conflict with Google on 5555 and Xero on 8749).

# Conventional Commits Reference

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | When to Use | SemVer Impact |
|------|-------------|---------------|
| `feat` | New feature for the user | MINOR |
| `fix` | Bug fix for the user | PATCH |
| `docs` | Documentation only changes | None |
| `style` | Formatting, white-space, semicolons (no code change) | None |
| `refactor` | Code change that neither fixes bug nor adds feature | None |
| `perf` | Performance improvement | PATCH |
| `test` | Adding or correcting tests | None |
| `build` | Build system or external dependencies | None |
| `ci` | CI configuration and scripts | None |
| `chore` | Maintenance tasks | None |
| `revert` | Reverting a previous commit | Depends |

## Breaking Changes

Two ways to indicate:

1. **Append an exclamation mark after type:**
   ```
   feat!: remove deprecated API endpoints
   ```

2. **Footer notation:**
   ```
   feat: change authentication flow

   BREAKING CHANGE: JWT tokens now require refresh token rotation.
   Old tokens will be invalidated.
   ```

Breaking changes → MAJOR version bump.

## Scope

Optional context in parentheses:

```
feat(auth): add OAuth2 support
fix(api): handle null response gracefully
docs(readme): update installation instructions
```

**Common scopes:**
- Component/module name: `auth`, `api`, `ui`, `db`
- Feature area: `login`, `checkout`, `dashboard`
- Layer: `frontend`, `backend`, `infra`

## Description Rules

- Imperative mood: "add" not "added" or "adds"
- Lowercase first letter
- No period at end
- Max 50 characters (soft limit, 72 hard)

**Good:**
- `add user authentication`
- `fix null pointer in checkout`
- `update dependency versions`

**Bad:**
- `Added user authentication` (past tense)
- `Adds user authentication.` (third person, period)
- `USER AUTHENTICATION` (caps)

## Body

- Separate from description by blank line
- Explain what and why, not how
- Wrap at 72 characters

```
fix(auth): prevent session fixation attack

The session ID was not being regenerated after login,
allowing attackers to fixate a session before the user
authenticates and then hijack it afterward.

Now regenerating session ID on all authentication state
changes.
```

## Footers

- `BREAKING CHANGE: <description>` - API breaking change
- `Closes #123` - Issue reference
- `Reviewed-by: Name` - Reviewer credit
- `Refs: #456, #789` - Related issues

## Examples

### Simple feature
```
feat(cart): add quantity selector to cart items
```

### Bug fix with issue reference
```
fix(checkout): correct tax calculation for EU orders

Tax was being applied before discount, resulting in
overcharges for discounted items.

Closes #234
```

### Breaking change
```
feat(api)!: change response format to JSON:API spec

BREAKING CHANGE: All API responses now follow JSON:API
specification. Clients must update their parsers.

Migration guide: https://docs.example.com/api-v2-migration
```

### Revert
```
revert: feat(auth): add OAuth2 support

This reverts commit abc123def.

OAuth2 implementation had security issues that need
to be addressed before re-release.
```

### Multiple footers
```
feat(notifications): add email digest option

Users can now opt into daily or weekly email digests
instead of real-time notifications.

Closes #567
Refs #123, #234
Reviewed-by: Jane Doe <jane@example.com>
```

## Anti-Patterns

**Vague descriptions:**
- `fix: stuff`
- `feat: updates`
- `chore: changes`

**Too long:**
- `feat: add new user authentication system with OAuth2 support including Google, GitHub, and Microsoft providers with automatic token refresh`

**Multiple concerns:**
- `feat: add login and fix header and update deps`

**Wrong type:**
- Using `feat` for bug fixes
- Using `fix` for new features
- Using `chore` for everything

## Quick Decision Tree

```
Did you add new functionality?
  → feat

Did you fix a bug?
  → fix

Did you only change docs?
  → docs

Did you only change tests?
  → test

Did you only refactor (no behavior change)?
  → refactor

Did you improve performance?
  → perf

Did you change build/deps?
  → build

Did you change CI/CD?
  → ci

Everything else?
  → chore
```

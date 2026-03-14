# TDD Troubleshooting Guide

## Common Problems and Solutions

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Investigate similar tests. Ask your human partner. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract test helpers/fixtures. Still complex? Simplify design. |
| Testing database operations | Investigate if project has test database setup. Look for existing database test patterns. Prefer real database over mocks. Implement cleanup strategy. |
| Test data pollution | Tests leave data in database. Implement cleanup: transactions with rollback, afterEach/afterAll hooks, or cleanup scripts. Verify database clean after tests. |
| Testing async code | Use framework's async testing utilities. Don't just await - test actual behavior. Check existing async tests for patterns. |
| Testing API routes | Investigate framework test client (supertest, etc.). Find existing API tests to follow. Test full request/response cycle. |
| Testing with external APIs | Always mock. Look for existing mocking patterns (nock, MSW, VCR). Test error cases. |
| Legacy code without tests | Add tests for new behavior first. Consider characterization tests for existing behavior. Follow TDD for all new code. |
| Framework-specific testing | Search codebase for existing tests. Check framework docs for testing best practices. Look for test setup/teardown patterns. |
| Performance/integration tests | These complement TDD, don't replace it. Unit tests first (fast feedback), integration tests verify end-to-end. |

## Technology-Specific Adaptations

### Databases

- **With test database**: Use real database for integration tests (tests triggers, constraints, RLS)
- **With in-memory database**: Prefer in-memory for speed (SQLite, H2)
- **Without test database**: Mock database calls, but note you're not testing database behavior
- **Transactions**: Wrap tests in transactions and rollback for isolation

**Key question**: Does the database have triggers, constraints, or row-level security? If yes, strongly prefer real database tests.

### API Routes/Endpoints

- Test the full request/response cycle when possible
- Use framework-specific test clients (supertest, httptest, TestClient)
- Verify status codes, headers, response body
- Test error cases (validation failures, auth errors, not found)

### External Services

- **Always mock** - External services cost money, have rate limits, or cause side effects
- Use recorded responses (VCR, Polly.js) for realistic fixtures
- Test error handling (timeouts, 500 errors, API changes)

### Async Operations

- Test actual async behavior, don't just await and assume it works
- Test race conditions, timeouts, retries
- Verify side effects occur in correct order

### React/UI Components

- Test behavior, not implementation
- User interactions → expected output
- Prefer integration tests over unit tests for components
- Use Testing Library patterns (user-centric queries)

## Mocking Strategy

**Investigate what to mock:**

1. **Never mock**: Pure functions, business logic, utilities
2. **Prefer real**: Databases (with test DB), file system (with temp dirs), in-process dependencies
3. **Always mock**: HTTP APIs, email services, payment processors, time-dependent code
4. **Context-dependent**: ORMs (real for integration, mock for unit), caches (real if fast, mock if network)

**Check project conventions**: If existing tests use real database, follow that pattern.

## Common Architecture Patterns

- **Service layer pattern**: Test services with real dependencies when possible, test controllers/routes with mocked services
- **Repository pattern**: Test repositories with real database, test business logic with mocked repositories
- **Hexagonal/Clean architecture**: Test domain logic (core) with no mocks, test adapters (infrastructure) with real external systems

## Discovering Test Commands

Look in `package.json` scripts:

```json
{
  "scripts": {
    "test": "...",                    // Run this
    "test:watch": "...",              // Or this for TDD
    "test:unit": "...",
    "test:integration": "...",
    "cleanup:test-data": "...",       // Check for cleanup scripts
    "test:cleanup": "..."
  }
}
```

Common patterns:
- Node: `npm test`, `npm run test:watch`
- Python: `pytest`, `pytest -v`
- .NET: `dotnet test`
- Java: `mvn test`, `gradle test`

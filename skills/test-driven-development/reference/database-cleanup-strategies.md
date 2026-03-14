# Database Test Data Cleanup Strategies

Tests MUST NOT pollute the database. Choose cleanup strategy based on your test framework:

## Strategy 1: Transactions (Preferred)

```typescript
// Wrap each test in transaction, rollback after
beforeEach(async () => {
  await db.beginTransaction();
});

afterEach(async () => {
  await db.rollback();
});
```

**Pros:**
- Automatic, fast, foolproof
- No manual tracking required

**Cons:**
- Doesn't work if code commits transactions
- May not work with connection pooling

## Strategy 2: Teardown Hooks

```typescript
// Delete test data after each test
const testData: TestRecord[] = [];

afterEach(async () => {
  for (const record of testData) {
    await db.delete(record.table, record.id);
  }
  testData.length = 0;
});

test('creates user', async () => {
  const user = await createUser({ email: 'test@example.com' });
  testData.push({ table: 'users', id: user.id });
  expect(user).toBeDefined();
});
```

**Pros:**
- Works with committed transactions
- Fine-grained control

**Cons:**
- Manual tracking required
- Can miss cleanup on test failures (use try/finally)

## Strategy 3: Cleanup Scripts

```typescript
// Run cleanup command after test suite
afterAll(async () => {
  await exec('npm run cleanup:all-test-data');
});
```

**Pros:**
- Handles complex relationships
- Project-specific logic
- Catches anything missed by other strategies

**Cons:**
- Slower
- Requires maintenance

## Verification

```typescript
// Verify database is clean after tests
afterAll(async () => {
  const testRecords = await db.query(
    "SELECT * FROM users WHERE email LIKE '%@test.example.com'"
  );
  expect(testRecords).toHaveLength(0);
});
```

## Rules

1. **NEVER** leave test data in database
2. Use unique identifiers (UUIDs, timestamps) to distinguish test data
3. Check for cleanup scripts in package.json (`cleanup:test-data`, `test:cleanup`)
4. Verify cleanup worked (query for test data after suite)
5. If tests fail mid-run, cleanup should still run (use try/finally)

## Test Commands to Look For

In `package.json`:
```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "cleanup:test-data": "tsx scripts/cleanup-test-data.ts",
    "cleanup:all-test-data": "tsx scripts/cleanup-all-test-data.ts",
    "test:cleanup": "vitest && npm run cleanup:test-data"
  }
}
```

## Red Flags

- Finding yesterday's test data in database
- Tests fail when run twice
- "Works on my machine" (stale test data)
- Manual database cleanup between test runs
- Tests that depend on execution order

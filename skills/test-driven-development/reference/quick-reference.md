# TDD Quick Reference Card

## The Cycle

```
RED → Verify Fails → GREEN → Verify Passes → REFACTOR → Repeat
```

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

**If you wrote code before the test:** Delete it. Start over. No exceptions.

## First Step

**ALWAYS investigate the codebase first:**
- Find existing tests (`**/*.test.ts`, `__tests__/`)
- Identify test framework
- Discover patterns and helpers
- Check for cleanup scripts

## Good Test Qualities

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Real** | Tests real code | Tests mocks instead of code |

## Verification Checklist

- [ ] Every new function has a test
- [ ] Watched each test fail first
- [ ] Wrote minimal code to pass
- [ ] All tests pass with clean output
- [ ] Test data cleanup implemented
- [ ] Database verified clean after tests

## Test Data Cleanup

```typescript
afterEach(async () => {
  for (const id of testIds) {
    await cleanup(id);
  }
  testIds.clear();
});
```

## Bug Fix Pattern

1. Write test that reproduces the bug (RED)
2. Verify test fails (bug confirmed)
3. Fix the bug (GREEN)
4. Verify test passes (bug fixed)
5. Test prevents regression forever

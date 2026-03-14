# QA Metrics & Formulas

Reference guide for calculating and interpreting quality metrics.

## Coverage Metrics

### Line Coverage

**Definition:** Percentage of code lines executed during tests.

**Formula:**
```
Line Coverage = (Lines Executed / Total Lines) × 100
```

**Example:**
```
Total lines: 1000
Lines executed by tests: 750
Line Coverage = (750 / 1000) × 100 = 75%
```

**Interpretation:**
- **90-100%**: Excellent (only acceptable for critical code)
- **75-90%**: Good (target for production code)
- **60-75%**: Acceptable (MVP/internal tools)
- **<60%**: Poor (significant gaps)

**Limitations:**
- Doesn't mean tests are good (could have weak assertions)
- Doesn't guarantee all behaviors tested
- Can be gamed (execute code without asserting)

### Branch Coverage

**Definition:** Percentage of conditional branches (if/else, switch, ternary) tested.

**Formula:**
```
Branch Coverage = (Branches Executed / Total Branches) × 100
```

**Example:**
```javascript
function validate(user) {
  if (!user.email) {        // Branch 1: true path
    return false;
  }
  if (!user.age) {          // Branch 2: true path
    return false;
  }
  return user.age >= 18;    // Branch 3: true/false
}

// Total branches: 5 (email-true, email-false, age-true, age-false, age>=18 true/false)
// If tests cover 4 branches: (4 / 5) × 100 = 80%
```

**Interpretation:**
- **85-100%**: Excellent
- **70-85%**: Good
- **50-70%**: Acceptable
- **<50%**: Poor (many paths untested)

**Why it matters:**
More thorough than line coverage. A line might execute, but not all its branches.

### Function Coverage

**Definition:** Percentage of functions called during tests.

**Formula:**
```
Function Coverage = (Functions Called / Total Functions) × 100
```

**Interpretation:**
- Useful for finding completely untested modules
- Less useful than line/branch coverage for quality assessment
- Target: 90%+ (few functions should be entirely untested)

### Statement Coverage

**Definition:** Percentage of statements executed.

**Similar to line coverage but counts logical statements, not just lines.**

## Effectiveness Metrics

### Test Effectiveness

**Definition:** How well tests catch real bugs.

**Formula:**
```
Test Effectiveness = (Bugs Caught by Tests / Total Bugs Found) × 100
```

**Example:**
```
Bugs found in production: 20
Bugs caught by tests before release: 15
Test Effectiveness = (15 / 20) × 100 = 75%
```

**Interpretation:**
- **90-100%**: Excellent (tests reliably catch issues)
- **75-90%**: Good
- **60-75%**: Fair (significant bugs slip through)
- **<60%**: Poor (tests missing critical scenarios)

**Improvement strategies:**
- Add tests for production bugs (prevent regression)
- Review bugs that slipped through (why didn't tests catch?)
- Increase edge case coverage

### Defect Density

**Definition:** Number of defects per unit of code size.

**Formula:**
```
Defect Density = Defects Found / Size (KLOC)

Where KLOC = Thousands of Lines of Code
```

**Example:**
```
Defects found: 5
Code size: 2000 LOC = 2 KLOC
Defect Density = 5 / 2 = 2.5 defects per KLOC
```

**Industry benchmarks:**
- **1-3 defects/KLOC**: Good
- **3-5 defects/KLOC**: Acceptable
- **5-10 defects/KLOC**: Poor
- **>10 defects/KLOC**: Critical

**Context matters:**
- New code: Higher density expected
- Legacy code: Lower density (bugs already found)
- Critical code: Target <1 defect/KLOC

### Defect Removal Efficiency (DRE)

**Definition:** Percentage of defects found before production.

**Formula:**
```
DRE = (Defects Found Before Release / Total Defects) × 100

Where Total Defects = Pre-release + Post-release defects
```

**Example:**
```
Defects found in testing: 45
Defects found in production: 5
Total defects: 45 + 5 = 50
DRE = (45 / 50) × 100 = 90%
```

**Interpretation:**
- **>95%**: Excellent (catching almost all bugs)
- **90-95%**: Good
- **80-90%**: Acceptable
- **<80%**: Poor (many bugs escaping to production)

**Goal:** High DRE means quality processes (testing, code review) are effective.

## Performance Metrics

### Test Suite Runtime

**Definition:** Total time to run all tests.

**Targets by test type:**
- **Unit tests**: <1 minute (for fast feedback)
- **Integration tests**: <5 minutes
- **E2E tests**: <15 minutes
- **Full suite**: <10 minutes (for quick CI/CD)

**Example:**
```
Unit: 850 tests, 35 seconds
Integration: 120 tests, 3.5 minutes
E2E: 15 tests, 8 minutes
Total: 985 tests, 11m 35s
```

**Red flags:**
- Unit tests >5 minutes (too slow, likely not true unit tests)
- E2E tests >30 minutes (too many, reduce to critical paths)
- Runtime growing >20% month-over-month (performance degradation)

### Average Test Speed

**Formula:**
```
Average Speed = Total Runtime / Number of Tests
```

**Targets:**
- **Unit tests**: <10ms per test
- **Integration tests**: <100ms per test
- **E2E tests**: <5s per test

**Example:**
```
Unit: 35 seconds / 850 tests = 41ms per test (⚠️ Slower than ideal)
Integration: 210 seconds / 120 tests = 1750ms per test (❌ Too slow)
E2E: 480 seconds / 15 tests = 32s per test (✅ Acceptable)
```

**Optimization targets:**
- Unit tests >100ms: Check for external dependencies
- Integration tests >1s: Optimize database setup/teardown
- E2E tests >10s: Consider splitting or parallel execution

### Flakiness Rate

**Definition:** Percentage of test runs that fail non-deterministically.

**Formula:**
```
Flakiness Rate = (Failed Runs / Total Runs) × 100

Where failures are not due to actual bugs
```

**Measurement approach:**
Run test suite 10 times without code changes:

**Example:**
```
10 runs: 8 pass, 2 fail (same tests fail)
Flakiness Rate = (2 / 10) × 100 = 20%
```

**Interpretation:**
- **0%**: Perfect (fully deterministic)
- **<5%**: Acceptable (minimal flakiness)
- **5-10%**: Problematic (needs investigation)
- **>10%**: Critical (CI/CD unreliable)

**Common causes:**
- Time-dependent tests (Date.now(), setTimeout)
- Race conditions (async without proper waits)
- External dependencies (real API calls)
- Test order dependency
- Random data without seeding

## Quality Metrics

### Test-to-Code Ratio

**Definition:** Ratio of test code to production code.

**Formula:**
```
Test-to-Code Ratio = Test LOC / Production LOC
```

**Example:**
```
Production code: 5000 LOC
Test code: 3500 LOC
Ratio = 3500 / 5000 = 0.7
```

**Interpretation:**
- **0.5-2.0**: Healthy (context-dependent)
- **<0.5**: Likely under-tested
- **>2.0**: Possibly over-tested or fragile tests

**Context matters:**
- Complex business logic: Higher ratio expected
- Simple CRUD: Lower ratio acceptable
- TDD projects: Often 1:1 or higher

### Code Churn

**Definition:** How frequently code changes (indicates stability).

**Formula:**
```
Churn Rate = Commits in Period / Total Files
```

**Example:**
```bash
git log --since="1 month ago" --name-only --pretty=format: | sort | uniq -c | sort -rn | head -10
```

**Output:**
```
  25 src/auth/login.js       ← High churn (25 commits/month)
  18 src/api/users.js
   8 src/utils/validation.js
   2 src/config/database.js  ← Low churn (stable)
```

**Interpretation:**
- **High churn (>20 commits/month)**: Indicates active development or instability
  - **Action**: Ensure high test coverage (risk of bugs)
- **Medium churn (10-20 commits/month)**: Normal feature development
  - **Action**: Standard test coverage
- **Low churn (<5 commits/month)**: Stable code
  - **Action**: Lower test priority if already covered

**Red flag:** High churn + Low coverage = High risk

### Mutation Testing Score (Advanced)

**Definition:** Percentage of code mutations detected by tests.

**Concept:**
Mutation testing tools make small changes (mutations) to code:
- Change `>` to `>=`
- Change `&&` to `||`
- Remove `return` statement

If tests still pass with mutation → Tests missed that code path.

**Formula:**
```
Mutation Score = (Mutations Killed / Total Mutations) × 100
```

**Example:**
```
Total mutations: 150
Mutations killed by tests: 120
Mutation Score = (120 / 150) × 100 = 80%
```

**Interpretation:**
- **80-100%**: Excellent test quality
- **60-80%**: Good
- **40-60%**: Fair (many weak assertions)
- **<40%**: Poor (tests execute code but don't validate)

**Tools:**
- **JavaScript**: Stryker
- **Python**: mutmut
- **Java**: PITest

**When to use:**
- Critical code (payments, authentication)
- After achieving high line coverage (next-level validation)
- Not for all code (expensive, time-consuming)

## Dashboards & Tracking

### Coverage Trend

**Track over time:**
```
Week | Line Coverage | Branch Coverage | Trend
-----|---------------|-----------------|-------
W1   | 65%          | 55%             | Baseline
W2   | 68%          | 58%             | ↗ +3%
W3   | 67%          | 57%             | ↘ -1% (regression!)
W4   | 72%          | 62%             | ↗ +5%
```

**Red flags:**
- Declining coverage (code added without tests)
- Stagnant coverage (not improving)
- Volatile coverage (inconsistent quality)

### Defect Trend

**Track by severity:**
```
Month | Critical | High | Medium | Low | Total
------|----------|------|--------|-----|------
Jan   | 2        | 5    | 12     | 8   | 27
Feb   | 1        | 4    | 10     | 6   | 21
Mar   | 0        | 2    | 8      | 5   | 15
```

**Goals:**
- Declining total defects (quality improving)
- Zero critical/high severity (caught before release)
- Shift left (find earlier in development)

### Test Health Dashboard

**Key metrics to track:**

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Coverage (overall) | 73% | 75% | ⚠️ Close |
| Coverage (critical) | 88% | 90% | ⚠️ Close |
| Test effectiveness | 85% | 90% | ⚠️ Fair |
| Defect density | 3.2/KLOC | <3/KLOC | ⚠️ Slightly high |
| Flakiness rate | 2% | <5% | ✅ Good |
| Test suite runtime | 8m 45s | <10min | ✅ Good |
| Tests passing | 985/985 | 100% | ✅ Perfect |

## Formulas Quick Reference

```
Line Coverage = (Lines Executed / Total Lines) × 100
Branch Coverage = (Branches Executed / Total Branches) × 100
Function Coverage = (Functions Called / Total Functions) × 100

Test Effectiveness = (Bugs Caught / Total Bugs) × 100
Defect Density = Defects / KLOC
DRE = (Pre-release Defects / Total Defects) × 100

Test-to-Code Ratio = Test LOC / Production LOC
Flakiness Rate = (Failed Runs / Total Runs) × 100
Average Speed = Total Runtime / Number of Tests

Mutation Score = (Mutations Killed / Total Mutations) × 100
```

## Collecting Metrics

### Coverage (JavaScript/Jest)

```bash
npm test -- --coverage --json --outputFile=coverage.json
```

```javascript
const coverage = require('./coverage/coverage-summary.json');
console.log(`Line Coverage: ${coverage.total.lines.pct}%`);
console.log(`Branch Coverage: ${coverage.total.branches.pct}%`);
```

### Coverage (Python/Pytest)

```bash
pytest --cov=src --cov-report=json
```

```python
import json
with open('coverage.json') as f:
    cov = json.load(f)
    print(f"Coverage: {cov['totals']['percent_covered']}%")
```

### Performance Tracking

```bash
# Measure runtime
time npm test > test-runtime.log

# Extract slow tests
npm test -- --verbose | grep "PASS.*ms" | sort -rn | head -10
```

### Flakiness Detection

```bash
# Run tests 10 times
for i in {1..10}; do npm test || echo "Run $i failed"; done
```

## Interpreting Combined Metrics

### High Coverage + Low Effectiveness
**Problem:** Tests execute code but don't validate behavior (weak assertions).
**Solution:** Review test quality, add assertions, consider mutation testing.

### Low Coverage + High Defect Density
**Problem:** Insufficient testing leading to bugs.
**Solution:** Increase coverage, focus on high-risk areas.

### High Coverage + High Flakiness
**Problem:** Tests are fragile, unreliable.
**Solution:** Fix flaky tests (remove time dependencies, async issues).

### Good Coverage + Long Runtime
**Problem:** Tests are slow, hurting developer velocity.
**Solution:** Optimize setup/teardown, enable parallel execution, reduce e2e tests.

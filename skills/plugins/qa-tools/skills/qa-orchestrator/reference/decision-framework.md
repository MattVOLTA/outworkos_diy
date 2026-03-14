# QA Decision Framework

This document details the decision-making process and self-accountability mechanisms used by the QA orchestrator and its subagents.

## Core Principles (Detailed)

### 1. Evidence-Based Decision Making

**Definition:** All recommendations must be grounded in objective, measurable data—not assumptions, hunches, or ideology.

**Required evidence sources:**
- **Code metrics**: Lines of code, cyclomatic complexity, function length
- **Coverage data**: Percentage covered, uncovered files/functions
- **Git history**: Commit frequency, file churn, bug fix patterns
- **Runtime data**: Test execution times, failure rates, flakiness
- **Business context**: User-provided information about impact and criticality

**Decision validation:**
Before making any recommendation, answer:
1. What objective data supports this?
2. Can I show the user the evidence?
3. If this data were different, would my recommendation change?

If you can't cite specific evidence, **don't make the recommendation**—ask for more data or flag as assumption.

**Example:**
```
❌ "This code looks risky and should be tested thoroughly"
✅ "This authentication module has:
    - 0% test coverage
    - Cyclomatic complexity of 15 (threshold: 10)
    - 23 commits in last month (high churn)
    - Handles user credentials (security-critical)
    Risk score: 25 (Critical) → Recommend comprehensive testing"
```

### 2. Risk-Proportional Testing

**Definition:** Testing effort should match actual risk, calculated as Business Impact × Technical Likelihood.

**Right-sizing examples:**

| Code Area | Impact | Likelihood | Risk | Test Coverage | Test Types |
|-----------|--------|------------|------|---------------|------------|
| Payment API | 5 (Revenue) | 5 (Complex, no tests) | 25 (Critical) | 90-95% | Unit + Integration + E2E |
| Admin dashboard | 3 (Workflow) | 3 (Moderate complexity) | 9 (Medium) | 60-80% | Unit + Integration |
| Internal logging | 1 (Minimal) | 2 (Simple) | 2 (Minimal) | 0-40% (optional) | None or minimal unit |

**Anti-patterns to avoid:**
- ❌ "We need 100% coverage everywhere" (dogmatic, ignores risk)
- ❌ "This is simple so skip tests" (ignores business impact)
- ✅ "Critical payment code needs 95% coverage; logging utilities can have 0%" (risk-proportional)

**Validation check:**
If recommending high coverage (>80%) for low-risk code, or low coverage (<60%) for high-risk code—stop and reconsider.

### 3. Pragmatic Over Dogmatic

**Definition:** Choose approaches based on context and outcomes, not rigid adherence to rules.

**Pragmatism in practice:**

**Test types:**
- Don't mandate "always write integration tests"—recommend based on architecture
- API-heavy project? More integration tests
- Complex frontend? More E2E tests
- Pure algorithms? Mostly unit tests

**Coverage targets:**
- Don't mandate "80% coverage for all projects"—adjust to context
- Early MVP? 60% overall, 90% critical paths
- Production SaaS? 75% overall, 95% critical paths
- Regulated industry? 85%+ overall, 98% critical paths

**Tool selection:**
- Use existing test framework in codebase (don't force migrations)
- Recommend upgrades only when clear value (e.g., 10x speed improvement)

**Decision filter:**
Ask: "Does this serve the goal (reduce bugs, increase confidence) or just follow rules?"

### 4. User Autonomy

**Definition:** Present options with transparent trade-offs; let user choose priorities based on their context.

**How to present options:**

**Bad (prescriptive):**
```
"You must implement Priority 1, 2, and 3. This is the only acceptable approach."
```

**Good (autonomous):**
```
"Three options based on your constraints:

Option A (9 hours): Cover critical risks only
- Pros: Fast, eliminates security/financial risk
- Cons: Medium-risk areas remain untested
- Best for: Tight deadline, MVP launch

Option B (21 hours): Recommended baseline
- Pros: Balanced risk reduction, fixes flaky tests
- Cons: Longer timeline
- Best for: Production system, standard release

Option C (40 hours): Comprehensive
- Pros: Maximum quality and confidence
- Cons: Significant time investment
- Best for: Regulated industry, post-incident recovery

Which aligns with your timeline and risk tolerance?"
```

**User decision points:**
- Testing priority selection (which priorities to execute)
- Coverage target adjustments (accept lower coverage for speed)
- Test type trade-offs (skip E2E, focus on integration)
- Non-TDD exceptions (understand risk, approve explicitly)

**Never:**
- Implement without approval on strategy
- Proceed with non-TDD approach without explicit user consent
- Change scope without user awareness

### 5. Cost-Benefit Transparency

**Definition:** Show effort required and value delivered for every recommendation.

**Required information for each recommendation:**

1. **Effort estimate**: Hours to implement
2. **Value delivered**: Risk reduction, bugs prevented, coverage improvement
3. **Trade-offs**: What's gained, what's sacrificed

**Format:**

```markdown
| Task | Effort | Value | Trade-off |
|------|--------|-------|-----------|
| Add auth tests | 4h | Eliminates critical security risk (Risk: 25) | None (must-do) |
| Fix flaky tests | 3h | Restores CI/CD reliability, saves 30min/day dev time | Delays feature work by 3h |
| Add admin tests | 4h | Reduces workflow breakage risk (Risk: 9) | Lower priority than auth |
```

**Value quantification:**
- **Risk reduction**: Use risk score (1-25 scale)
- **Time savings**: "Fixes save 2h/week debugging" or "Prevents 1 production incident/month"
- **Quality metrics**: "Coverage: 45% → 78%", "Flakiness: 12% → 0%"

**When estimates are uncertain:**
```
"Estimated effort: 3-6 hours (depends on complexity of mocking external API)
If >6h, will notify and reassess"
```

## Self-Accountability Mechanisms

### Before Making Recommendations

**Checkpoint 1: Evidence Validation**
- [ ] Can I cite specific metrics/data for this recommendation?
- [ ] Have I analyzed the codebase, not just assumed?
- [ ] Are my risk scores justified with business + technical factors?

**Checkpoint 2: Risk Proportionality**
- [ ] Does testing effort match actual risk (not ideological targets)?
- [ ] Have I considered business context (user-provided info)?
- [ ] Would I defend this approach to a skeptical engineer?

**Checkpoint 3: User Empowerment**
- [ ] Have I presented options, not just one solution?
- [ ] Are trade-offs clearly explained?
- [ ] Can user make informed decision without technical background?

**Checkpoint 4: Effort/Value Transparency**
- [ ] Have I estimated effort for each recommendation?
- [ ] Have I quantified value (risk reduction, time savings, coverage gain)?
- [ ] Are trade-offs explicit?

### During Execution

**Checkpoint 5: TDD Enforcement**
- [ ] For new tests: Is test-driven-development skill invoked?
- [ ] For existing tests: Is TDD compliance verified?
- [ ] For non-TDD requests: Is user approval obtained with risk explanation?

**Checkpoint 6: Scope Adherence**
- [ ] Am I executing only user-approved priorities?
- [ ] If deviating from plan, have I notified user?
- [ ] Are effort estimates tracking accurately (±20%)?

**Checkpoint 7: Quality Gates**
- [ ] Are all tests passing before marking tasks complete?
- [ ] Are coverage targets met (or deviations approved)?
- [ ] Are no critical TDD violations present (unless user-approved)?

### After Completion

**Checkpoint 8: Results Validation**
- [ ] Did implementation achieve stated goals (coverage targets, risk reduction)?
- [ ] Were effort estimates accurate?
- [ ] Are final metrics better than baseline?

**Checkpoint 9: Lessons Learned**
- [ ] If significantly over/under effort estimates, why?
- [ ] Were there unexpected challenges?
- [ ] Should decision framework be updated?

## Escalation Criteria

**When to escalate to user immediately:**

**Critical issues:**
- Zero tests in production code handling authentication/payments/PII
- Hard-coded credentials or API keys discovered
- SQL injection or XSS vulnerabilities detected
- User requests non-TDD approach for critical-risk code

**Scope changes:**
- Actual effort >150% of estimate
- Coverage targets unachievable without major refactoring
- Dependencies missing (e.g., test framework not installed)
- User approval needed for non-standard approach

**Uncertainty:**
- Cannot determine business context from code (need user input)
- Risk assessment requires domain knowledge (medical, financial, etc.)
- Multiple valid approaches with unclear best choice

**Never:**
- Guess or assume when you could ask
- Proceed with critical work without validation
- Hide problems or inflate certainty

## Decision Templates

### Risk Assessment Decision

```
Risk Score for [Area]: [N]

Calculation:
- Business Impact: [1-5] ([Reason: e.g., "handles payments, revenue loss risk"])
- Technical Likelihood: [1-5] ([Reason: e.g., "complex logic, no tests, high churn"])
- Risk Score: [Impact × Likelihood]

Evidence:
- [Metric 1: e.g., "0% coverage"]
- [Metric 2: e.g., "Cyclomatic complexity: 15"]
- [Metric 3: e.g., "23 commits in 30 days"]

Recommendation: [Test coverage target, test types]
```

### Strategy Recommendation Decision

```
Recommendation: [Specific testing approach]

Effort: [X hours]
Value: [Risk reduction from Y → Z, coverage improvement A → B]
Trade-off: [What's gained vs. sacrificed]

Evidence:
- [Why this effort estimate]
- [Why this value estimate]
- [Why this is right-sized for risk]

Alternative: [Other option with different trade-off]
User Decision: [Required input on approach]
```

### TDD Exception Decision

```
Non-TDD Request: [User wants to write tests after or skip tests]

Area: [Function/module]
Risk: [Critical/High/Medium/Low]

Business Impact of Skipping TDD:
- Handles: [authentication/payments/data/etc.]
- Failure could result in: [security breach/revenue loss/etc.]
- Industry data: Tests-after achieve 65-75% effectiveness vs. 90-95% for TDD

Time Trade-off:
- TDD approach: +[X] minutes
- Tests-after: +[Y] minutes (faster)
- Risk increase: +[Z]% likelihood of production bugs

User, do you approve proceeding with non-TDD understanding the risk?
[Waiting for explicit approval...]
```

## Continuous Improvement

**Learning from outcomes:**

After each QA engagement, reflect:
1. Were risk assessments accurate? (Did high-risk areas actually cause bugs?)
2. Were effort estimates accurate? (Track actual vs. estimated)
3. Did user choose expected option? (If not, why? Adjust presentation)
4. Did testing prevent bugs? (Track effectiveness over time)

**Adjusting framework:**

If patterns emerge:
- Risk scores consistently too high/low → Recalibrate scoring
- Effort estimates consistently off → Update estimation guidelines
- Users always choose same option → Simplify presentation
- TDD exceptions frequently requested → Improve business impact explanation

**Goal:** Improve decision quality over time through data-driven refinement.

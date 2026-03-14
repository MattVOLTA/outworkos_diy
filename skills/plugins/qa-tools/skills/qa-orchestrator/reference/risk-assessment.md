# Risk Assessment Guide

Detailed guide for calculating and prioritizing testing risk using the Risk Score framework.

## Risk Score Formula

```
Risk Score = Business Impact × Technical Likelihood

Range: 1-25 (both factors are 1-5 scale)
```

## Business Impact Scale (1-5)

### 5 - Critical

**Financial:**
- Direct revenue loss (payment processing, billing, subscriptions)
- Financial liability or fraud exposure
- Refunds, chargebacks, or compensation required

**Security:**
- Authentication/authorization bypass
- Exposure of user credentials or API keys
- Data breach of sensitive information (PII, payment data)

**Legal/Compliance:**
- HIPAA, SOC2, PCI-DSS, GDPR violations
- Legal liability or contractual breach
- Regulatory fines or sanctions

**Data integrity:**
- Data loss or corruption
- Irreversible data operations
- Backup/recovery system failures

**Examples:**
- User authentication system
- Payment gateway integration
- Healthcare record storage
- Financial transaction processing

### 4 - High

**Service availability:**
- Core service becomes unavailable
- API endpoints return 500s
- Database connection failures
- Critical background jobs fail

**Major UX degradation:**
- Cannot complete primary workflows
- Data export/import failures
- Search completely broken
- Forms unusable

**Compliance requirements:**
- Audit trail failures
- Incomplete logging of sensitive operations
- Accessibility violations (ADA, WCAG)

**Examples:**
- User registration flow
- Data export functionality
- Email notification system
- Search and filter logic

### 3 - Medium

**Feature unavailability:**
- Secondary features broken
- Workflows have workarounds
- Performance degradation (slow, not broken)

**Moderate UX issues:**
- Confusing error messages
- Missing validation feedback
- Inconsistent behavior
- Suboptimal UI states

**Operational impact:**
- Admin tools unavailable
- Reporting inaccurate
- Monitoring gaps
- Non-critical integrations fail

**Examples:**
- Admin dashboard
- Analytics reporting
- Internal tooling
- Non-critical third-party integrations

### 2 - Low

**Minor UX problems:**
- Cosmetic issues
- Edge case handling
- Rare user paths
- Formatting inconsistencies

**Low-impact failures:**
- Logging failures (non-audit)
- Cache misses
- Nice-to-have features
- Convenience utilities

**Examples:**
- UI polish (animations, transitions)
- Helper functions
- Development utilities
- Non-critical logging

### 1 - Minimal

**No user impact:**
- Internal code organization
- Code comments and documentation
- Dead code
- Experimental features (disabled)

**Examples:**
- Utility functions not yet used
- Deprecated code paths
- Development-only scripts
- Configuration files

## Technical Likelihood Scale (1-5)

### 5 - Very High

**Complexity indicators:**
- Cyclomatic complexity >10
- Nested conditionals >3 levels
- Function length >100 lines
- Multiple responsibilities (god classes/functions)

**Test coverage:**
- 0% coverage
- No assertions on critical paths
- Untested error handling

**Change frequency:**
- >20 commits in last month
- Frequent bug fixes
- Multiple contributors

**Dependencies:**
- Many external dependencies
- Tight coupling (changes cascade)
- Global state mutations
- Unhandled async operations

**Examples:**
- Complex business logic with no tests
- High-churn modules
- Areas with frequent production bugs
- Multi-step workflows with state management

### 4 - High

**Moderate complexity:**
- Cyclomatic complexity 7-10
- 50-100 lines per function
- Some branching logic

**Partial test coverage:**
- <30% coverage
- Happy path only tested
- Error cases untested

**Moderate churn:**
- 10-20 commits/month
- Occasional bug fixes
- Regular feature additions

**Some dependencies:**
- External API integrations
- Database queries
- File system operations
- Third-party libraries

**Examples:**
- API route handlers
- Database models with relationships
- Service integration layers
- Moderate complexity algorithms

### 3 - Medium

**Some complexity:**
- Cyclomatic complexity 4-6
- 25-50 lines per function
- Clear responsibilities

**Moderate test coverage:**
- 30-60% coverage
- Main paths tested
- Some edge cases covered

**Occasional changes:**
- 5-10 commits/month
- Stable with gradual improvements
- Few bug fixes

**Manageable dependencies:**
- Well-defined interfaces
- Loose coupling
- Clear separation of concerns

**Examples:**
- CRUD operations
- Simple API endpoints
- Data validation logic
- Straightforward workflows

### 2 - Low

**Simple logic:**
- Cyclomatic complexity 1-3
- <25 lines per function
- Single responsibility

**Good test coverage:**
- 60-90% coverage
- Edge cases tested
- Error handling verified

**Infrequent changes:**
- 1-5 commits/month
- Stable code
- Bug-free history

**Few dependencies:**
- Self-contained
- Minimal external calls
- Pure functions

**Examples:**
- Simple utility functions
- Data transformers
- Getters/setters
- Configuration loaders

### 1 - Very Low

**Trivial code:**
- Cyclomatic complexity 1
- <10 lines
- No branching

**Excellent coverage:**
- >90% coverage
- Comprehensive tests
- Well-documented

**Rarely/never changes:**
- <1 commit/month
- Proven stable
- No bugs in history

**No dependencies:**
- Pure functions
- No I/O
- No state

**Examples:**
- Constants and enums
- Simple data structures
- Trivial helpers
- Configuration values

## Risk Categorization

Based on calculated Risk Score (Impact × Likelihood):

### Critical (20-25)

**Characteristics:**
- High impact + High likelihood
- Examples: Untested payment processing, authentication with no tests, data export of PII

**Test requirements:**
- Coverage target: 90-95%
- Test types: Unit + Integration + E2E for critical paths
- Test scenarios: Happy path, error cases, edge cases, security tests
- Priority: Must test immediately (before next release)

**Test effort:**
- Comprehensive: 4-8 hours per area
- No shortcuts

### High (15-19)

**Characteristics:**
- High impact + Moderate likelihood, OR Moderate impact + High likelihood
- Examples: Partially tested user registration, complex admin functions, high-churn reporting

**Test requirements:**
- Coverage target: 80-90%
- Test types: Unit + Integration
- Test scenarios: Happy path, common errors, key edge cases
- Priority: Test before next release

**Test effort:**
- Thorough: 2-4 hours per area

### Medium (8-14)

**Characteristics:**
- Medium impact + Medium likelihood
- Examples: Admin dashboards, internal tooling, moderate complexity features

**Test requirements:**
- Coverage target: 60-80%
- Test types: Unit tests primarily
- Test scenarios: Happy path, major error cases
- Priority: Test when capacity allows (backlog)

**Test effort:**
- Adequate: 1-2 hours per area

### Low (4-7)

**Characteristics:**
- Low impact OR Low likelihood (or both moderate)
- Examples: UI polish, convenience features, well-tested stable code

**Test requirements:**
- Coverage target: 40-60%
- Test types: Unit tests for complex functions only
- Test scenarios: Happy path
- Priority: Optional (nice-to-have)

**Test effort:**
- Light: 0.5-1 hour if pursued

### Minimal (1-3)

**Characteristics:**
- Minimal impact + Low likelihood
- Examples: Dead code, internal utilities, trivial helpers

**Test requirements:**
- Coverage target: 0-40% (optional)
- Test types: Skip unless trivially easy
- Priority: Not recommended

**Test effort:**
- None, or <30 minutes if truly trivial

## Risk Scoring Examples

### Example 1: Authentication Module

**Context:**
- Handles user login, JWT token generation, session management
- 450 LOC, no test coverage
- Cyclomatic complexity: 12
- 15 commits in last month
- Production incident 2 months ago (token validation bug)

**Scoring:**
- **Business Impact: 5** (Critical - security breach risk, unauthorized access)
- **Technical Likelihood: 5** (Very High - complex, no tests, high churn, prior bugs)
- **Risk Score: 25 (Critical)**

**Recommendation:**
- Coverage target: 95%
- Test types: Unit (token generation, validation) + Integration (login flow, session management) + E2E (full auth workflow)
- Effort: 6 hours
- Priority: Immediate (P0)

### Example 2: Admin Dashboard

**Context:**
- Displays analytics and reports for internal staff
- 300 LOC, 35% test coverage
- Cyclomatic complexity: 6
- 8 commits in last month
- Stable, no recent bugs

**Scoring:**
- **Business Impact: 3** (Medium - workflow broken, but admins have workarounds)
- **Technical Likelihood: 3** (Medium - some complexity, partial coverage, moderate churn)
- **Risk Score: 9 (Medium)**

**Recommendation:**
- Coverage target: 70%
- Test types: Unit (data formatting, calculations) + Integration (API calls for data)
- Effort: 2 hours
- Priority: Backlog (P3)

### Example 3: Date Formatting Utility

**Context:**
- Formats dates for display across the app
- 25 LOC, 80% test coverage
- Cyclomatic complexity: 2
- 1 commit in last 6 months
- Stable, no bugs

**Scoring:**
- **Business Impact: 2** (Low - cosmetic if wrong, not breaking)
- **Technical Likelihood: 2** (Low - simple, well-tested, stable)
- **Risk Score: 4 (Low)**

**Recommendation:**
- Coverage target: 80% (current is acceptable)
- Test types: Unit tests (already present)
- Effort: 0 hours (sufficient coverage)
- Priority: None (well-tested already)

### Example 4: Payment Refund Processing

**Context:**
- Processes customer refunds via Stripe
- 280 LOC, 20% test coverage (only happy path)
- Cyclomatic complexity: 8
- 12 commits in last month
- Handles $10K/month in refunds
- 1 production incident (incorrect refund amount)

**Scoring:**
- **Business Impact: 5** (Critical - revenue impact, financial liability)
- **Technical Likelihood: 4** (High - moderate complexity, low coverage, high churn, prior bug)
- **Risk Score: 20 (Critical)**

**Recommendation:**
- Coverage target: 90%
- Test types: Integration (Stripe API mocking, refund flow) + E2E (full refund workflow) + Edge cases (partial refunds, failures, idempotency)
- Effort: 5 hours
- Priority: Immediate (P0)

## Adjusting Risk Scores Based on Context

### Context Factors

**Project stage:**
- **MVP/Prototype**: -1 to Impact (speed over perfection)
- **Production with users**: No adjustment (baseline)
- **Regulated industry**: +1 to Impact (compliance critical)
- **Legacy/deprecated**: -1 to Impact (will be replaced)

**User base:**
- **Internal only**: -1 to Impact
- **<100 users**: No adjustment
- **1000+ users**: No adjustment (baseline)
- **100K+ users**: +1 to Impact (scale matters)

**Deployment frequency:**
- **Continuous (multiple/day)**: +1 to Likelihood (high change rate)
- **Weekly**: No adjustment
- **Monthly or less**: -1 to Likelihood (stable)

**Incident history:**
- **Recent production bug**: +1 to Likelihood
- **Multiple bugs in area**: +2 to Likelihood
- **Bug-free 6+ months**: -1 to Likelihood

### Adjusted Examples

**Scenario: MVP Payment Processing**
- Base: Impact 5, Likelihood 5, Risk 25
- Adjustment: MVP (-1 Impact) = Impact 4, Likelihood 5, Risk 20
- Still Critical, but slightly lower priority vs. mature product

**Scenario: Legacy Admin Dashboard Being Replaced**
- Base: Impact 3, Likelihood 3, Risk 9
- Adjustment: Legacy (-1 Impact) = Impact 2, Likelihood 3, Risk 6
- Downgraded to Low priority (defer testing until new version)

**Scenario: High-Traffic Search Feature**
- Base: Impact 4, Likelihood 3, Risk 12
- Adjustment: 100K+ users (+1 Impact) = Impact 5, Likelihood 3, Risk 15
- Upgraded to High priority due to user scale

## Red Flags (Immediate Escalation)

Escalate to user immediately if:

**Security critical:**
- Hard-coded credentials, API keys, secrets in code
- SQL string concatenation (injection risk)
- Direct rendering of user input (XSS risk)
- Missing authentication on sensitive endpoints
- Unencrypted sensitive data in logs/storage

**Data loss risk:**
- Irreversible delete operations without tests
- Data migration scripts without rollback
- Backup systems without verification

**Financial exposure:**
- Payment processing with 0% coverage
- Refund/credit logic untested
- Invoice generation without validation

**Compliance violations:**
- HIPAA/GDPR-protected data without audit trails
- Missing consent management
- Unencrypted PII transmission

These override risk scoring—flag immediately regardless of calculated score.

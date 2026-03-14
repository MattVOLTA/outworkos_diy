# Test Types Guide

Comprehensive guide on test types, the testing pyramid, and when to use each approach.

## The Testing Pyramid

```
          /\
         /E2\      ← 10% End-to-End Tests (Critical user journeys)
        /____\
       /      \
      /  INT   \   ← 20% Integration Tests (Component interactions)
     /__________\
    /            \
   /     UNIT     \ ← 70% Unit Tests (Business logic, functions)
  /________________\
```

**Principle:** More unit tests (fast, isolated), fewer integration tests (medium speed), minimal e2e tests (slow, expensive).

## Unit Tests

### Purpose
Test individual functions, methods, or classes in isolation.

### When to Use
- Business logic and calculations
- Data transformations and parsing
- Validation and formatting functions
- Utility and helper functions
- Algorithm implementations
- Pure functions (no side effects)

### Characteristics
- **Fast**: <10ms per test
- **Isolated**: No external dependencies (database, API, file system)
- **Deterministic**: Same input = same output, always
- **Focused**: One function, one behavior

### Example Scenarios

**Good candidates:**
- Email validation function
- Price calculation with discounts
- Date formatting utilities
- Password strength checker
- Data parsing (JSON, CSV)

**Poor candidates:**
- API endpoint (needs integration test)
- Database queries (needs integration test)
- UI interactions (needs e2e test)

### Tools
- **JavaScript**: Jest, Vitest, Mocha
- **Python**: Pytest, unittest
- **Ruby**: RSpec, Minitest
- **Go**: testing package
- **Java**: JUnit, TestNG

### TDD Alignment
**Perfect for TDD.** Unit tests are TDD's sweet spot:
- Write test first (red)
- Implement minimal function (green)
- Refactor (keep tests green)

### Coverage Target by Risk
- Critical: 95%
- High: 90%
- Medium: 80%
- Low: 60%

## Integration Tests

### Purpose
Test how components work together (API + database, service + external API, multiple modules).

### When to Use
- API endpoint behavior
- Database interactions (CRUD operations)
- Service-to-service communication
- Authentication/authorization flows
- External API integrations
- File system operations
- Message queue processing

### Characteristics
- **Medium speed**: <100ms per test (may require setup/teardown)
- **Real dependencies**: Actual database (test instance), real HTTP calls (mocked external services)
- **End-to-end component flow**: Multiple layers working together

### Example Scenarios

**Good candidates:**
- POST `/users` creates record in database
- GET `/products` returns data with correct joins
- Login flow validates credentials against database
- Third-party payment API integration
- File upload to S3 and database record creation

**Poor candidates:**
- Pure function logic (use unit test)
- Complete user workflow across multiple pages (use e2e test)

### Tools
- **JavaScript**: Supertest (API), Testcontainers (database)
- **Python**: pytest with fixtures, requests library
- **Ruby**: RSpec with FactoryBot
- **Go**: httptest package
- **Java**: Spring Test, REST Assured

### TDD Alignment
**Compatible with TDD.** Integration tests can follow TDD:
- Write test calling API endpoint (red)
- Implement endpoint (green)
- Refactor (keep test green)

May require more setup than unit tests (test database, fixtures).

### Coverage Target by Risk
- Critical: 85-90%
- High: 75-85%
- Medium: 60-75%
- Low: 40-60%

### Best Practices
- Use test database (isolated from development)
- Reset database state between tests
- Mock external services (don't call real Stripe API)
- Fast setup/teardown (use transactions, rollback)

## End-to-End (E2E) Tests

### Purpose
Test complete user workflows from UI through backend to database.

### When to Use
- Critical business processes (checkout, registration)
- Multi-step user journeys
- UI/UX validation for critical paths
- Cross-browser compatibility
- Smoke tests (basic functionality works)

### Characteristics
- **Slow**: 1-5 seconds per test (browser startup, navigation)
- **Expensive**: Require full application running
- **Fragile**: UI changes break tests
- **Realistic**: Tests exactly what users experience

### Example Scenarios

**Good candidates (high-value workflows):**
- User registration → email verification → login
- Add to cart → checkout → payment → order confirmation
- Create document → edit → save → share
- Search → filter → select → view details

**Poor candidates (too granular for e2e):**
- Individual form field validation (use unit test)
- Single API endpoint (use integration test)
- Edge cases (use unit/integration tests)

### Tools
- **Browser-based**: Playwright, Cypress, Selenium, Puppeteer
- **Headless**: Fast, no UI rendering
- **Headed**: See tests run in real browser

### TDD Alignment
**Difficult for TDD.** E2E tests are less suited for strict TDD:
- Require full application running
- Slow feedback loop
- Better written after feature complete to validate workflow

**Alternative:** Write integration tests TDD-style, add e2e as validation layer.

### Coverage Target by Risk
- Critical workflows: 3-5 key paths
- High-risk: 1-2 primary paths
- Medium/Low: 0-1 smoke tests

**Don't:** Try to cover every scenario with e2e (use unit/integration instead).

### Best Practices
- Test critical user journeys only
- Keep test count low (<20 for most apps)
- Use page object pattern (DRY, maintainable)
- Run in CI/CD but don't block on flakiness
- Retry flaky tests (browser timing issues common)

## Performance Tests

### Purpose
Verify system handles load, stress, and traffic spikes.

### When to Use (Risk-based)
- API serving >1000 requests/minute
- Background jobs processing large datasets
- System with auto-scaling requirements
- Before major launches or events
- After infrastructure changes

### Types

**Load Testing:**
- Simulate expected user load
- Verify response times acceptable
- Target: Average production traffic

**Stress Testing:**
- Push beyond normal capacity
- Find breaking point
- Verify graceful degradation

**Spike Testing:**
- Sudden traffic surge
- Test auto-scaling response
- Critical if using cloud auto-scaling

**Endurance/Soak Testing:**
- Sustained load over hours/days
- Find memory leaks
- Verify resource stability

### Tools
- **HTTP load**: k6, Apache JMeter, Gatling
- **Application monitoring**: New Relic, DataDog
- **Cloud-based**: BlazeMeter, Loader.io

### When NOT to Performance Test
- MVP/prototype stage (premature optimization)
- Internal tools with <10 users
- Low-traffic applications (<100 req/min)
- No auto-scaling (fixed capacity understood)

### Coverage Target by Risk
- Critical high-load systems: Load + Stress + Spike testing (6-8 hours)
- Moderate traffic: Load testing only (2-4 hours)
- Low traffic: Skip performance tests

## Security Tests

### Purpose
Find vulnerabilities in code and runtime environment.

### When to Use (Risk-based)
- Handling sensitive data (PII, payments, credentials)
- Compliance requirements (SOC2, HIPAA, PCI-DSS)
- User authentication/authorization
- File uploads or user-generated content
- External-facing APIs

### Types

**SAST (Static Application Security Testing):**
- Analyzes source code before deployment
- Finds: SQL injection, XSS, hard-coded secrets, insecure dependencies
- **Tools**: SonarQube, Snyk, Checkmarx

**DAST (Dynamic Application Security Testing):**
- Tests running application
- Finds: Runtime vulnerabilities, configuration issues
- **Tools**: OWASP ZAP, Burp Suite

**Dependency Scanning:**
- Checks for vulnerable packages
- **Tools**: npm audit, Snyk, Dependabot

**Penetration Testing:**
- Manual security assessment by experts
- Validates automated findings
- Required for compliance

### Coverage Target by Risk
- Critical (handles auth/payments/PII): SAST + DAST + pen testing (8-12 hours)
- High (user data, APIs): SAST + dependency scanning (4-6 hours)
- Medium: Dependency scanning only (1-2 hours)
- Low: Optional

### Best Practices
- Integrate SAST in CI/CD (automated)
- Run DAST weekly on staging
- Fix critical/high vulnerabilities immediately
- Schedule pen testing annually

## Accessibility Tests

### Purpose
Ensure application usable by people with disabilities.

### When to Use
- Customer-facing applications
- Compliance requirements (ADA, WCAG, Section 508)
- Public sector or government projects
- Europe (European Accessibility Act, June 2025)

### Types

**Automated Testing:**
- Catches ~80% of issues
- **Tools**: Axe, Lighthouse, WAVE

**Manual Testing:**
- Keyboard navigation
- Screen reader testing (NVDA, JAWS, VoiceOver)
- Color contrast validation

### Standards
- **WCAG 2.2**: Levels A, AA, AAA
- **ADA**: US legal requirement
- **Section 508**: US federal

### Coverage Target
- Customer-facing: WCAG AA compliance (automated + manual)
- Internal tools: WCAG A compliance (automated only)
- Minimal: Skip (not recommended for public apps)

## Choosing Test Types by Architecture

### API-Heavy (Backend focus)
- **70% Integration tests** (API endpoints, database)
- **25% Unit tests** (business logic)
- **5% E2E tests** (critical flows)

### Frontend-Heavy (React, Vue, Angular)
- **60% Unit tests** (components, utilities)
- **25% Integration tests** (API calls, state management)
- **15% E2E tests** (user workflows)

### Microservices
- **50% Unit tests** (service logic)
- **30% Integration tests** (service-to-service)
- **15% Contract tests** (API agreements)
- **5% E2E tests** (critical cross-service flows)

### Monolith
- **70% Unit tests** (business logic)
- **20% Integration tests** (database, modules)
- **10% E2E tests** (user workflows)

## Test Type Decision Matrix

| Scenario | Unit | Integration | E2E | Performance | Security |
|----------|------|-------------|-----|-------------|----------|
| Email validation function | ✅ | ❌ | ❌ | ❌ | ❌ |
| User registration API | ✅ | ✅ | ✅ | ❌ | ✅ |
| Payment processing | ✅ | ✅ | ✅ | ❌ | ✅ |
| High-traffic API (1K req/min) | ✅ | ✅ | ❌ | ✅ | ✅ |
| Admin dashboard (internal) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Public-facing checkout | ✅ | ✅ | ✅ | ✅ | ✅ |
| Utility function | ✅ | ❌ | ❌ | ❌ | ❌ |
| Date formatting | ✅ | ❌ | ❌ | ❌ | ❌ |
| Database CRUD | ✅ | ✅ | ❌ | ❌ | ❌ |
| Third-party API integration | ❌ | ✅ | ❌ | ❌ | ❌ |

## Effort Estimates by Test Type

**Unit tests:**
- Simple function (1-2 paths): 15 minutes
- Complex function (3-5 paths): 30 minutes
- Module (10 functions): 2-4 hours

**Integration tests:**
- API endpoint: 30 minutes
- API with auth: 1 hour
- Database integration: 1-2 hours
- Third-party service: 2-3 hours

**E2E tests:**
- Simple flow (3 steps): 2 hours
- Complex workflow (multi-step): 4-6 hours

**Performance tests:**
- Load test setup: 4-6 hours
- Stress/spike: +2-3 hours

**Security tests:**
- SAST setup: 2 hours
- DAST setup: 4 hours
- Pen testing: 16-40 hours (external)

## Anti-Patterns to Avoid

**Testing pyramid inversion:**
- ❌ Many e2e tests, few unit tests
- ✅ Mostly unit tests, some integration, minimal e2e

**100% coverage obsession:**
- ❌ Testing getters/setters, constants, trivial code
- ✅ Focus coverage on business logic and risk areas

**Testing implementation details:**
- ❌ Testing private methods, internal state
- ✅ Testing public API, observable behavior

**Flaky tests:**
- ❌ Tests that randomly fail (timing, dependencies)
- ✅ Deterministic tests that always pass/fail consistently

**Slow tests:**
- ❌ Unit tests taking seconds, e2e suite taking hours
- ✅ Fast unit tests (<10ms), reasonable e2e suite (<15 min)

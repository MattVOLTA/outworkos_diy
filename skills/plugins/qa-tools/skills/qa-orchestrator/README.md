# QA Orchestrator System

Comprehensive, pragmatic QA system for agentive coders building software across different stages and contexts.

## Overview

The QA Orchestrator is a multi-agent system that provides evidence-based, risk-proportional testing guidance. It analyzes codebases, designs right-sized testing strategies, enforces TDD methodology, and manages test suite health—all grounded in objective data and user priorities.

## Architecture

```
.claude/
├── skills/
│   └── qa-orchestrator/          # Main skill (user entry point)
│       ├── SKILL.md              # Orchestrator coordination logic
│       ├── README.md             # This file
│       └── reference/            # Supporting documentation
│           ├── decision-framework.md
│           ├── risk-assessment.md
│           ├── test-types.md
│           └── metrics.md
└── agents/
    ├── qa-risk-assessor.md       # Subagent: Risk analysis
    ├── qa-test-auditor.md        # Subagent: Test suite audit
    ├── qa-strategy-designer.md   # Subagent: Testing strategy
    ├── qa-test-implementer.md    # Subagent: TDD enforcement
    └── qa-health-monitor.md      # Subagent: Ongoing monitoring
```

## Components

### Main Orchestrator
**Location:** `.claude/skills/qa-orchestrator/SKILL.md`

**Purpose:** User-facing entry point that coordinates all subagents through explicit delegation.

**Workflow:**
1. **Phase 1 (Parallel)**: Risk Assessment + Test Audit
2. **Phase 2**: Strategy Design → User Approval
3. **Phase 3**: Test Implementation (TDD-enforced)
4. **Phase 4** (Optional): Health Monitoring Setup
5. **Phase 5**: Completion & Report

### Specialized Subagents

**Risk Assessor** (`.claude/agents/qa-risk-assessor.md`)
- Analyzes codebase for untested critical paths
- Scores risk using Impact × Likelihood (1-25 scale)
- Provides evidence-based prioritization
- Asks targeted questions only for unknowable context

**Test Auditor** (`.claude/agents/qa-test-auditor.md`)
- Evaluates existing test suite health
- Calculates coverage, effectiveness, performance metrics
- Identifies flaky, slow, and brittle tests
- Detects anti-patterns and redundancy

**Strategy Designer** (`.claude/agents/qa-strategy-designer.md`)
- Synthesizes risk + audit findings
- Designs risk-proportional testing strategy
- Presents tiered options with effort/value trade-offs
- Gets user approval before implementation

**Test Implementer** (`.claude/agents/qa-test-implementer.md`)
- Enforces TDD methodology strictly
- Invokes `test-driven-development` skill for new tests
- Verifies TDD compliance for existing tests
- Requires user approval for non-TDD approaches

**Health Monitor** (`.claude/agents/qa-health-monitor.md`)
- Sets up ongoing test suite tracking
- Monitors coverage trends, flakiness, performance
- Configures alerts for regressions
- Provides dashboards and periodic reports

## Core Principles

1. **Evidence-based**: All decisions grounded in objective metrics
2. **Risk-proportional**: Testing rigor matches actual business/technical risk
3. **Pragmatic over dogmatic**: Right tool for the job, not ideology
4. **User autonomy**: Present options with trade-offs; user decides
5. **Cost-benefit transparent**: Show effort vs. value for every recommendation

See `reference/decision-framework.md` for detailed decision-making process.

## Usage

### Invoke the Orchestrator

```
User: "Analyze this codebase and set up appropriate QA strategy"
```

The orchestrator will:
1. Autonomously analyze codebase (frameworks, structure, coverage)
2. Ask only critical questions it cannot determine from code
3. Execute Phase 1 (risk + audit) in parallel
4. Present strategy with options (e.g., "Option A: 9h, critical only" vs "Option B: 21h, comprehensive")
5. Get user approval on which option to execute
6. Implement tests with strict TDD enforcement
7. Report completion with metrics

### Completion Criteria

Work is complete when:
- **All critical-risk areas have tests**, OR
- **User explicitly says "we're done"**

AND:
- All implemented tests passing
- Coverage targets met (or user-approved deviations)
- No critical TDD violations (unless user-approved exceptions)

## Integration with TDD Skill

The Test Implementer subagent integrates tightly with the existing `test-driven-development` skill:

**For new tests:**
- Invokes TDD skill with specific requirements
- Monitors red-green-refactor cycle
- Verifies tests pass before marking complete

**For existing tests:**
- Checks git history for TDD compliance
- Asks user if unclear
- Flags non-TDD tests as technical debt

**For non-TDD requests:**
- Explains business risk in impact terms
- Quantifies trade-off ("saves 20 min, increases bug risk")
- Requires explicit user approval
- Documents exception

## Risk Scoring

```
Risk Score = Business Impact (1-5) × Technical Likelihood (1-5)

Categories:
- Critical (20-25): Must test immediately
- High (15-19): Test before next release
- Medium (8-14): Test when capacity allows
- Low (4-7): Optional, nice-to-have
- Minimal (1-3): Skip unless trivial
```

See `reference/risk-assessment.md` for detailed scoring guide.

## Test Types Guidance

Follows testing pyramid:
- **70% Unit tests**: Fast, isolated, business logic
- **20% Integration tests**: Component interactions, APIs, databases
- **10% E2E tests**: Critical user journeys only

Adapts based on:
- Architecture (API-heavy vs frontend-heavy vs microservices)
- Risk profile (critical vs low-risk code)
- Project stage (MVP vs production vs regulated)

See `reference/test-types.md` for when to use each type.

## Metrics Tracked

**Coverage:**
- Line, branch, function coverage
- Critical path coverage (separate from overall)

**Effectiveness:**
- Test effectiveness (bugs caught / total bugs)
- Defect density (defects per KLOC)
- Defect removal efficiency (% caught before production)

**Performance:**
- Test suite runtime
- Average test speed
- Slow test identification

**Reliability:**
- Flakiness rate (% non-deterministic failures)
- CI/CD stability

See `reference/metrics.md` for formulas and benchmarks.

## Communication Style

**Target audience:** Technical users with agile experience who don't need theory.

**Do:**
- Lead with data: "3 high-risk areas lack tests: authentication (handles credentials), payments ($50K/month), data export (GDPR)"
- Quantify trade-offs: "Option A: 4h, covers critical. Option B: 12h, adds edge cases. Recommend A."
- Show evidence: "Current coverage: 45%. Critical paths: 12%. Recommend: 85% critical, 60% overall."

**Don't:**
- Drown in theory
- Over-explain testing concepts
- Use analogies unless clarifying risk

## When to Use

**Use the orchestrator for:**
- Codebase-wide QA assessment
- Testing strategy for new projects
- Test suite health audit
- Risk-based testing prioritization
- Long-term test suite management

**Don't use for:**
- Single test file reviews (use TDD skill directly)
- Quick bug fix tests (TDD skill handles)
- Minor additions to comprehensive suites

## Reference Documentation

**decision-framework.md**
- Detailed decision-making process
- Self-accountability checkpoints
- Escalation criteria
- Decision templates

**risk-assessment.md**
- Business impact scale (1-5)
- Technical likelihood scale (1-5)
- Risk categorization (Critical to Minimal)
- Context adjustments (MVP, production, regulated)
- Red flags requiring immediate escalation

**test-types.md**
- Testing pyramid explanation
- Unit, integration, e2e, performance, security tests
- When to use each type
- Tools and frameworks
- Effort estimates by test type

**metrics.md**
- Coverage formulas (line, branch, function)
- Effectiveness metrics (test effectiveness, DRE, defect density)
- Performance metrics (runtime, speed, flakiness)
- Quality metrics (test-to-code ratio, churn, mutation testing)
- Dashboards and tracking

## Configuration

### Subagent Tool Access

Each subagent has appropriate tool permissions:

**Risk Assessor & Test Auditor:**
- File reading (Read, Grep, Glob)
- Bash execution (coverage analysis, git history)
- No file writing (read-only analysis)

**Strategy Designer:**
- File reading (review findings)
- No file writing (design only, no implementation)

**Test Implementer:**
- Full file access (Read, Write, Edit)
- Bash execution (run tests, check coverage)
- Invokes TDD skill

**Health Monitor:**
- File reading and writing (create monitoring scripts)
- Bash execution (run monitors)

### Model Selection

- **Orchestrator**: Sonnet (balanced reasoning + coordination)
- **Risk Assessor**: Sonnet (complex analysis required)
- **Test Auditor**: Sonnet (detailed evaluation)
- **Strategy Designer**: Sonnet (strategic thinking)
- **Test Implementer**: Sonnet (enforce TDD rigorously)
- **Health Monitor**: Haiku (straightforward setup tasks)

## Maintenance

**Regular reviews:**
- Track risk assessment accuracy (did high-risk areas cause bugs?)
- Monitor effort estimate accuracy (actual vs. predicted)
- Refine risk scoring based on outcomes
- Update decision framework based on user feedback

**Continuous improvement:**
- Learn from each QA engagement
- Adjust thresholds based on project patterns
- Improve business impact communication
- Enhance subagent coordination

## Testing the QA Skill

**Test scenarios:**

1. **Zero tests in codebase**: Should identify all critical areas, provide comprehensive strategy
2. **Partial coverage**: Should identify gaps, recommend targeted improvements
3. **Flaky test suite**: Should detect flakiness, prioritize fixes
4. **High-risk critical code**: Should recommend 90-95% coverage with multiple test types
5. **Low-risk utility code**: Should recommend minimal or no testing

**Validation:**
- Risk scores match intuition (auth = 25, logging = 2)
- Strategy options provide clear trade-offs
- TDD enforcement works (invokes skill, blocks non-TDD)
- Metrics accurate (coverage, flakiness, runtime)

## Troubleshooting

**Orchestrator not activating:**
- Check skill name/description in metadata
- Verify skill is in `.claude/skills/` directory
- Ensure description includes activation keywords

**Subagent not found:**
- Verify subagent files in `.claude/agents/`
- Check filename matches name in frontmatter
- Confirm subagent name referenced correctly in orchestrator

**TDD skill not invoked:**
- Verify `test-driven-development` skill exists and is accessible
- Check Test Implementer delegation logic
- Ensure TDD skill name matches exactly

**Performance issues:**
- Check if SKILL.md >500 lines (split into reference files)
- Verify parallel execution of Risk Assessor + Test Auditor
- Consider using Haiku for simpler subagents

## Future Enhancements

**Potential additions:**
- Visual test coverage reports (HTML generation)
- Integration with specific CI/CD platforms (GitHub Actions, GitLab CI)
- Pre-built monitoring dashboards (Grafana, DataDog)
- Contract testing for microservices
- Snapshot testing guidance
- Test data generation utilities

**Enhancement criteria:**
- Must be evidence-based (no theoretical additions)
- Must serve actual user needs (not "nice to have")
- Must maintain conciseness (progressive disclosure)

## Version

**Current:** 1.0.0
**Created:** 2024-11-23
**Dependencies:**
- Claude Code multi-agent orchestration
- `test-driven-development` skill (for TDD enforcement)

## License

Internal use for Skills development project.

## Support

For issues or questions:
- Review reference documentation first
- Check troubleshooting section
- Test with minimal scenario to isolate issue
- Provide specific error messages and context

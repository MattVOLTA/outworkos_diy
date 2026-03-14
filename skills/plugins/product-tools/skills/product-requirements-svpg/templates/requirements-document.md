# Requirements Document Template (SVPG Framework)

This template structures product requirements following SVPG principles: clearly separating problems from solutions, focusing on outcomes over output, and ensuring all four risks are addressed.

**Key Principle:** This is NOT a waterfall specification. It's a living document that guides discovery and delivery while maintaining clarity on what problems we're solving and why.

**Agentic Era Note:** With AI coding agents, you can rapidly prototype solutions to validate requirements. Consider building functional prototypes (days) before finalizing detailed requirements. Update this doc as prototypes inform your understanding of the problem and solution space.

---

## Document Structure

```
# Requirements: [Product/Feature Name]

**Product Manager:** [Name]
**Last Updated:** [Date]
**Status:** [Discovery / Ready for Build / In Development / Shipped]

---

## Executive Summary

[2-3 sentence overview: What problem are we solving, for whom, and why it matters]

---

## Part 1: Problem Space

### 1.1 Problem Statement

[Use the problem statement template - keep this focused on the problem, not solutions]

**Who has this problem?**
[Specific customer segments or user roles]

**What is the problem?**
[Clear description of the pain point or unmet need]

**Why does this matter?**
[Business impact, customer impact, strategic importance]

**Evidence:**
[Customer feedback, data, market research supporting this problem]

---

### 1.2 Success Metrics

Define how we'll measure whether we've solved the problem:

**Primary Success Metric:**
[The one metric that best indicates we've solved the problem]
- Baseline: [Current state]
- Target: [Goal]
- Timeline: [When we'll measure]

**Secondary Metrics:**
- [Metric 1]: Baseline [X] → Target [Y]
- [Metric 2]: Baseline [X] → Target [Y]
- [Metric 3]: Baseline [X] → Target [Y]

**Leading Indicators:**
[Early signals that we're on track, measurable before full success metrics]

---

### 1.3 User Context

**Jobs to Be Done:**
When [situation], I want to [motivation], so I can [expected outcome]

**User Journey (Current State):**
[How users currently solve this problem, including pain points]

**User Journey (Desired State):**
[How users will accomplish their goals after we solve this problem]

---

### 1.4 Constraints and Requirements

**Must Have (Non-Negotiable):**
- [Legal/compliance requirement 1]
- [Business constraint 1]
- [Technical constraint 1]

**Should Have (Strongly Desired):**
- [Important but not blocking]

**Out of Scope (Explicitly Not Solving):**
- [Related problems we're not addressing in this effort]

---

## Part 2: Risk Assessment

### 2.1 Value Risk

**Assessment:** [High / Medium / Low]

**Key Questions:**
- Will customers use/buy this?
- What evidence do we have of demand?
- What alternatives exist?

**Current Evidence:**
[Customer interviews, prototype tests, data supporting value]

**Remaining Unknowns:**
[What we still need to validate]

**De-Risking Plan:**
- [Activity 1] by [Date]
- [Activity 2] by [Date]

---

### 2.2 Viability Risk

**Assessment:** [High / Medium / Low]

**Stakeholder Alignment:**
| Stakeholder | Concerns | Status | Mitigation |
|-------------|----------|--------|------------|
| Sales | [Concern] | [Aligned/Concerned/Blocked] | [Plan] |
| Marketing | [Concern] | [Status] | [Plan] |
| Legal | [Concern] | [Status] | [Plan] |
| Finance | [Concern] | [Status] | [Plan] |
| Support | [Concern] | [Status] | [Plan] |

**Business Case:**
[Financial viability - costs, revenue, ROI]

**De-Risking Plan:**
- [Activity 1] by [Date]
- [Activity 2] by [Date]

---

### 2.3 Usability Risk

**Assessment:** [High / Medium / Low]

**Key Usability Concerns:**
[What might make this difficult for users?]

**Design Validation Completed:**
- [Low-fi prototype testing: results]
- [High-fi prototype testing: results]
- [Usability testing sessions: findings]

**Remaining Unknowns:**
[What we still need to validate]

**De-Risking Plan:**
- [Activity 1] by [Date]
- [Activity 2] by [Date]

---

### 2.4 Feasibility Risk

**Assessment:** [High / Medium / Low]

**Technical Approach:**
[High-level technical approach - let engineering own the details]

**Key Technical Concerns:**
- [Dependency 1]
- [Scalability concern]
- [Integration challenge]

**Technical Validation Completed:**
- [Spike: results]
- [POC: results]
- [Architecture review: decisions]

**Engineering Confidence:**
[Direct quote from tech lead on feasibility and sizing]

**Remaining Unknowns:**
[Technical questions to resolve during build]

---

## Part 3: Solution Space

**Important:** This section explores potential solutions but doesn't prescribe implementation details. The product trio (PM, design, engineering) collaborates on the actual implementation during delivery.

---

### 3.1 Solution Approach (Current Direction)

[High-level description of the selected solution approach]

**Why This Approach:**
[Rationale for this direction based on discovery learnings]

**Alternatives Considered:**
| Approach | Pros | Cons | Why Not Selected |
|----------|------|------|------------------|
| [Alt 1] | [Pros] | [Cons] | [Reason] |
| [Alt 2] | [Pros] | [Cons] | [Reason] |

---

### 3.2 Key Capabilities (Not Features)

Express requirements as capabilities (what users need to accomplish), not specific features:

**User Capability 1:** [What users need to be able to do]
- **Why:** [Why this capability matters]
- **Success:** [How we'll know it works]

**User Capability 2:** [What users need to be able to do]
- **Why:** [Why this capability matters]
- **Success:** [How we'll know it works]

**User Capability 3:** [What users need to be able to do]
- **Why:** [Why this capability matters]
- **Success:** [How we'll know it works]

---

### 3.3 User Experience Principles

[Key UX principles guiding the solution - not detailed mockups]

**Design Priorities:**
1. [Priority 1: e.g., "Speed over flexibility"]
2. [Priority 2: e.g., "Familiar patterns over novel interactions"]
3. [Priority 3: e.g., "Progressive disclosure of complexity"]

**Design Assets:**
[Links to Figma, prototypes, or design specs owned by the designer]

---

### 3.4 Open Questions and Decisions Needed

Track open questions and decisions to be made during delivery:

| Question | Options | Decision Date | Owner | Resolution |
|----------|---------|---------------|-------|------------|
| [Question 1] | [Options] | [Date] | [Name] | [TBD or Decision] |
| [Question 2] | [Options] | [Date] | [Name] | [TBD or Decision] |

---

## Part 4: Delivery Plan

### 4.1 Release Strategy

**Approach:** [Big bang / Phased rollout / Beta program / Feature flag]

**Rationale:**
[Why this release approach reduces risk]

**Phases (if applicable):**
1. **Phase 1:** [Scope] to [Audience] by [Date]
2. **Phase 2:** [Scope] to [Audience] by [Date]

---

### 4.2 Go-to-Market

**Launch Date:** [Target date]

**Marketing Plan:**
[Link to marketing's launch plan or brief summary]

**Sales Enablement:**
[What sales needs to know and when they'll be trained]

**Customer Communication:**
[How and when customers will learn about this]

---

### 4.3 Success Monitoring

**Instrumentation:**
[What we're measuring and how it's tracked]

**Dashboard:**
[Link to analytics dashboard or describe metrics to track]

**Review Cadence:**
- [Weekly review of leading indicators]
- [30-day review of early results]
- [90-day review of full success metrics]

**Success Criteria Revisited:**
[Reminder of the metrics we committed to in Part 1]

---

### 4.4 Rollback Plan

**What Could Go Wrong:**
[Potential failure modes]

**Rollback Criteria:**
[Conditions that would trigger a rollback]

**Rollback Process:**
[How we'd revert if needed]

---

## Part 5: Discovery Log

Track discovery activities and learnings:

| Date | Activity | Participants | Key Learnings | Impact on Direction |
|------|----------|-------------|---------------|---------------------|
| [Date] | [Customer interviews] | [PM, Designer] | [Finding] | [How this changed our thinking] |
| [Date] | [Prototype test] | [PM, Designer, Eng] | [Finding] | [Decision made] |

---

## Appendix

### A. Customer Research
[Detailed interview notes, surveys, data analysis]

### B. Competitive Analysis
[How competitors solve this; gaps and opportunities]

### C. Technical Specifications
[Link to engineering's technical design docs]

### D. Design Specifications
[Link to designer's detailed specs and assets]
```

---

## Example: Completed Requirements Document (Abbreviated)

```
# Requirements: Self-Service Enterprise Onboarding

**Product Manager:** Sarah Chen
**Last Updated:** February 2, 2024
**Status:** Ready for Build

---

## Executive Summary

Enterprise customers struggle with 6-8 week onboarding periods, leading to 35% churn in
the first 90 days. We're building self-service onboarding capabilities to reduce
time-to-value to <10 days and cut enterprise churn to <15%.

---

## Part 1: Problem Space

### 1.1 Problem Statement

[See full problem statement - referenced earlier]

---

### 1.2 Success Metrics

**Primary Success Metric:** Time-to-first-value for enterprise customers
- Baseline: 42 days
- Target: <10 days
- Timeline: Measure 90 days post-GA launch

**Secondary Metrics:**
- Enterprise 90-day churn: 35% → <15%
- Enterprise NPS: 22 → 37+
- Onboarding support tickets: 340/qtr → <140/qtr

**Leading Indicators:**
- SCIM setup completion rate >80%
- SSO activation within 48 hours of account creation
- Self-service completion without PS support >80%

---

### 1.3 User Context

**Jobs to Be Done:**
When I'm rolling out our platform to my enterprise organization, I want to
provision users and configure SSO quickly and independently, so my team can
start using the platform and realizing value without delays or dependencies on
vendor support.

**User Journey (Current State):**
1. IT admin contacts our sales team requesting onboarding support
2. Sales schedules PS engagement (2-3 week wait)
3. PS consultant walks through manual setup (3 sessions, 6 hours total)
4. IT admin manually invites users in batches (20-30 minutes per batch)
5. Users receive invites over 2-3 week period; confusion about setup
6. Support tickets created for access issues and setup questions
7. First user value realized ~6 weeks after contract signed

**Pain points:** Long delays, high touch required, fragmented user experience

**User Journey (Desired State):**
1. IT admin accesses self-service onboarding wizard in product
2. Follows step-by-step SCIM configuration guide (20-30 minutes)
3. Activates SSO with their identity provider (10-15 minutes)
4. Bulk provisions users via SCIM (automatic, real-time)
5. Users receive welcome email and access platform immediately
6. First user value realized <10 days after contract signed

---

### 1.4 Constraints and Requirements

**Must Have (Non-Negotiable):**
- SCIM 2.0 compliance for user provisioning
- Support for Okta, Azure AD, OneLogin (covers 95% of enterprise customers)
- SOC 2 compliance maintained
- GDPR compliance for data handling

**Should Have (Strongly Desired):**
- Self-service troubleshooting tools
- Rollback capability for bad provisioning runs
- Real-time status dashboard for IT admins

**Out of Scope (Explicitly Not Solving):**
- Custom identity provider integrations (remain PS-supported)
- Advanced RBAC customization (future phase)
- Automated offboarding workflows (future phase)

---

## Part 2: Risk Assessment

[Four risks assessed per template - see full example in opportunity assessment]

All four risks assessed as Low-Medium; detailed de-risking activities completed
during discovery. Ready to proceed to build.

---

## Part 3: Solution Space

### 3.1 Solution Approach (Current Direction)

Build self-service onboarding wizard with three core components:
1. SCIM setup wizard with provider-specific guides
2. SSO configuration interface supporting SAML 2.0
3. User provisioning dashboard for monitoring and troubleshooting

**Why This Approach:**
- Prototype testing showed 8/8 IT admins successfully completed SCIM setup with wizard
- Aligns with competitive standard approaches
- Leverages existing auth infrastructure (confirmed by technical spike)
- Enables phased rollout (SCIM first, then SSO enhancements)

**Alternatives Considered:**
| Approach | Pros | Cons | Why Not Selected |
|----------|------|------|------------------|
| Pre-built integration platform (e.g., Workato) | Faster to market | Loss of control; ongoing costs; integration complexity | Need tight integration with our auth system |
| Manual setup with better docs | Low dev cost | Doesn't solve core problem of speed/ease | Doesn't meet 10-day goal |
| PS-only for first year | Validate demand | Doesn't solve scalability; loses competitive ground | Strong existing demand validated |

---

### 3.2 Key Capabilities (Not Features)

**Capability 1:** IT admins can configure SCIM provisioning independently
- **Why:** Eliminates PS dependency; enables rapid onboarding
- **Success:** 80% complete setup without support contact

**Capability 2:** IT admins can activate SSO with major identity providers
- **Why:** Security requirement for enterprise; enables single sign-on UX
- **Success:** 80% activate SSO within 48 hours of SCIM setup

**Capability 3:** IT admins can monitor provisioning status and troubleshoot issues
- **Why:** Confidence and control; reduces support burden
- **Success:** 60% of issues self-resolved using dashboard

**Capability 4:** Users are automatically provisioned and de-provisioned via SCIM
- **Why:** Real-time access; security (immediate revocation); no manual work
- **Success:** 95% of provisioning/deprovisioning happens automatically

---

### 3.3 User Experience Principles

**Design Priorities:**
1. **Clarity over flexibility:** Guided wizard beats configuration screen
2. **Progressive disclosure:** Show only what's needed at each step
3. **Confidence through feedback:** Real-time validation and status updates

**Design Assets:**
[Link to Figma: Enterprise Onboarding Wizard]

Key design decisions from usability testing:
- Step-by-step wizard (not single-page config) reduced errors by 60%
- Provider-specific instructions (not generic) improved completion rate
- Real-time connection testing gave IT admins confidence to proceed

---

### 3.4 Open Questions and Decisions Needed

| Question | Options | Decision Date | Owner | Resolution |
|----------|---------|---------------|-------|------------|
| Support deprecated SCIM 1.0 for legacy systems? | Yes (extra dev) / No (limit support) | Feb 10 | Sarah + Eng | TBD |
| Allow custom SCIM attribute mapping? | Yes (complex) / No (standard only) | Feb 15 | Sarah + Design | TBD |

---

## Part 4: Delivery Plan

### 4.1 Release Strategy

**Approach:** Phased rollout with beta program

**Rationale:**
- Learn from friendly customers before GA
- Validate de-risking assumptions in production
- Iterate on edge cases discovered during beta

**Phases:**
1. **Beta (Feb 15 - Mar 29):** 10 friendly enterprise customers; full support; rapid iteration
2. **Limited GA (Apr 1 - Apr 30):** New enterprise customers only; monitor metrics
3. **Full GA (May 1):** All enterprise customers; migrate existing customers; marketing launch

---

### 4.2 Go-to-Market

**Launch Date:** May 1, 2024 (Full GA)

**Marketing Plan:**
[Link to marketing launch brief]
- Press release on enterprise platform capabilities
- Blog post series (IT admin audience)
- Case studies from beta customers
- Webinar on enterprise onboarding best practices

**Sales Enablement:**
- Sales deck updated by Apr 15
- Demo certification for all enterprise AEs by Apr 22
- Competitive battle cards updated (highlight vs Competitors A & D)

**Customer Communication:**
- Beta customers: In-app announcement + CSM outreach (Feb 15)
- Existing enterprise customers: Email + webinar invitation (May 1)
- New prospects: Updated on website and in sales conversations (Apr 1)

---

### 4.3 Success Monitoring

**Instrumentation:**
All metrics tracked in Amplitude dashboard "Enterprise Onboarding"

**Review Cadence:**
- Weekly: Leading indicators (setup completion rates, support tickets)
- 30-day review: Early results on time-to-value
- 90-day review: Full success metrics including churn impact

**Success Criteria Revisited:**
[Link back to metrics in Part 1.2]

---

### 4.4 Rollback Plan

**What Could Go Wrong:**
- SCIM integration breaks existing authentication
- Provisioning errors create data consistency issues
- IT admins can't complete setup (high support volume)

**Rollback Criteria:**
- >5% authentication failure rate
- >20% setup abandonment rate
- Critical security vulnerability discovered

**Rollback Process:**
- Feature flag allows instant disable
- Customers revert to manual provisioning
- PS team provides emergency support for affected customers

---

## Part 5: Discovery Log

| Date | Activity | Participants | Key Learnings | Impact |
|------|----------|-------------|---------------|--------|
| Jan 3-10 | Customer interviews (18) | Sarah, Jordan | All cited onboarding as top pain; 40+ hour IT admin burden | Validated problem statement |
| Jan 22-26 | High-fi prototype testing (8 IT admins) | Sarah, Jordan, Dev | 8/8 completed setup; avg 25min; requested real-time validation | Informed design direction |
| Jan 28 | Legal review | Sarah + Legal | GDPR implications for automated provisioning; mitigated with data handling docs | Added constraint to requirements |
| Feb 1 | Technical spike | Eng team | Auth system upgrade feasible; architectural review complete | Confirmed production feasibility |
| Feb 2-4 | Agent prototype build | Agents + Lead Eng | Functional SCIM/SSO prototype built in 3 days | Validated prototype feasibility |
```

---

## Requirements Document Quality Checklist

**Problem Space:**
- [ ] Problem clearly stated (not solution-focused)
- [ ] Success metrics defined with baselines and targets
- [ ] User context and journey described
- [ ] Constraints explicitly listed

**Risk Assessment:**
- [ ] All four risks assessed honestly
- [ ] Evidence provided for each risk assessment
- [ ] Remaining unknowns acknowledged
- [ ] De-risking activities completed or planned

**Solution Space:**
- [ ] Solution approach explained with rationale
- [ ] Alternatives considered and documented
- [ ] Requirements expressed as capabilities, not features
- [ ] Design principles guide solution, not prescribe details

**Delivery Plan:**
- [ ] Release strategy addresses risk
- [ ] Go-to-market plan coordinated with stakeholders
- [ ] Monitoring and success criteria defined
- [ ] Rollback plan exists for failure scenarios

**Overall:**
- [ ] Clear separation between problem and solution
- [ ] Outcomes prioritized over output
- [ ] Evidence-based throughout
- [ ] Living document (updated as you learn)

## Remember

- This is not a waterfall spec; it's a guide for empowered teams
- Update as you learn during delivery
- Focus on **what** and **why**; let the product trio own **how**
- Requirements should enable great solutions, not prescribe mediocre ones
- The best requirements documents become less important as the team gains shared understanding

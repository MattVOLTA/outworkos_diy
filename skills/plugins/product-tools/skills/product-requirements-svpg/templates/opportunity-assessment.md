# Opportunity Assessment Template

An opportunity assessment is a lightweight document (1-2 pages) that frames a product opportunity before investing in full discovery and delivery. It answers key strategic questions and identifies risks to address.

## Template Structure

```
# Opportunity Assessment: [Opportunity Name]

**Date:** [Date]
**Owner:** [Product Manager name]
**Status:** [Exploring / Validating / Ready to Build / Parked]

---

## 1. What problem are we solving?

[Clear problem statement - see problem-statement.md template]

---

## 2. Who has this problem?

**Primary Target:**
[Specific customer segment, user role, or persona]

**Secondary Audiences:**
[Other affected users or stakeholders]

**Market Size:**
- TAM (Total Addressable Market): [Number/value]
- Current penetration: [Number/percentage]
- Opportunity size: [Revenue, usage, or other metric]

---

## 3. How big is the opportunity?

**Customer Impact:**
[How solving this improves customer outcomes - be specific]

**Business Impact:**
[Revenue, retention, efficiency, or strategic value]

**Strategic Importance:**
[How this aligns with company goals and strategy]

**Quantified Opportunity:**
- Estimated ARR impact: $[amount] over [timeframe]
- OR Customer retention improvement: [X]% reduction in churn
- OR Market share: Enable [X] new customer acquisitions
- OR Operational efficiency: $[amount] cost savings

---

## 4. How will we measure success?

**Primary Metric:**
[The one metric that best indicates success]

**Supporting Metrics:**
- [Metric 1]: Baseline [X], Target [Y]
- [Metric 2]: Baseline [X], Target [Y]
- [Metric 3]: Baseline [X], Target [Y]

**Evaluation Timeline:**
[When we'll measure results - typically 30-90 days post-launch]

---

## 5. What alternatives exist?

**Current Solutions:**
- [How customers solve this today, including "doing nothing"]

**Competitive Landscape:**
- [Competitor 1]: [Their approach and strengths/weaknesses]
- [Competitor 2]: [Their approach and strengths/weaknesses]

**Build vs. Buy vs. Partner:**
[If applicable, assess these alternatives]

**Why We're Best Positioned:**
[Our unique advantages or strategic fit]

---

## 6. What are the risks?

Assess all four risks explicitly:

### Value Risk
**Level:** [High / Medium / Low]

**Assessment:**
[Will customers use/buy this?]

**Key Unknowns:**
- [What we don't know about customer demand]

**De-Risking Plan:**
- [Discovery activities to validate value]

---

### Viability Risk
**Level:** [High / Medium / Low]

**Assessment:**
[Does this work for our business?]

**Key Stakeholders & Concerns:**
- [Sales]: [Concern or requirement]
- [Marketing]: [Concern or requirement]
- [Legal/Compliance]: [Concern or requirement]
- [Finance]: [Business case status]
- [Support]: [Concern or requirement]

**De-Risking Plan:**
- [Activities to address viability concerns]

---

### Usability Risk
**Level:** [High / Medium / Low]

**Assessment:**
[Can users figure out how to use this?]

**Key Unknowns:**
- [What we don't know about usability]

**De-Risking Plan:**
- [Design and testing activities]

---

### Feasibility Risk
**Level:** [High / Medium / Low]

**Assessment:**
[Can we build this with available time/tech/skills?]

**Technical Concerns:**
- [Dependency 1]
- [Dependency 2]
- [Unknown 1]

**De-Risking Plan:**
- [Technical spikes or proofs of concept needed]

**Discovery Timeline (Agent-Accelerated):**
- Prototype-to-customer-feedback: [1-5 days with agents]
- Customer validation cycles: [1-2 weeks]
- Beta-ready build: [2-3 weeks with agent assistance]
- Production hardening: [2-4 weeks based on integration complexity]

**Resource Estimate:**
- Lead engineer (architecture/review): [X days/weeks]
- Agent build capacity: [Note any specialized requirements or constraints]
- Critical review points: [Security, performance, scale, integration validation]

---

## 7. What needs to be true for this to succeed?

List critical assumptions that must be validated:

1. [Assumption about customer behavior or demand]
2. [Assumption about technical approach]
3. [Assumption about business model or viability]
4. [Assumption about market or competition]

**Validation Plan:**
[How and when we'll test these assumptions]

---

## 8. What's the recommendation?

**Decision:** [Proceed to discovery / Build now / Park for later / Kill]

**Rationale:**
[Why this recommendation based on opportunity size and risks]

**Next Steps:**
1. [Specific action 1]
2. [Specific action 2]
3. [Specific action 3]

**Timeline (Agent-Accelerated):**
- Problem validation: [3-5 days]
- Rapid prototyping: [1-5 days with agents]
- Customer validation: [1-2 weeks]
- Beta build: [2-3 weeks]
- Production hardening: [2-4 weeks]
- Total: [7-11 weeks typical]

**Resources Needed:**
- PM: [% time or sprint commitment]
- Design: [% time - agents implement from designs]
- Lead Engineer: [% time for architecture/review - agents handle implementation]
- AI Agents: [Prototype + implementation + testing capacity]

---

## Appendix: Supporting Evidence

[Optional section for detailed data, customer quotes, research findings]
```

---

## Example: Completed Opportunity Assessment

```
# Opportunity Assessment: Self-Service Enterprise Onboarding

**Date:** January 15, 2024
**Owner:** Sarah Chen (PM, Enterprise)
**Status:** Validating

---

## 1. What problem are we solving?

Enterprise customers struggle to onboard their teams efficiently, leading to delayed
time-to-value and increased churn in the first 90 days.

[See full problem statement in separate doc]

---

## 2. Who has this problem?

**Primary Target:**
Enterprise customers with 100+ seats, specifically IT administrators responsible for
user provisioning and access management

**Secondary Audiences:**
- End users being onboarded (experience delays and confusion)
- Customer success team (high touch required during onboarding)
- Sales team (deals delayed waiting for onboarding completion)

**Market Size:**
- TAM: 2,400 enterprise accounts in target segments
- Current penetration: 180 enterprise customers (7.5%)
- Opportunity: 2,220 potential enterprise customers
- Current enterprise ARR: $21.6M (180 × $120K average)

---

## 3. How big is the opportunity?

**Customer Impact:**
Reduce onboarding time from 6-8 weeks to <10 days, enabling faster value realization
and better first-90-day experience

**Business Impact:**
- **Retention:** Reduce first-90-day enterprise churn from 35% to <15%
  - Current annual churn cost: $7.6M (35% × $21.6M)
  - Target churn cost: $3.2M (15% × $21.6M)
  - **Annual retention improvement: $4.4M**

- **New Sales:** Improve enterprise win rate from 18% to 25%
  - Current: 18% × 400 opportunities × $120K = $8.6M
  - Target: 25% × 400 opportunities × $120K = $12M
  - **Annual new ARR improvement: $3.4M**

- **Efficiency:** Eliminate professional services requirement
  - Current: 180 customers × 40 hours × $200/hr = $1.44M annual PS cost
  - **Annual cost savings: $1.44M**

**Strategic Importance:**
- Enterprise is 60% of 2024 growth strategy
- Competitive parity on expected functionality
- Unlocks scale (removes PS bottleneck)

**Total Quantified Opportunity: ~$9.3M annual impact**

---

## 4. How will we measure success?

**Primary Metric:**
Time-to-first-value for enterprise customers

**Supporting Metrics:**
- Time-to-first-value: Baseline 42 days → Target <10 days
- Enterprise 90-day churn: Baseline 35% → Target <15%
- Enterprise NPS: Baseline 22 → Target 37+
- Onboarding support tickets: Baseline 340/quarter → Target <140/quarter
- PS hours per enterprise customer: Baseline 40 → Target <5

**Evaluation Timeline:**
90 days post-launch (need 3-month cohort for churn measurement)

---

## 5. What alternatives exist?

**Current Solutions:**
- Manual user invitations (our current approach)
- Professional services custom integration (4-6 week engagement)
- Customers use their own scripting (error-prone)

**Competitive Landscape:**
- **Competitor A**: Full SCIM/SSO self-service, 2-day typical onboarding
- **Competitor B**: SCIM only, SSO requires PS engagement
- **Competitor C**: Manual process similar to ours (disadvantaged like us)
- **Competitor D**: Self-service SCIM/SSO plus automated user provisioning

**Build vs. Buy vs. Partner:**
- Build: Full control, integrated experience
- Buy: Faster to market but integration complexity
- Partner: Okta/Azure AD have APIs we can leverage

**Why We're Best Positioned:**
We already have 180 enterprise customers who trust us; solving this creates
stickiness and prevents competitive vulnerability

---

## 6. What are the risks?

### Value Risk
**Level:** Low

**Assessment:**
Strong customer validation through interviews, feature requests, and churn analysis

**Key Unknowns:**
- Will self-service approach meet security requirements across all enterprise IT teams?
- How many customers will adopt vs. continue requesting PS support?

**De-Risking Plan:**
- Prototype testing with 8 enterprise IT admins (in progress)
- Security review with 3 large customers' InfoSec teams
- Beta program with 10 friendly enterprise customers

---

### Viability Risk
**Level:** Medium

**Assessment:**
Business case is strong, but stakeholder concerns exist

**Key Stakeholders & Concerns:**
- **Sales:** Concerned about losing PS upsell revenue ($1.44M)
  - Mitigation: PS team refocuses on advanced integrations (higher margin)
- **Marketing:** Need to update positioning and competitive battle cards
  - Mitigation: Already engaged, supportive
- **Legal/Compliance:** SCIM/SSO introduce new data privacy considerations
  - Mitigation: Legal review in progress, no blockers identified yet
- **Finance:** Business case approved contingent on hitting retention targets
  - Mitigation: Phased rollout allows early measurement
- **Support:** Concerned about new complexity
  - Mitigation: Self-service should reduce tickets; need training plan

**De-Risking Plan:**
- Finalize legal/compliance review by Jan 30
- Create PS transition plan with sales leadership
- Build support training and documentation in parallel

---

### Usability Risk
**Level:** Medium

**Assessment:**
IT admin workflows are complex; need to ensure intuitive experience

**Key Unknowns:**
- Can non-technical IT admins complete SCIM setup without support?
- What's the right balance between flexibility and simplicity?

**De-Risking Plan:**
- Low-fi prototype testing (completed - positive feedback)
- High-fi prototype testing with 8 IT admins (scheduled for Jan 22-26)
- Beta program usability monitoring

---

### Feasibility Risk
**Level:** Medium

**Assessment:**
Technically feasible but non-trivial; dependencies on auth infrastructure

**Technical Concerns:**
- SCIM 2.0 implementation requires auth system upgrades
- SSO integration with multiple identity providers (Okta, Azure AD, OneLogin)
- Data migration for existing customers
- Scale considerations (some customers have 10K+ users)

**De-Risking Plan:**
- Technical spike on auth system upgrades (completed - 2 week estimate)
- POC with Okta integration (in progress)
- Load testing plan defined

**Discovery Timeline (Agent-Accelerated):**
- Prototype-to-customer-feedback: 3-5 days with agents
- Customer validation cycles: 2 weeks (multiple iterations)
- Beta-ready build: 3 weeks with agent assistance
- Production hardening: 3-4 weeks (auth system complexity + scale testing)
- Total: 8-10 weeks

**Resource Estimate:**
- Lead engineer (architecture/review): 50% time for 8-10 weeks
- Agent build capacity: Standard (complex auth integration needs architectural oversight)
- Critical review points: Security audit, auth system upgrades, scale testing (10K+ users)

---

## 7. What needs to be true for this to succeed?

Critical assumptions to validate:

1. **IT admins can self-serve SCIM setup without PS support**
   - Validation: Usability testing by Jan 26; beta program monitoring

2. **Security/compliance review surfaces no blockers**
   - Validation: Legal review completion by Jan 30

3. **Self-service onboarding improves 90-day retention by 15+ points**
   - Validation: Measure cohort retention 90 days post-beta launch

4. **Technical architecture scales to 10K+ user enterprises**
   - Validation: Load testing before GA launch

5. **PS team can successfully transition to higher-value services**
   - Validation: PS leadership commitment; track PS revenue for 2 quarters

---

## 8. What's the recommendation?

**Decision:** Proceed to build after completing final de-risking activities

**Rationale:**
- High-value opportunity ($9.3M annual impact) with strong customer validation
- All four risks are manageable (low-medium across the board)
- Strategic imperative for enterprise growth
- Competitive necessity to avoid disadvantage

**Next Steps:**
1. Complete high-fi prototype testing (Jan 22-26)
2. Finalize legal/compliance review (by Jan 30)
3. Get final engineering architecture approval (by Feb 2)
4. Kick off beta program (target 10 customers, Feb 15 start)
5. Begin build for GA launch in Q2 2024

**Timeline (Agent-Accelerated):**
- Final validation: 1 week (Jan 22-26 high-fi testing + Jan 29-30 legal review)
- Rapid prototyping with agents: 1 week (Jan 29 - Feb 2)
- Beta development: 3 weeks (Feb 5 - Feb 23, agent-assisted)
- Beta program: 4 weeks (Feb 15 - Mar 15)
- Production hardening: 3 weeks (Mar 1 - Mar 22)
- GA launch: Late March 2024

**Timeline improvement: 6 weeks faster (late March vs mid-April)**

**Resources Needed:**
- PM: 100% time through launch (Sarah)
- Design: 50% time through beta, 25% through GA (Jordan)
- Lead Engineer: 60% time for architecture/review (Backend lead)
- AI Agents: Prototype + implementation + test generation

---

## Appendix: Supporting Evidence

[Customer interview transcripts, data analysis, competitive research, etc.]
```

---

## Opportunity Assessment Quality Checklist

- [ ] Problem is clearly defined (not solution-focused)
- [ ] Target customer segment is specific
- [ ] Opportunity is quantified with specific metrics
- [ ] All four risks are assessed honestly
- [ ] Evidence is provided for key claims
- [ ] Success metrics are defined with baselines and targets
- [ ] Assumptions are explicitly stated
- [ ] Clear recommendation with rationale
- [ ] Next steps and timeline are specific
- [ ] Resource requirements are estimated
- [ ] Document is concise (1-3 pages max, excluding appendix)

## Remember

- Opportunity assessments should be lightweight (not heavy PRDs)
- Update them as you learn during discovery
- All four risks must be addressed, not just feasibility
- Evidence beats opinion—include data and customer feedback
- Be honest about unknowns and risks
- Clear recommendation and next steps are essential

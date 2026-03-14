# Problem Statement Template

A strong problem statement focuses on the problem to solve, not the solution. It should be clear, specific, measurable, and explain why the problem matters.

## Template Structure

```
## Problem Statement

[1-2 sentence description of the problem]

### Who Experiences This Problem?
[Specific customer segment or user type]

### What Is the Problem?
[Detailed description of the pain point or unmet need]

### Why Does This Problem Matter?
[Business impact, customer impact, strategic importance]

### How Do We Know This Is a Problem?
[Evidence: customer feedback, data, market research]

### What Happens If We Don't Solve This?
[Consequences of inaction]

### Success Criteria
[How will we measure if we've solved this problem?]
```

## Example: Good Problem Statement

```
## Problem Statement

Enterprise customers struggle to onboard their teams efficiently, leading to delayed
time-to-value and increased churn in the first 90 days.

### Who Experiences This Problem?
- Enterprise customers (100+ seats)
- IT administrators responsible for rollout
- End users being onboarded to the platform

### What Is the Problem?
Enterprise customers currently face a 6-8 week onboarding period that requires
significant manual work:
- IT admins must manually invite users in small batches
- No bulk user provisioning capability
- SCIM/SSO integration requires custom professional services engagement
- No self-service tools for managing user groups and permissions
- End users receive fragmented communication about getting started

This creates friction, delays value realization, and generates support burden.

### Why Does This Problem Matter?
**Business Impact:**
- 35% of enterprise customers churn within first 90 days (vs 12% for SMB)
- Average enterprise deal: $120K ARR
- Delayed onboarding extends sales cycle by 30 days on average
- Professional services team fully booked (constraint on growth)

**Customer Impact:**
- Customers report "getting started" as #1 pain point (CSAT data)
- IT admins spend 20+ hours per rollout on manual tasks
- End users wait 2-3 weeks before receiving access

**Strategic Importance:**
- Enterprise segment is core to 2024 growth strategy (60% of new ARR target)
- Competitive differentiation opportunity (3 of 4 competitors have self-service onboarding)

### How Do We Know This Is a Problem?
**Customer Evidence:**
- 18 customer interviews in Q4 2023 (verbatim quotes documented)
- Top feature request in enterprise segment (47% of feature requests)
- NPS detractor analysis: onboarding mentioned in 60% of enterprise detractor comments

**Data Evidence:**
- Time-to-first-value for enterprise: 42 days (vs 7 days for SMB)
- Enterprise churn rate 3x higher than SMB in first 90 days
- Support ticket volume: 340 tickets related to onboarding in Q4

**Market Evidence:**
- Lost 4 enterprise deals to competitors citing easier onboarding
- Analyst reports identify onboarding as category hygiene factor

### What Happens If We Don't Solve This?
- Miss enterprise ARR targets for 2024 ($15M at risk)
- Continue losing deals to competitors with better onboarding
- Professional services team remains bottleneck to scaling enterprise
- Customer satisfaction and retention remain weak in strategic segment

### Success Criteria
**Customer Metrics:**
- Reduce average onboarding time to <10 days for enterprise customers
- Increase enterprise NPS by 15+ points
- Reduce onboarding-related support tickets by 60%

**Business Metrics:**
- Reduce first-90-day enterprise churn from 35% to <15%
- Eliminate professional services requirement for standard onboarding
- Enable 80% of enterprise customers to self-serve onboarding

**Timeline:**
- Measure 90 days after launch for statistical significance
```

## Example: Bad Problem Statement (Solution-Focused)

```
## Problem Statement

We need to build a SCIM provisioning API and SSO integration to solve enterprise
onboarding problems.
```

**Why this is bad:**
- Jumps directly to a solution (SCIM/SSO) without defining the problem
- Doesn't explain who has the problem or why it matters
- No evidence provided
- No measurable success criteria
- Assumes one specific solution without exploring alternatives

## Problem Statement Quality Checklist

Use this checklist to evaluate problem statements:

### Problem-Focused (Not Solution-Focused)
- [ ] Describes the problem, not a feature or solution
- [ ] Avoids technical implementation details
- [ ] Explains "what" and "why" before "how"

### Specific and Clear
- [ ] Targets a specific customer segment or user type
- [ ] Describes the pain point in concrete terms
- [ ] Avoids vague language ("better," "improve," "enhance")

### Evidence-Based
- [ ] Cites specific customer feedback or quotes
- [ ] Includes relevant data (usage, churn, revenue, support tickets)
- [ ] References market or competitive intelligence
- [ ] Quantifies the problem size and impact

### Impact-Oriented
- [ ] Explains business impact (revenue, cost, strategic)
- [ ] Explains customer impact (satisfaction, efficiency, outcomes)
- [ ] Articulates consequences of not solving the problem

### Measurable
- [ ] Defines success criteria with specific metrics
- [ ] Includes baseline measurements
- [ ] Specifies target improvements
- [ ] Identifies how and when success will be measured

### Scoped Appropriately
- [ ] Focused enough to be actionable
- [ ] Broad enough to allow solution exploration
- [ ] Clear boundaries (what's in/out of scope)

## Common Problem Statement Mistakes

### Mistake 1: Disguised Solution

**Bad**: "The problem is we don't have a mobile app"

**Why**: That's a solution, not a problem

**Better**: "Field sales reps can't access customer data when meeting clients on-site, leading to longer sales cycles and lower close rates"

### Mistake 2: Too Vague

**Bad**: "Customers want better reporting"

**Why**: "Better" is subjective; no specifics; no evidence

**Better**: "Finance teams spend 8+ hours per month manually reconciling data across three systems because our current reports don't include transaction-level details they need for audits"

### Mistake 3: No Evidence

**Bad**: "We think users would like dark mode"

**Why**: Opinion-based; no customer validation; unclear impact

**Better**: "15% of users (2,400 people) have requested dark mode in surveys and support tickets, citing eye strain during extended usage. This segment has 40% higher engagement than average users."

### Mistake 4: Feature Request Parroting

**Bad**: "The sales team says we need Salesforce integration"

**Why**: Stakeholder solution presented as a problem; no customer validation

**Better**: "Sales reps spend 30 minutes per deal manually copying data between our product and Salesforce, creating data entry errors in 25% of deals and delaying quote generation"

### Mistake 5: No Business Impact

**Bad**: "The checkout flow has too many steps"

**Why**: Asserts a problem without demonstrating impact

**Better**: "Our checkout flow has a 68% abandonment rate (vs 45% industry average), costing an estimated $2.3M in annual revenue. User testing shows confusion at the shipping options step."

## Using the Problem Statement

Once you have a strong problem statement:

1. **Share widely** with the product trio (PM, design, engineering) and key stakeholders
2. **Validate assumptions** through discovery activities
3. **Generate multiple solutions** (avoid anchoring on one approach)
4. **Assess all four risks** for potential solutions
5. **Refer back frequently** to ensure solutions actually address the stated problem

## Remember

As SVPG emphasizes:
- Problems are owned by product teams; solutions are discovered collaboratively
- Strong problem definition enables creative solution exploration
- Evidence-based problem statements build stakeholder confidence
- The problem statement should remain stable even as solutions evolve

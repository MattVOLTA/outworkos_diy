# Good vs. Bad Requirements: Quality Assessment

Based on SVPG principles, this reference helps identify high-quality requirements that enable empowered teams vs. poor requirements that create feature factories.

---

## Core Principles

### What Makes Requirements "Good" (SVPG Framework)

Good requirements:
1. **Problem-focused**: Define the problem, not the solution
2. **Evidence-based**: Backed by customer data, not opinions
3. **Outcome-oriented**: Focus on results, not features
4. **Risk-aware**: Address all four risks (value, viability, usability, feasibility)
5. **Enabling**: Give teams problems to solve, not features to build
6. **Measurable**: Define success criteria clearly

### What Makes Requirements "Bad"

Bad requirements:
1. **Solution-focused**: Prescribe features without explaining problems
2. **Opinion-based**: Built on assumptions, not evidence
3. **Output-oriented**: Focus on shipping features, not achieving outcomes
4. **Risk-blind**: Ignore value/viability risks; over-focus on feasibility
5. **Constraining**: Tell teams exactly what to build, removing autonomy
6. **Vague**: Lack clear success criteria or measurable goals

---

## Detailed Comparisons

### 1. Problem vs. Solution Focus

#### Bad Example (Solution-Focused)
```
Requirement: Build a mobile app with push notifications,
offline mode, and biometric authentication.
```

**Why it's bad:**
- Jumps directly to solution without stating the problem
- Prescribes specific features without explaining why
- Removes team's ability to discover better solutions
- No evidence that this solves a real problem

#### Good Example (Problem-Focused)
```
Problem: Field technicians cannot access work orders
while on job sites without cellular connectivity, leading
to 4+ hours of lost productivity per technician per week
and reduced customer satisfaction (NPS 35 vs 62 for
office-based workflows).

Evidence:
- 45 technician interviews highlighting connectivity as #1 pain point
- Time-motion studies showing 4.2 hours/week wasted
- Support tickets: 340 in Q4 related to offline access

Success Criteria:
- Reduce productivity loss to <1 hour/week
- Increase field technician NPS from 35 to 55+
- Eliminate connectivity-related support tickets

Solution Space:
Multiple approaches to explore: native mobile app,
progressive web app with offline mode, optimized
lightweight mobile web, etc.
```

**Why it's good:**
- Clearly defines the problem and who has it
- Provides evidence (interviews, data, metrics)
- Explains business and customer impact
- Defines measurable success criteria
- Opens solution space for team to explore

---

### 2. Evidence vs. Opinion

#### Bad Example (Opinion-Based)
```
Users probably want dark mode because it's trendy
and all modern apps have it. We should build it to
stay competitive.
```

**Why it's bad:**
- Based on assumption ("probably want")
- Trend-chasing without customer validation
- Competitive copying without understanding context
- No data or evidence provided

#### Good Example (Evidence-Based)
```
Problem: Power users report eye strain during
extended usage sessions (2+ hours daily).

Evidence:
- 2,400 users (15% of base) explicitly requested dark mode
- Usage data: this segment averages 4.2 hours/day in product
- NPS verbatim comments: "bright interface" mentioned by 18% of detractors
- Usability study: 8/10 power users reported eye discomfort after 2 hours
- Competitive analysis: 4 of 5 top competitors offer dark mode

Impact:
- Power users represent 40% of revenue despite being 15% of users
- Risk of churn if we don't address ergonomics for extended usage

Success Criteria:
- 60% adoption rate among power users within 90 days
- Eye strain complaints reduced by 70%
- Power user NPS improvement of 10+ points
```

**Why it's good:**
- Specific customer segment identified
- Multiple evidence sources cited
- Quantified impact and opportunity
- Clear success metrics defined

---

### 3. Outcomes vs. Outputs

#### Bad Example (Output-Focused)
```
Requirements:
- Build 5 new dashboard widgets
- Add 10 new report types
- Create 3 data export formats
- Deliver by end of Q2

Success = All features shipped on time
```

**Why it's bad:**
- Lists features to ship, not problems to solve
- Success defined as "shipping" not "achieving results"
- No connection to business or customer outcomes
- Feature factory mentality

#### Good Example (Outcome-Focused)
```
Problem: Marketing managers cannot attribute ROI to
campaigns, leading to inefficient budget allocation.

Current State:
- Marketing spends $5M annually across 12 channels
- No clear attribution model in place
- Budget decisions made on intuition, not data
- Estimated 20-30% of budget wasted on ineffective channels

Desired Outcome:
- Marketing can accurately attribute revenue to campaigns
- Budget allocation optimized based on data
- Marketing efficiency improved by 20%+

Success Criteria:
- 80% of marketing budget allocated based on attribution data
- Marketing ROI improved from 2.1x to 2.7x+
- Time to analyze campaign performance reduced from 2 weeks to <1 day

Solution Approach:
Multiple approaches explored during discovery:
- Enhanced analytics dashboard (current thinking)
- Third-party attribution integration
- ML-powered attribution modeling
- Simplified reporting with key metrics focus

Features will be determined based on what achieves
the outcome most effectively.
```

**Why it's good:**
- Focuses on business outcome (better ROI, faster decisions)
- Quantifies current state and target state
- Success defined by business results, not feature count
- Solution space remains open for discovery

---

### 4. Four-Risks vs. Feasibility-Only

#### Bad Example (Feasibility-Only Focus)
```
Technical Requirements:
- Use React for frontend
- PostgreSQL database
- REST API with OAuth 2.0
- Deploy on AWS

Engineering says it will take 8 weeks.
Looks feasible, let's build it.
```

**Why it's bad:**
- Only addresses feasibility risk
- Ignores whether customers want it (value risk)
- Ignores business viability (stakeholder concerns, business case)
- Ignores usability (can users actually use it?)
- Technical decisions made before problem is clear

#### Good Example (All Four Risks Assessed - Agentic Era)
```
Risk Assessment:

VALUE RISK - Medium
- Customer interviews (12) validate problem exists
- Willingness to pay unclear (need prototype test)
- Competitive alternatives strong
→ De-risk: Agent-built functional prototype in 3 days → test with 20 customers over 1 week

VIABILITY RISK - Medium
- Business case positive ($2M ARR opportunity)
- Legal reviewing compliance concerns (GDPR)
- Sales concerned about impact on services revenue
→ De-risk: Legal clearance by Feb 15, sales workshop on Feb 10

USABILITY RISK - Low
- Designer completed low-fi testing (8 users, positive)
- Standard patterns used
- High-fi prototype testing scheduled
→ De-risk: High-fi testing Feb 20-24 with agent-built functional prototype

FEASIBILITY RISK - Prototype: Low / Production: Medium
- Prototype feasibility: Agents can build functional version in 3-5 days
- Production feasibility: Auth system integration requires architectural review
- AWS infrastructure sufficient for scale
→ De-risk: Agent builds prototype for customer validation (3 days), then engineering architecture review for production (1 week)
→ De-risk: Auth spike complete, architecture reviewed

Recommendation: Proceed to build after completing
value de-risking (prototype tests) and viability
clearance (legal/sales alignment).
```

**Why it's good:**
- All four risks explicitly assessed
- Honest evaluation (low-medium, not all "low")
- Evidence provided for each assessment
- De-risking activities identified
- Gated decision: complete de-risking before full build

---

### 5. Empowering vs. Constraining

#### Bad Example (Constraining)
```
Build exactly this:
- Home screen with 6 tiles (3×2 grid)
- Each tile 120px × 120px
- Blue gradient background (#0066CC to #0052A3)
- Tiles: Dashboard, Reports, Settings, Help, Profile, Logout
- On click, navigate to respective screen
- Use Roboto font, 16pt bold for labels
- Animation: 200ms fade on hover

Do not deviate from this spec.
```

**Why it's bad:**
- Prescribes exact implementation
- Removes designer and engineer from decision-making
- Assumes PM knows best solution (unlikely)
- No room for team expertise or discovery
- Feature team behavior, not empowered team

#### Good Example (Empowering)
```
Problem: First-time users don't know where to start,
leading to 45% abandonment in first session.

User Need:
When I first log in, I need to understand what this
product can do and quickly access the most relevant
features for my role, so I can start getting value
immediately.

Constraints:
- Must support 4 primary user roles with different needs
- Must be accessible (WCAG AA compliance)
- Must work on mobile and desktop

Design Principles:
- Clarity over flexibility
- Progressive disclosure (don't overwhelm)
- Personalization based on role

Success Criteria:
- First-session abandonment reduced to <20%
- Time-to-first-value reduced from 12 minutes to <3 minutes
- User comprehension (measured via survey): 80%+ understand
  core capabilities after first session

Collaboration:
Design will explore multiple approaches through
prototyping and testing. Engineering will advise on
technical feasibility and performance. PM will ensure
solution addresses the problem and success metrics.
```

**Why it's good:**
- Defines problem and user need clearly
- Provides constraints (real requirements like accessibility)
- Sets design principles without prescribing solutions
- Defines success criteria (measurable)
- Invites cross-functional collaboration
- Trusts team expertise (design, engineering)

---

### 6. Measurable vs. Vague

#### Bad Example (Vague)
```
Goal: Improve the user experience and make the
product better.

Requirements:
- Better performance
- Improved design
- Enhanced functionality
- More intuitive interface

Success: Users are happier
```

**Why it's bad:**
- "Better," "improved," "enhanced" are subjective
- No baseline or target metrics
- "Happier" is not measurable
- No way to know if you've succeeded

#### Good Example (Measurable)
```
Problem: Checkout flow has 68% abandonment rate
(vs 45% industry average), costing $2.3M annually.

Current State Metrics:
- Checkout abandonment: 68%
- Time to complete checkout: 4.2 minutes (median)
- Error rate: 22% of attempts encounter errors
- Mobile abandonment: 79%
- Customer satisfaction (checkout): 3.2/5

Target Metrics:
- Checkout abandonment: <50% (industry competitive)
- Time to complete: <2 minutes (50% reduction)
- Error rate: <5%
- Mobile abandonment: <55% (close mobile-desktop gap)
- Customer satisfaction: >4.0/5

Leading Indicators (measurable within 2 weeks):
- Completion rate of step 1 (address): >85%
- Completion rate of step 2 (payment): >90%
- Completion rate of step 3 (review): >95%

Measurement Plan:
- Baseline established: Jan 2024 (30 days data)
- Weekly monitoring during development
- 30-day post-launch evaluation
- 90-day sustained improvement validation

Success = Hit 3 of 5 target metrics AND overall
abandonment <50%
```

**Why it's good:**
- Specific current state with data
- Quantified targets with rationale
- Leading indicators enable early course correction
- Clear measurement plan and timeline
- Defined success criteria (not subjective)

---

## Common Requirements Red Flags

### Red Flag Checklist

Watch for these warning signs in requirements:

- [ ] **No problem statement**: Jumps directly to features
- [ ] **No evidence**: Based on opinion or single data point
- [ ] **No success metrics**: Vague goals like "better" or "improved"
- [ ] **Solution prescribed**: Exact features specified before discovery
- [ ] **Only feasibility addressed**: Value/viability/usability risks ignored
- [ ] **Competitive copying**: "Competitor has it so we need it"
- [ ] **HiPPO-driven**: "Executive wants it" with no problem validation
- [ ] **Feature list**: Multiple features without clear problem connection
- [ ] **One customer request**: Optimizing for single customer without broader validation
- [ ] **No user context**: Missing who, when, where, why
- [ ] **Assumed solution**: "We need X" instead of "Users can't accomplish Y"
- [ ] **Output focus**: Success defined as "shipped on time"
- [ ] **Vague language**: "Better," "easier," "faster" without specifics

---

## Quality Assessment Exercise

Use this rubric to score requirements quality (1-5 scale):

### Problem Clarity (1-5)
1. No problem stated, only features
2. Vague problem, mostly focused on features
3. Problem stated but unclear or broad
4. Clear problem with some context
5. Crystal clear problem with full context

### Evidence (1-5)
1. No evidence, pure opinion
2. Single anecdote or data point
3. Some data but not comprehensive
4. Multiple evidence sources
5. Strong evidence from customers, data, and market

### Outcome Focus (1-5)
1. Pure feature list
2. Mostly features with vague outcomes
3. Some outcomes mentioned
4. Clear outcomes with supporting features
5. Strong outcome focus with measurable success

### Risk Assessment (1-5)
1. No risk assessment
2. Only feasibility considered
3. Two risks addressed
4. Three risks addressed
5. All four risks thoroughly assessed

### Team Empowerment (1-5)
1. Exact solution prescribed
2. Heavily constrained solution
3. Some room for team input
4. Problem clear, solution space open
5. Fully empowering with clear constraints

### Measurability (1-5)
1. No metrics or success criteria
2. Vague goals ("better," "improved")
3. Some metrics but unclear baseline/target
4. Clear metrics with baseline and target
5. Comprehensive metrics with measurement plan

**Scoring:**
- 25-30: Excellent requirements (empowered team)
- 20-24: Good requirements (minor improvements needed)
- 15-19: Fair requirements (significant improvements needed)
- 10-14: Poor requirements (major rework needed)
- 6-9: Very poor requirements (start over with problem discovery)

---

## Transforming Bad Requirements into Good Ones

### Transformation Process

1. **Identify the pattern**: Which bad pattern is this? (solution-focused, opinion-based, etc.)
2. **Ask clarifying questions**: Use five-whys and stakeholder interview techniques
3. **Gather evidence**: Customer research, data analysis, market validation
4. **Reframe as problem**: Write clear problem statement
5. **Assess all four risks**: Don't skip value/viability
6. **Define success metrics**: Specific, measurable outcomes
7. **Open solution space**: Invite team collaboration

### Example Transformation

**Before (Bad):**
```
Build a Slack integration with commands for creating
tasks, viewing dashboards, and getting notifications.
```

**After (Good):**
```
Problem: Remote teams lose context and alignment because
critical product updates are buried in email/meetings,
leading to missed deadlines and duplicated work.

Evidence:
- 34 customer interviews citing "staying in sync" as top challenge
- Average team spends 6 hours/week in alignment meetings
- 40% of support tickets stem from missed communications
- Users check our product 2.3×/day but Slack 18×/day

Success Criteria:
- Reduce alignment meeting time by 40%
- Increase product engagement by 30% (via ambient awareness)
- Reduce communication-related support tickets by 50%

Risk Assessment:
[Value: Medium, Viability: Low, Usability: Medium, Feasibility: Low]

Solution Exploration:
Multiple approaches to explore:
- Slack integration (original request)
- Email digests with better formatting
- Standalone notifications app
- In-product activity feeds
- Microsoft Teams integration instead/additionally

Collaborate with design and engineering to prototype
and test approaches.
```

---

## Remember

As SVPG emphasizes:
- "Feature teams deliver output, but product teams deliver outcomes"
- "Bad teams gather requirements; good teams solve problems"
- Requirements should enable creativity, not constrain it
- Evidence beats opinion every time
- All four risks matter, not just feasibility
- Empowered teams need problems to solve, not features to build

Good requirements are the foundation of great products.

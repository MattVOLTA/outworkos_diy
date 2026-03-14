# The Four Big Risks Framework

Every product effort faces four critical risks. Product managers must understand and assess all four, with explicit ownership of value and viability risks.

## 1. Value Risk

**Definition**: Will customers buy this or choose to use it?

### Key Questions
- Does this solve a real problem customers care about?
- Will customers choose this over alternatives (including doing nothing)?
- What evidence do we have of customer desire?
- How strong is the customer pain point?

### Assessment Criteria
- **High Risk**: No customer validation; assumed pain point; crowded market with strong alternatives
- **Medium Risk**: Some customer feedback; validated problem but unclear solution fit
- **Low Risk**: Strong customer demand; proven willingness to pay/use; differentiated value

### De-Risking Activities
- Customer interviews and observation
- Prototype testing with target users
- Fake door tests (measure interest before building)
- Concierge MVP (manual delivery to validate demand)
- Landing pages with signup to gauge interest

### Red Flags
- "We think customers want this"
- Relying solely on stakeholder or sales requests
- No direct customer contact in last 30 days
- Assuming your opinion represents customer needs

### Evidence to Gather
- Customer quotes demonstrating pain
- Usage data showing current workarounds
- Willingness-to-pay signals
- Competitive win/loss analysis
- NPS and satisfaction scores for related features

## 2. Viability Risk

**Definition**: Does this solution work for our business?

### Key Questions
- Does this align with business strategy and priorities?
- Can we market and sell this effectively?
- Does this meet legal, compliance, privacy requirements?
- Can we support and service this long-term?
- Does this strengthen or weaken our market position?
- What are financial implications (cost, revenue, margins)?

### Stakeholder Considerations

**Sales**: Can they sell it? Does it help close deals? Training needed?

**Marketing**: Can they position it? Does it fit brand and messaging?

**Finance**: What's the business case? ROI timeline? Pricing implications?

**Legal/Compliance**: Any regulatory concerns? Privacy issues? Terms of service changes?

**Support/Success**: Can customers be supported effectively? Documentation and training needs?

**Operations**: Infrastructure and operational requirements? Scale considerations?

**Leadership**: Strategic alignment? Resource allocation justified?

### Assessment Criteria
- **High Risk**: Conflicts with strategy; unclear business case; major stakeholder objections
- **Medium Risk**: Business case exists but uncertain; some stakeholder concerns
- **Low Risk**: Strong alignment; clear business value; stakeholder support secured

### De-Risking Activities
- Stakeholder interviews early and often
- Business case modeling with finance
- Legal/compliance review before deep investment
- Go-to-market planning with sales and marketing
- Operational readiness assessment

### Red Flags
- "We'll figure out the business model later"
- Building without stakeholder input
- Ignoring cost and scalability implications
- Surprising stakeholders late in the process
- Assuming viability because value exists

### Evidence to Gather
- Business case with financial projections
- Stakeholder sign-offs on key concerns
- Legal/compliance clearance
- Go-to-market plan from marketing/sales
- Support and operations readiness assessment

## 3. Usability Risk

**Definition**: Can users figure out how to use this?

### Key Questions
- Is the user experience intuitive?
- Can users accomplish their goals efficiently?
- Does this fit users' mental models?
- Are error messages and guidance clear?
- Is accessibility addressed?

### Assessment Criteria
- **High Risk**: Complex workflow; unfamiliar patterns; no user testing done
- **Medium Risk**: Standard patterns used; some testing; minor concerns identified
- **Low Risk**: User-tested design; proven patterns; positive usability feedback

### De-Risking Activities
- Low-fidelity prototypes tested with users
- High-fidelity mockups for detailed feedback
- Usability testing sessions
- A/B testing of design alternatives
- Accessibility reviews

### SVPG Context
Usability is the domain of product design expertise. Product managers should:
- Collaborate closely with designers (not do their job)
- Ensure designers have access to customers
- Participate in usability testing
- Respect design as a specialized discipline

### Red Flags
- "It's intuitive to me, so it must be intuitive"
- Skipping user testing to save time
- Product manager designing UI instead of collaborating with designer
- Complex workflows without user validation

### Evidence to Gather
- Usability test recordings and notes
- User task completion rates
- Time-on-task metrics
- User feedback and satisfaction scores
- Accessibility audit results

## 4. Feasibility Risk

**Definition**: Can we build this with the time, technology, and skills we have?

### Two Dimensions of Feasibility (Agentic Era)

With AI coding agents, feasibility now has two distinct dimensions:

**Prototype Feasibility**: Can we build a working prototype to validate the concept?
- **With AI agents**: Usually LOW risk (days to functional prototype)
- **Key constraint**: Quality of requirements and design inputs
- **Timeline**: 1-5 days for most features

**Production Feasibility**: Can we build a scalable, secure, maintainable production system?
- **Even with AI agents**: Varies based on integration, scale, security needs
- **Key constraints**: Architecture, performance, compliance, third-party dependencies
- **Timeline**: 2-6 weeks depending on complexity

### Key Questions

**For Prototype Feasibility:**
- Can AI agents build a working prototype from our designs/requirements?
- What quality of specifications do agents need to be effective?
- Can we iterate rapidly based on customer feedback?

**For Production Feasibility:**
- Does this integrate with our existing architecture?
- What are performance and scale requirements?
- What security, compliance, or regulatory considerations exist?
- What third-party dependencies or integrations are required?
- What's the long-term maintenance and technical debt impact?

### Assessment Criteria

**Prototype Feasibility:**
- **High Risk**: Poorly defined requirements; unclear user flows; novel UI patterns requiring extensive design exploration
- **Medium Risk**: Well-defined problem but multiple solution approaches to explore
- **Low Risk**: Clear requirements and designs; standard patterns; agent can implement quickly

**Production Feasibility:**
- **High Risk**: Major architectural changes; unproven technology at scale; complex integrations; strict compliance requirements
- **Medium Risk**: Established architecture but non-trivial implementation; some integration complexity
- **Low Risk**: Well-understood patterns; minimal integration; clear scalability path

### De-Risking Activities

**For Rapid Validation (Days 1-5):**
- Agent-built functional prototypes from designs
- Quick iteration cycles based on user testing
- Parallel exploration of multiple solution approaches
- Early validation of technical approach with working code

**For Production Confidence (Weeks 2-4):**
- Architecture reviews with engineering leads
- Performance and scale testing
- Security and compliance reviews
- Integration validation with existing systems
- Technical spikes for high-uncertainty areas

### SVPG Context (Updated for AI Agents)

Feasibility remains engineering's domain. Product managers should:
- Collaborate with engineers early (not hand off requirements)
- Include engineers in discovery
- Respect engineering judgment on architecture and production concerns
- Understand trade-offs, not dictate technical solutions

**What changes with AI agents:**
- Engineers focus more on architecture, review, and production concerns
- Agents handle implementation from validated designs
- Engineering estimates shift from "time to build" to "time to validate and harden"
- Prototype-to-customer-feedback cycles compress from weeks to days

**What doesn't change:**
- Engineers still own architecture decisions
- Production quality still requires human review
- Security, performance, and scale still need engineering expertise
- Technical judgment on feasibility still critical

### Red Flags (Agentic Era)

**Old anti-patterns still apply:**
- "Engineering says it's easy" (without investigation)
- Promising delivery dates without engineering input
- Ignoring technical debt implications
- Product manager specifying technical implementation

**New anti-patterns to avoid:**
- "Agents can prototype anything quickly" (ignoring requirement quality needs)
- Treating agent-built prototypes as production-ready
- Skipping architecture review because "the agent built it"
- Building with agents without customer validation
- Assuming low prototype feasibility means low production feasibility

### Evidence to Gather

**For Prototype Feasibility:**
- Working prototype built by agents (proof of concept)
- Customer feedback on prototype functionality
- Iteration speed (hours to incorporate changes)

**For Production Feasibility:**
- Engineering architecture review and approval
- Performance benchmarks and scale testing results
- Security and compliance clearance
- Integration validation with existing systems
- Production deployment plan with confidence levels
- Technical debt assessment and mitigation plan

## Balancing the Four Risks

### Common Imbalances

**Feasibility-only focus**: "Can we build it?" without asking if anyone wants it
- **Problem**: Builds things nobody uses
- **Fix**: Prioritize value risk assessment equally

**Usability-only focus**: "Is it easy to use?" without business viability
- **Problem**: Creates unsustainable products
- **Fix**: Validate business model and costs

**Value-only focus**: "Customers want it!" without viability or feasibility
- **Problem**: Commitments you can't keep
- **Fix**: Include stakeholders and engineers early

### Integrated Assessment

Good product teams assess all four risks simultaneously through:

1. **Cross-functional discovery**: PM, design, and engineering collaborate from day one
2. **Parallel learning**: Run experiments addressing multiple risks at once
3. **Rapid iteration**: Test cheapest/fastest methods first (prototypes before builds)
4. **Evidence-based decisions**: Gather real data, not opinions

### Risk Evolution

Risks change as you learn:
- **Early**: All four risks may be high
- **During discovery**: De-risk systematically through experiments
- **Before build**: Should have evidence reducing risk in all four areas
- **After launch**: Monitor for new risks (market changes, technical issues)

## Documenting Risk Assessment

For each risk, document:

```
Risk Type: [Value/Viability/Usability/Feasibility]

Current Assessment: [High/Medium/Low]

Evidence:
- [What data/feedback/tests inform this assessment?]

Remaining Unknowns:
- [What don't we know yet?]

De-Risking Plan:
- [What activities will reduce uncertainty?]
- [Timeline and owners]

Decision Criteria:
- [What evidence would make us confident enough to proceed?]
```

## Remember

- Product managers explicitly own **value** and **viability** risks
- All four risks must be assessed, not just feasibility and usability
- Discovery activities should address multiple risks in parallel
- Evidence beats opinion—gather real data from customers, stakeholders, and technical spikes
- Risk assessment is continuous, not one-time

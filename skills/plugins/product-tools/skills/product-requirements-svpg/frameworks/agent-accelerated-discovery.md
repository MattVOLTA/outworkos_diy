# Agent-Accelerated Discovery Framework

AI coding agents fundamentally change the economics and timelines of product discovery. This framework integrates agentic coding capabilities with SVPG discovery principles.

## Core Principle: Prototype-First Discovery

Traditional discovery separates learning activities:
1. Customer interviews → understand problems
2. Design mockups → explore solutions
3. Engineering estimates → assess feasibility
4. Prototypes → test usability
5. Then finally: commit to build

**Agent-accelerated discovery collapses these steps:**
1. Customer interviews → understand problems
2. Design concepts + agent-built prototypes → validate value, usability, AND feasibility simultaneously in days
3. Iterate rapidly based on customer feedback
4. Commit to production build with validated working prototype

## What Changes with AI Agents

### Speed and Cost

**Traditional prototyping:**
- High-fidelity clickable prototypes: 1-2 weeks (design tools only)
- Functional prototypes: 3-6 weeks (requires engineering time)
- Production-quality code: 8-16 weeks
- Cost: High (engineering time is the bottleneck)

**Agent-accelerated prototyping:**
- Functional prototypes: 1-5 days (agents build from designs)
- Production-ready code: 2-4 weeks (agents + human review)
- Cost: 10x cheaper (agent time vs human engineering time)

### Parallel Risk Reduction

**Traditional approach**: Sequential de-risking
- Week 1-2: Customer interviews (value)
- Week 3-4: Design mockups (usability)
- Week 5-6: Technical spikes (feasibility)
- Week 7-8: Stakeholder alignment (viability)

**Agentic approach**: Parallel de-risking
- Days 1-3: Agent builds functional prototype
- Week 1: Test with customers → validates value + usability + basic feasibility together
- Week 2: Iterate based on feedback + stakeholder review → validates viability
- Week 3-4: Production hardening → validates full feasibility

### Exploration of Alternatives

**Traditional approach:**
- Expensive to prototype multiple solutions
- Teams typically commit to one approach early
- "Analysis paralysis" or single-solution anchoring

**Agentic approach:**
- Cheap to prototype 3-4 different solutions
- Customer feedback determines winning approach
- Lower risk of picking wrong solution

## Agent-Accelerated Discovery Process

### Phase 1: Problem Validation (Week 0)

**No change from traditional SVPG**: Human-led discovery
- Customer interviews to understand problems
- Problem statement development
- Opportunity sizing
- Four-risks initial assessment

**Timeline**: 3-5 days
**Ownership**: Product Manager leads with designer and engineer input

### Phase 2: Rapid Prototyping (Days 1-5)

**Agent-enabled acceleration**: Build functional prototypes

**Inputs needed:**
- Clear problem statement
- User flows and interaction designs (low-to-medium fidelity)
- Key technical constraints (APIs, data models, integrations)

**Agent activities:**
- Generate functional UI from designs
- Implement user flows and interactions
- Create realistic data and states
- Build clickable, testable prototypes

**Human activities:**
- PM: Provide context and acceptance criteria
- Designer: Create user flows and visual direction
- Engineer: Define technical guardrails and constraints
- All: Review agent output for quality and direction

**Outputs:**
- 2-3 working prototype alternatives
- Functional code that users can interact with
- Early validation of technical feasibility

**Timeline**: 1-5 days depending on complexity

### Phase 3: Customer Validation (Week 1-2)

**Accelerated by agents**: Rapid iteration cycles

**Activities:**
- Test prototypes with 5-10 target customers
- Gather feedback on value and usability
- Iterate daily based on learnings (agents rebuild in hours)
- Test multiple alternatives to identify strongest approach

**Human ownership:**
- PM + Designer: Lead customer testing sessions
- Engineer: Review technical feedback and constraints
- Agents: Implement changes between sessions

**Decision point:**
- Is there evidence of customer value?
- Can users accomplish their goals (usability)?
- Are there technical red flags?
- Stakeholder concerns surfaced?

**Timeline**: 1-2 weeks (multiple iteration cycles)

### Phase 4: Viability and Architecture Validation (Week 2-3)

**Agents enable**: Working code for stakeholder review

**Activities:**
- Stakeholder review with functional prototype (not just mockups)
- Engineering architecture review
- Business case refinement with realistic scope
- Security and compliance preliminary review

**What's different from traditional:**
- Stakeholders see working software, not concept slides
- Engineers review actual implementation, not estimate in vacuum
- More concrete understanding of "what we're building"

**Decision point:**
- Business case still positive?
- Architecture approach sound?
- Stakeholder concerns addressable?
- Security/compliance risks manageable?

**Timeline**: 1-2 weeks

### Phase 5: Beta-Quality Build (Week 3-5)

**Agents accelerate**: Implementation and test coverage

**Activities:**
- Agents generate production-quality code from validated prototype
- Engineers review code quality, architecture, security
- Agents generate comprehensive test coverage
- Integration with production systems
- Beta customer deployment

**Human focus:**
- Engineering: Architecture review, security review, performance testing
- PM: Beta customer selection and coordination
- Designer: Polish and edge cases
- Agents: Implementation, testing, documentation

**Timeline**: 2-3 weeks

### Phase 6: Production Hardening (Week 5-7)

**Still requires human expertise**: Scale, security, operations

**Activities:**
- Performance and scale testing
- Security audits and penetration testing
- Operational readiness (monitoring, alerts, runbooks)
- Documentation and training materials
- Compliance sign-offs

**What agents can help with:**
- Test generation for edge cases
- Documentation generation
- Monitoring and alert code
- Performance optimization implementation

**What still needs humans:**
- Security review and threat modeling
- Architecture decisions for scale
- Operational procedures
- Compliance validation

**Timeline**: 2-3 weeks

## Total Timeline Comparison

### Traditional SVPG Discovery + Delivery
- Discovery: 6-8 weeks (interviews, designs, prototypes, estimates)
- Delivery: 8-16 weeks (implementation, testing, launch)
- **Total: 14-24 weeks (3.5-6 months)**

### Agent-Accelerated Discovery + Delivery
- Problem validation: 3-5 days
- Rapid prototyping: 1-5 days
- Customer validation: 1-2 weeks
- Viability/architecture: 1-2 weeks
- Beta build: 2-3 weeks
- Production hardening: 2-3 weeks
- **Total: 7-11 weeks (1.75-2.75 months)**

**Speed improvement: 2-3x faster end-to-end**

## When Agents Provide Maximum Value

Agents excel at:
- Standard CRUD applications and user interfaces
- API integrations and data transformations
- Test generation and documentation
- Iterating on designs rapidly
- Exploring multiple solution alternatives
- Generating boilerplate and repetitive code

Agents provide moderate value for:
- Novel algorithms or complex business logic
- Performance-critical code
- Security-sensitive implementations
- Complex state management
- Real-time systems

Agents struggle with:
- Poorly defined requirements
- Architecture decisions requiring domain expertise
- Debugging production issues without good error messages
- Optimizing for extreme scale
- Understanding implicit business rules

## Resource Model Shifts

### Traditional Team Allocation
- Product Manager: 100% (1 FTE)
- Product Designer: 50-75% (0.5-0.75 FTE)
- Engineers: 2-3 FTEs for 8-12 weeks

**Total: 3.5-4.75 FTEs for 8-12 weeks**

### Agent-Accelerated Team Allocation
- Product Manager: 100% (1 FTE)
- Product Designer: 50-75% (0.5-0.75 FTE)
- Lead Engineer: 50% architecture/review (0.5 FTE)
- AI Agents: Prototype + implementation + testing

**Total: 2-2.25 human FTEs for 7-11 weeks + agent capacity**

**Efficiency gain: 40-50% reduction in human engineering time**

## Updated Discovery Kanban

Adapt your discovery board for agent acceleration:

### Columns

1. **Backlog**: Opportunities to explore
2. **Problem Validation**: Customer interviews, problem statements (1 week)
3. **Rapid Prototyping**: Agent-built prototypes (days)
4. **Customer Testing**: Validate with users (1-2 weeks)
5. **Validated**: Ready for production build decision
6. **Beta Build**: Agent-assisted implementation (2-3 weeks)
7. **Production**: Hardening and launch (2-3 weeks)
8. **Measuring**: Post-launch evaluation

### Cards should include:

- **Problem statement** (not solution)
- **Target outcome** and success metrics
- **Four-risks assessment** (including prototype vs production feasibility)
- **Prototype links** (agent-built prototypes)
- **Customer validation summary** (evidence gathered)
- **Timeline estimate** (days for prototype, weeks for production)

## Best Practices

### 1. Start with Clear Problem Statements

Agents amplify good requirements and expose bad ones:
- **Good input**: "Users need to export report data in CSV and PDF formats with custom date ranges"
- **Poor input**: "Add an export feature"

The clearer your problem statement, the faster agents can prototype.

### 2. Design for Agent Implementation

Designers should provide:
- User flows with clear states and transitions
- Component-level designs (not just full-page mockups)
- Interaction patterns and edge cases
- Accessibility requirements

**Don't need**: Pixel-perfect visuals for initial prototypes

### 3. Engineer as Architect and Reviewer

Engineers shift from implementers to:
- **Architects**: Define technical approach and constraints upfront
- **Reviewers**: Assess agent-generated code for quality and security
- **Educators**: Help agents understand your codebase patterns

**Time savings**: 60-80% reduction in hands-on coding time

### 4. Iterate with Customers, Not Internally

**Anti-pattern**: Agent builds prototype → team debates internally for 2 weeks → rebuild

**Best practice**: Agent builds prototype → test with customers within 48 hours → iterate based on real feedback

### 5. Distinguish Prototype from Production

Just because agents can build a prototype in 3 days doesn't mean it's production-ready:

**Prototype goals:**
- Validate customer value
- Test usability
- Prove technical feasibility

**Still need for production:**
- Security review
- Performance optimization
- Error handling and edge cases
- Monitoring and operations
- Compliance validation

### 6. Maintain the Product Trio

Agents don't replace the PM-Designer-Engineer trio:
- **PM**: Still owns value and viability
- **Designer**: Still owns user experience
- **Engineer**: Still owns architecture and production quality
- **Agents**: Amplify the trio's effectiveness

## Anti-Patterns to Avoid

### 1. "Agent Can Build It, So Let's Build It"

**Problem**: Building without validating customer value

**Why it fails**: Fast prototyping doesn't mean customers need it

**SVPG principle still applies**: Discovery validates *what* to build, not just *that* we can build it

### 2. "Skip the Designer, Agent Can Design"

**Problem**: Agents generating UI without design expertise

**Why it fails**: Agents create functional but not necessarily usable experiences

**Best practice**: Designers guide user experience; agents implement designs

### 3. "Production-Ready in 3 Days"

**Problem**: Treating agent prototypes as production code

**Why it fails**: Security, scale, operations still need expert review

**Best practice**: Prototype in days; production-harden in weeks

### 4. "Agent Prototyped It, So Engineering Estimates Should Be Low"

**Problem**: Assuming prototype complexity = production complexity

**Why it fails**: Integration, scale, security add complexity

**Best practice**: Use prototype to inform estimates, not replace them

### 5. "We Don't Need Discovery Anymore"

**Problem**: Jumping straight to agent-building without problem validation

**Why it fails**: Fast building doesn't mean building the right thing

**SVPG principle still applies**: Discovery before delivery

## Measuring Agent-Accelerated Discovery

Track these metrics to assess effectiveness:

### Speed Metrics
- **Time-to-prototype**: Days from problem statement to working prototype
- **Iteration velocity**: Hours to incorporate customer feedback into prototype
- **Time-to-customer**: Days from idea to customer testing
- **Discovery cycle time**: Weeks from opportunity identification to validated backlog item

### Quality Metrics
- **Customer validation rate**: % of prototypes that generate positive customer feedback
- **Production conversion rate**: % of prototypes that become production features
- **Agent code acceptance rate**: % of agent-generated code that passes review without major changes
- **Technical debt introduced**: Debt from agent implementations vs human implementations

### Efficiency Metrics
- **Engineering time saved**: Hours not spent on prototype/implementation
- **Cost per validated idea**: Total cost to validate an opportunity
- **Alternatives explored**: Number of solution approaches tested per opportunity
- **Discovery capacity**: Number of concurrent opportunities team can explore

### Outcome Metrics (Still Most Important)
- **Feature adoption rate**: % of users who adopt launched features
- **Business impact**: Actual outcome metrics (revenue, retention, efficiency)
- **Time-to-value**: Customer time from problem to solution
- **Team satisfaction**: PM, designer, engineer happiness with process

## Remember

Agent-accelerated discovery is still SVPG discovery:
- **Outcomes over output**: Fast building is only good if building valuable things
- **Evidence over opinion**: Agents make gathering evidence faster, not optional
- **Empowered teams**: Agents augment the team, don't replace judgment
- **Continuous discovery**: Speed enables more continuous learning, not less rigor

As Marty Cagan emphasizes: "The goal of discovery is to validate ideas quickly and cheaply before expensive builds."

AI agents make discovery even quicker and cheaper—but the goal remains the same: **ship valuable, viable, usable, and feasible products that customers love.**

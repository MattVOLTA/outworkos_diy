# Changelog - Product Requirements SVPG Skill

## Version 2.0 - Agentic Era Update (January 2025)

This major update adapts the SVPG product requirements skill for the era of AI coding agents, reflecting the 10x faster and cheaper prototyping capabilities that agents provide.

### Summary of Changes

**Core Assumption:** With AI coding agents, functional prototypes can be built in days (not weeks), and production implementations take 2-4 weeks (not 8-16 weeks). This changes the economics and timelines of product discovery.

---

### New Content

#### 1. **New Framework Document: `frameworks/agent-accelerated-discovery.md`**
Comprehensive guide covering:
- How AI agents change discovery timelines (2-3x faster end-to-end)
- Six-phase agent-accelerated process (problem validation → rapid prototyping → customer validation → viability/architecture → beta build → production hardening)
- Timeline comparison: Traditional (14-24 weeks) vs Agent-accelerated (7-11 weeks)
- Resource model shifts (40-50% reduction in human engineering time)
- Best practices for working with agents
- Anti-patterns to avoid
- Metrics for measuring agent-accelerated discovery effectiveness

**Key insight:** Discovery cycles compress from weeks to days, but SVPG principles remain—agents make building faster, not customer validation.

---

### Updated Content

#### 2. **`frameworks/four-risks.md` - Feasibility Risk Reframed**
**Major change:** Split feasibility risk into two dimensions:

**Prototype Feasibility** (usually LOW with agents)
- Can agents build a working prototype in 1-5 days?
- Key constraint: Quality of requirements and design inputs
- Evidence: Working prototype built by agents

**Production Feasibility** (still varies)
- Can we build scalable, secure, maintainable production system?
- Key constraints: Architecture, performance, compliance, integrations
- Timeline: 2-6 weeks depending on complexity
- Evidence: Architecture review, security clearance, scale testing

**Why this matters:** Teams should prototype quickly with agents to validate ideas, then assess production feasibility separately. Don't conflate the two.

**Added sections:**
- "Two Dimensions of Feasibility (Agentic Era)"
- Updated assessment criteria for prototype vs production
- New de-risking activities (agent-built rapid prototypes)
- Updated SVPG context (what changes vs what doesn't with agents)
- New red flags for agentic era
- Updated evidence to gather (prototype + production)

---

#### 3. **`frameworks/discovery-techniques.md` - Agent Workflow Added**
**New techniques added:**
- **Agent-Built Rapid Prototypes** ⭐ (new primary technique)
  - Purpose: Validate technical approach AND test value/usability simultaneously
  - When: Early discovery (days 1-5)
  - Timeline: 1-3 days for functional prototype

**Updated existing techniques:**
- Technical Spikes: Now focused on production feasibility (after prototype validates value)
- Proof of Concept: Agents can implement; engineers review for production viability
- Architecture Review: Review agent-generated code, not just planned approach

**New section added:**
- "Agent-Accelerated Discovery Workflow" with timeline comparison table
- Key principles for agent-accelerated discovery (5 principles)
- Updated "Remember" section emphasizing that agents amplify practices, don't replace judgment

---

#### 4. **`templates/opportunity-assessment.md` - Timeline Updates**
**Changed throughout template:**

**Old feasibility section:**
```
Rough Sizing:
Engineering estimate: S/M/L/XL or T-shirt size
```

**New feasibility section:**
```
Discovery Timeline (Agent-Accelerated):
- Prototype-to-customer-feedback: [1-5 days with agents]
- Customer validation cycles: [1-2 weeks]
- Beta-ready build: [2-3 weeks with agent assistance]
- Production hardening: [2-4 weeks based on integration complexity]

Resource Estimate:
- Lead engineer (architecture/review): [X days/weeks]
- Agent build capacity: [Note any specialized requirements]
- Critical review points: [Security, performance, scale, integration]
```

**Updated example timeline:**
- Old: 18+ weeks (6 week beta dev + 6 week beta program + 4 week GA dev)
- New: 12 weeks (3 week beta dev + 4 week beta program + 3 week production hardening)
- **Improvement: 6 weeks faster**

**Updated resource needs:**
- Old: PM 100% + Design 50% + 2 engineers + 1 lead
- New: PM 100% + Design 50% + 1 lead engineer 60% + AI agents

---

#### 5. **`SKILL.md` - Core Principles Updated**
**Updated sections:**

**"Core SVPG Principles"** renamed to **"Core SVPG Principles (Adapted for Agentic Era)"**
- Added agent-specific notes to each principle
- Feasibility risk now explicitly mentions prototype vs production split
- Discovery section highlights agent advantages (functional prototypes in days, 10x cheaper alternatives)

**"Key Resources"** section updated:
- Added reference to new `agent-accelerated-discovery.md` framework
- Updated descriptions noting agentic era updates

**"Remember"** section expanded:
- New paragraph on agentic era fundamentals
- Emphasizes: speed doesn't justify wrong things, human judgment irreplaceable, customer learning essential

---

#### 6. **`README.md` - Version and Overview Updates**
**Version updated:**
- Old: Version 1.0 (February 2024)
- New: Version 2.0 (January 2025 - Agentic Era Update)

**File structure updated:**
- Added `agent-accelerated-discovery.md` to frameworks list

**Usage Notes updated:**
- Added notes about agent-accelerated discovery
- Timeline shift: 2-3x faster with functional prototypes

---

#### 7. **`reference/good-vs-bad-requirements.md` - Example Updated**
**Risk assessment example updated:**
- Changed from traditional "8 week engineering estimate" approach
- New example shows prototype vs production feasibility split
- VALUE RISK: Now uses "agent-built functional prototype in 3 days → test with 20 customers"
- FEASIBILITY RISK: Split into "Prototype: Low / Production: Medium" with agent timeline

---

#### 8. **`templates/requirements-document.md` - Agentic Note Added**
**Added upfront note:**
> "Agentic Era Note: With AI coding agents, you can rapidly prototype solutions to validate requirements. Consider building functional prototypes (days) before finalizing detailed requirements."

**Discovery log example updated:**
- Added row showing agent prototype build (3 days)
- Updated technical spike description to focus on production feasibility

---

### What Stayed The Same

**SVPG principles remain foundational:**
- Outcomes over output
- Empowered teams over feature teams
- Discovery before delivery
- Four risks must all be assessed
- Problem-first thinking
- Customer learning is essential

**Human judgment still critical:**
- Product managers still own value and viability
- Designers still own user experience
- Engineers still own architecture and production decisions
- Customer interviews and validation still human-led

**What agents DON'T replace:**
- Customer discovery and problem validation
- Strategic product decisions
- Complex architecture decisions
- Production performance/scale validation
- Security and compliance review

---

### Impact Summary

| Aspect | Traditional SVPG | Agent-Accelerated SVPG |
|--------|------------------|------------------------|
| **Discovery timeline** | 6-8 weeks | 3-5 days + 1-2 weeks validation |
| **Prototype creation** | 3-6 weeks (engineering bottleneck) | 1-5 days (agents) |
| **Total delivery time** | 14-24 weeks | 7-11 weeks |
| **Alternative exploration** | Expensive (1-2 alternatives max) | Cheap (3-4 alternatives feasible) |
| **Feasibility risk** | Single dimension | Split: Prototype (LOW) vs Production (varies) |
| **Engineering role** | Implementation + architecture | Architecture + review (agents implement) |
| **Resource efficiency** | 3.5-4.75 FTEs | 2-2.25 FTEs + agents |
| **Core principles** | Unchanged | **Unchanged** ✓ |

---

### Migration Guide

**If you're already using this skill:**

1. **Read the new framework first:** Start with `frameworks/agent-accelerated-discovery.md` to understand the new workflow

2. **Distinguish prototype vs production feasibility:** When assessing feasibility risk, separately evaluate:
   - Can agents build a prototype quickly? (usually yes)
   - Can we deploy this at production scale/security? (still needs assessment)

3. **Update your opportunity assessments:** Use the new timeline template in `templates/opportunity-assessment.md`:
   - Prototype: days
   - Customer validation: 1-2 weeks
   - Beta: 2-3 weeks
   - Production: 2-4 weeks

4. **Prototype earlier:** Don't wait weeks for engineering estimates—build functional prototypes in days to validate ideas with customers

5. **Maintain SVPG rigor:** Faster prototyping doesn't mean skip customer validation or problem definition

---

### Questions or Feedback?

This update maintains the integrity of SVPG principles while reflecting the new reality of AI-assisted development. The fundamentals haven't changed—we're still solving customer problems through rigorous discovery. We're just doing it 2-3x faster with agent assistance.

If you have feedback or suggestions for further improvements, please open an issue or submit a pull request.

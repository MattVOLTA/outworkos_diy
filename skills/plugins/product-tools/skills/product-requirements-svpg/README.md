# Product Requirements (SVPG Framework) Skill

A Claude skill for defining product requirements using Silicon Valley Product Group (SVPG) principles, based on Marty Cagan's frameworks.

## Overview

This skill helps product managers, product leaders, and teams apply SVPG best practices to:
- Transform feature requests into problem statements
- Assess all four risks (value, viability, usability, feasibility)
- Create requirements that separate problems from solutions
- Enable empowered teams instead of feature factories
- Focus on outcomes over output

## When to Use This Skill

Use this skill when:
- Defining new product requirements or opportunities
- Evaluating feature requests from stakeholders or customers
- Building PRDs or product briefs
- Starting product discovery for new initiatives
- Transforming from feature team to empowered team practices

## What This Skill Provides

### Core Frameworks
- **Four Risks Assessment**: Systematic evaluation of value, viability, usability, and feasibility
- **Discovery Techniques**: SVPG-aligned approaches to continuous product discovery
- **Problem-First Thinking**: Moving from solution-focused to problem-focused requirements

### Templates
- **Problem Statements**: Structure and examples for defining problems clearly
- **Opportunity Assessments**: Lightweight 1-2 page opportunity evaluation format
- **Requirements Documents**: Full template separating problem space from solution space

### Reference Guides
- **Feature-to-Problem Transformation**: Examples and techniques for converting feature requests into problems
- **Good vs. Bad Requirements**: Quality assessment criteria with detailed comparisons

## File Structure

```
product-requirements-svpg/
├── SKILL.md                          # Main skill file with overview and workflow
├── README.md                         # This file
├── frameworks/
│   ├── four-risks.md                 # Detailed four-risks framework (updated for prototype vs production feasibility)
│   ├── discovery-techniques.md       # Product discovery approaches (updated with agent workflow)
│   └── agent-accelerated-discovery.md # NEW: AI agents impact on discovery timelines and economics
├── templates/
│   ├── problem-statement.md          # Problem statement template and examples
│   ├── opportunity-assessment.md     # Opportunity assessment template
│   └── requirements-document.md      # Full requirements doc template
└── reference/
    ├── feature-to-problem.md         # Feature transformation examples
    └── good-vs-bad-requirements.md   # Requirements quality assessment
```

## Key SVPG Principles Embedded

1. **Empowered Teams Over Feature Teams**: Give teams problems to solve, not features to build
2. **Outcomes Over Output**: Focus on business results and customer value, not shipping features
3. **Four Big Risks**: Assess value, viability, usability, and feasibility systematically
4. **Discovery Before Delivery**: Validate ideas through rapid experimentation before building
5. **Evidence Over Opinion**: Base decisions on customer data, not assumptions
6. **Cross-Functional Collaboration**: Product trio (PM, design, engineering) works together

## How the Skill Works

### Interview-First Approach
When you request help with requirements, the skill will:

1. **Ask clarifying questions** to understand your context
2. **Challenge solution-centric framing** if you present features instead of problems
3. **Guide collaborative exploration** of the problem space
4. **Assess all four risks** systematically
5. **Generate structured outputs** (problem statements, risk assessments, requirements docs)

### Progressive Disclosure
The skill uses progressive disclosure:
- **SKILL.md** provides overview and workflow
- **Frameworks** offer deep-dive on specific SVPG concepts
- **Templates** provide copyable structures for your work
- **Reference** materials offer examples and quality criteria

## Example Usage

**You:** "I need to write requirements for a mobile app our sales team is requesting"

**Claude (with this skill):**
- Asks about the underlying problem (not jumping to mobile app solution)
- Explores who has the problem and why it matters
- Assesses all four risks (not just feasibility)
- Helps transform the request into a clear problem statement
- Generates requirements that separate problem from solution
- Suggests discovery activities to validate assumptions

## Sources

This skill is based on the top SVPG articles including:
- Product Management - Start Here
- Good Product Team / Bad Product Team
- Product Management Theater
- Behind Every Great Product
- More PM Problem Areas
- Product Discovery
- The Four Big Risks

All content follows Marty Cagan's frameworks and SVPG principles for modern product management.

## Version

**Version:** 2.0 (Agentic Era Update)
**Created:** February 2024
**Updated:** January 2025 (added agent-accelerated discovery guidance)
**Based on:** SVPG articles and frameworks by Marty Cagan

## Usage Notes

- This skill focuses on **requirements definition** first; it can be expanded to cover broader PM topics
- Works best when you engage with the interview questions honestly
- Designed for high freedom (guidance and principles, not rigid checklists)
- Assumes you're working toward empowered team practices
- **Updated for AI agents**: Includes guidance on agent-accelerated discovery (prototyping in days, not weeks)
- **Timeline shift**: Discovery cycles now 2-3x faster with functional prototypes enabling rapid customer validation

## Next Steps

To use this skill:
1. Activate it when defining product requirements
2. Answer the discovery questions thoughtfully
3. Reference the templates and frameworks as needed
4. Use the quality checklists to assess your work

For more on SVPG principles, visit: https://www.svpg.com/articles/

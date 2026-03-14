# Test Scenario: Define Requirements Skill

## Purpose
Validate that the skill correctly guides users through JTBD discovery and produces output ready for github-issue-creator.

## Test Case 1: Basic Feature Request

### Setup
User invokes skill with a feature idea.

### Input
> "I want to add a dashboard that shows meeting statistics"

### Expected Behavior

**Phase 1: Problem Definition**
- Skill should NOT accept this at face value
- Should ask: "What problem are you trying to solve?"
- Should probe for who has this problem and why it matters

**Phase 2: JTBD Interview**
- Should identify functional jobs (e.g., "see how many meetings happened", "track participation trends")
- Should map functionality to each job
- Should offer depth choice (functional only vs emotional/social)

**Phase 3: Checkpoint**
- Should present summary of problem + jobs
- Should wait for explicit confirmation

**Phase 4-6: Analysis**
- Should read CLAUDE.md files
- Should identify relevant existing patterns (dashboards, charts, data fetching)
- Should note database queries needed
- Should provide TDD-focused recommendations

**Phase 7: Final Checkpoint**
- Should present complete summary
- Should ask if ready for GitHub issue

### Success Criteria
- [ ] Never jumped to solution before understanding problem
- [ ] Captured at least 2-3 distinct jobs
- [ ] Mapped functionality to each job
- [ ] Paused at both checkpoints
- [ ] Referenced CLAUDE.md conventions
- [ ] Included specific file paths in recommendations
- [ ] TDD workflow clearly defined

---

## Test Case 2: Security-Sensitive Requirement

### Setup
User requests feature with potential security implications.

### Input
> "I want users to be able to see all meetings across all organizations"

### Expected Behavior

**Security Detection**
- Should immediately flag tenant isolation concern
- Should warn: "This would bypass tenant isolation..."
- Should recommend proper approach (RLS, tenant_id filtering)
- Should NOT proceed without user acknowledgment of security approach

### Success Criteria
- [ ] Security risk identified before codebase analysis
- [ ] Clear warning presented to user
- [ ] Recommended secure alternative
- [ ] Did not proceed blindly

---

## Test Case 3: Anti-Pattern Detection

### Setup
User suggests approach that violates project conventions.

### Input
> "I want to fetch user data directly from the database in the component"

### Expected Behavior

**Anti-Pattern Detection**
- Should identify DAL pattern violation
- Should warn: "This bypasses the DAL pattern..."
- Should recommend: "Use lib/dal/ for all data access"
- Should reference CLAUDE.md conventions

### Success Criteria
- [ ] Anti-pattern identified
- [ ] Referenced project conventions
- [ ] Provided correct approach
- [ ] Did not proceed without adjustment

---

## Test Case 4: Vague Problem

### Setup
User can't articulate the problem clearly.

### Input
> "I want to make the app better"

### Expected Behavior

**Problem Clarification**
- Should NOT accept this as a valid problem
- Should probe: "Can you give me a specific example?"
- Should ask: "What's not working today?"
- Should continue probing until problem is concrete

### Success Criteria
- [ ] Did not proceed with vague problem
- [ ] Asked clarifying questions
- [ ] Eventually extracted specific problem or guided user to think more specifically

---

## Test Case 5: Complete Flow to Handoff

### Setup
User goes through entire flow and confirms at both checkpoints.

### Input
Start: "I need to add the ability to export meeting transcripts as PDF"

### Expected Flow

1. **Problem probing** → User explains need to share transcripts with stakeholders
2. **JTBD interview** → Jobs: share with non-users, archive for records, print for meetings
3. **Checkpoint 1** → User confirms understanding
4. **Codebase analysis** → Identifies transcript storage, PDF libraries, export patterns
5. **Recommendations** → TDD approach, specific files, security (tenant isolation on exports)
6. **Checkpoint 2** → User confirms ready
7. **Handoff** → Invokes github-issue-creator

### Success Criteria
- [ ] Both checkpoints executed
- [ ] User confirmed at each checkpoint
- [ ] Final output contains all necessary context for github-issue-creator
- [ ] TDD workflow included in handoff

---

## Validation Checklist

After running test scenarios, verify:

### Interview Quality
- [ ] One question at a time (not questionnaire dumps)
- [ ] Built on previous answers
- [ ] Offered appropriate choices
- [ ] Used user's language back to them

### Analysis Quality
- [ ] Read CLAUDE.md before analysis
- [ ] Specific file paths with line numbers
- [ ] Database impact assessed
- [ ] Security reviewed
- [ ] Anti-patterns checked

### Output Quality
- [ ] Problem clearly stated
- [ ] Jobs mapped to functionality
- [ ] TDD workflow defined
- [ ] Ready for github-issue-creator consumption

### Checkpoint Behavior
- [ ] Paused after JTBD interview
- [ ] Waited for explicit confirmation
- [ ] Paused before GitHub issue creation
- [ ] Did not proceed without user approval

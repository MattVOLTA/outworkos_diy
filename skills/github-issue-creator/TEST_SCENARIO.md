# Test Scenario: GitHub Issue Creator Skill

## Scenario 1: After Bug Investigation

**User conversation:**
```
User: I'm seeing errors on the network page when there are too many profiles
Agent: [Investigates and finds the issue is in fetchProfiles function]
Agent: I found the issue - it's making too many concurrent requests without rate limiting
User: Can you create a GitHub issue for this fix?
```

**Expected behavior:**
1. Agent activates `github-issue-creator` skill
2. Agent drafts comprehensive issue including:
   - Problem description with error details
   - Root cause analysis (concurrent requests, no rate limiting)
   - Specific file reference: `src/services/profileService.ts:45`
   - Code snippet showing problematic code
   - Proposed solution with implementation details
   - **User Integration section** describing user-facing changes (error states, loading behavior)
   - Testing strategy
3. Agent shows draft to user for approval
4. Agent auto-detects repo: `MattVOLTA/builders`
5. Agent creates issue via `mcp__github__create_issue`
6. Agent returns issue URL: `https://github.com/MattVOLTA/builders/issues/XXX`

## Scenario 2: After Feature Planning

**User conversation:**
```
User: I want to add a "favorite builders" feature to the network page
Agent: [Researches existing patterns, plans implementation]
Agent: I've designed the feature using Supabase for storage and React hooks for state
User: Create a GitHub issue for this
```

**Expected behavior:**
1. Agent activates skill
2. Agent drafts issue including:
   - Feature overview and user story
   - Technical approach (Supabase schema, React components)
   - Database schema changes needed
   - Component architecture
   - Files to create/modify with specific details
   - **User Integration section** with user interaction walkthrough (adding/viewing/removing favorites)
   - Integration with existing network page
   - Acceptance criteria
3. Shows draft for approval
4. Creates issue in GitHub
5. Returns success with issue link

## Scenario 3: After Performance Analysis

**User conversation:**
```
User: The profile page is really slow
Agent: [Profiles the page, finds N+1 query issue]
Agent: The issue is multiple database queries for each portfolio item
User: Document this as a GitHub issue
```

**Expected behavior:**
1. Agent activates skill
2. Agent drafts issue with:
   - Performance metrics (load time data)
   - Profiling results
   - Root cause (N+1 queries in portfolio fetch)
   - Specific query code with line references
   - Optimization strategy (batch loading)
   - **User Integration section** (faster load times, or "No Changes" if invisible optimization)
   - Expected performance improvement
   - Benchmarking approach
3. Gets approval and creates issue

## Success Criteria

The skill works correctly if:
- ✅ Activates when user asks to create GitHub issue
- ✅ Drafts comprehensive issue with all research context
- ✅ Includes specific file references and line numbers
- ✅ **Includes User Integration section** (user interaction walkthrough or "No Changes")
- ✅ Explains WHY decisions were made, not just WHAT to do
- ✅ Shows draft to user before creating
- ✅ Auto-detects repository from git context
- ✅ Successfully creates issue via GitHub MCP tools
- ✅ Returns issue URL to user
- ✅ Another developer could implement from issue alone

## Anti-patterns to Avoid

The skill should NOT:
- ❌ Create brief, vague issues without context
- ❌ Skip the approval step and create immediately
- ❌ Forget to include research findings
- ❌ Miss specific file/line references
- ❌ **Omit User Integration section** (every issue needs this, even if "No Changes")
- ❌ Fail to explain technical decisions
- ❌ Create issues that require redoing research to implement

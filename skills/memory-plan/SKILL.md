---
description: Create and manage implementation plans for multi-session projects. Use for creating plans, tracking progress, marking tasks complete, or viewing current plan status.
---

# Memory Plan

Create, manage, and track implementation plans for multi-session projects.

## Instructions

When this skill is triggered, determine the user's intent:

### Intent: Show Current Plan

If user wants to see the current plan:

1. Read `.claude/plans/active_plan.md`
2. Read `.claude/plans/progress.md`
3. Read `.claude/plans/findings.md`
4. Display summary:

```
Active Plan: [Plan Name]

Status: [In Progress | Blocked | Not Started]
Created: [Date]
Progress: [X]% ([N] of [M] phases complete)

## Phases

Phase 1: Setup (Complete)
   - Set up project structure
   - Configure dependencies

Phase 2: Core Implementation (In Progress)
   - [x] Create data models
   - [x] Implement API endpoints
   - [ ] Add validation
   - [ ] Write tests

Phase 3: Integration (Pending)
   - Connect to external services
   - End-to-end testing

## Recent Findings
- API rate limit is 100 req/min (discovered 2024-01-14)
- Need to handle timezone edge cases

## Blockers
(none)

Commands:
- "complete [task]" - Mark a task done
- "add task" - Add new task to current phase
- "add finding" - Record a discovery
- "block [reason]" - Mark as blocked
- "next phase" - Move to next phase
```

### Intent: Create New Plan

If user wants to create a new plan:

**Step 1: Gather Information**
```
Let's create an implementation plan.

What's the goal of this work?
(e.g., "Add user authentication", "Migrate to PostgreSQL")
```

**Step 2: Define Scope**
```
Got it: "[Goal]"

What are the major phases? I'll help break them down.
(Enter phases one per line, or say "help me figure it out")
```

**Step 3: Break Down Tasks**
For each phase, ask what tasks are needed.

**Step 4: Set Success Criteria**
```
What does "done" look like for this plan?

Success criteria help us know when we're finished:
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Deployed to staging
```

**Step 5: Generate Plan**
Create the plan file at `.claude/plans/active_plan.md`:

```markdown
# Active Plan: [Goal]

**Created**: [DATE]
**Status**: Not Started
**Goal**: [Goal description]

## Overview
[1-2 paragraph description generated from discussion]

## Implementation Steps

### Phase 1: [Name]
- [ ] Task 1.1
- [ ] Task 1.2

### Phase 2: [Name]
- [ ] Task 2.1
- [ ] Task 2.2

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Dependencies
- [Required tools, access, or prerequisites]

## Notes
- [Additional context]
```

### Intent: Update Progress

If user wants to update task status:

**Mark Task Complete**
```
User: complete "Create data models"

Marked complete: Create data models

Phase 2 Progress: 2/4 tasks (50%)
Overall Progress: 5/12 tasks (42%)

Remaining in Phase 2:
- [ ] Add validation
- [ ] Write tests
```

### Intent: Add Finding

If user discovered something during implementation:

```
User: /memory-plan finding: The external API requires OAuth2, not API keys

Added to findings.md:

### OAuth2 Required for External API
> Discovered: 2024-01-15

The external API requires OAuth2, not API keys as originally assumed.

Impact assessment:
- May need to add OAuth2 library
- Consider adding to Phase 3 tasks?
```

### Intent: Manage Blockers

**Add Blocker**
```
User: /memory-plan blocked: waiting for API credentials

Plan marked as BLOCKED

Blocker: Waiting for API credentials
Added: 2024-01-15

When the blocker is resolved, say "unblock" to continue.
```

**Remove Blocker**
```
User: /memory-plan unblock

Blocker resolved: Waiting for API credentials

Plan status: In Progress
Resuming Phase 3: Integration
```

### Intent: Archive/Complete Plan

When work is finished:

```
User: /memory-plan complete

Let's verify the success criteria:
[x] All tests passing
[x] Documentation updated
[x] Deployed to staging

All criteria met!

Archiving plan:
- Moving to: .claude/plans/archive/[date]_[plan-name]/
- Creating completion summary

Would you like to:
1. Add learnings to knowledge base
2. Create a decision record
3. Start a new plan
4. Done
```

## File Paths
- Active plan: `.claude/plans/active_plan.md`
- Progress tracker: `.claude/plans/progress.md`
- Findings: `.claude/plans/findings.md`
- Archive: `.claude/plans/archive/`

## Related Skills
- `/memory-start` - Shows active plan at session start
- `/memory-save` - Updates progress when saving session
- `/memory-knowledge` - Store learnings from plan execution

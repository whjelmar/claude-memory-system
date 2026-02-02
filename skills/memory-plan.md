# Memory Plan Skill

Create, manage, and track implementation plans for multi-session projects.

## Trigger Phrases
- `/memory-plan`
- "create plan", "update plan", "show plan"
- "plan for", "implementation plan"
- "what's the plan", "next steps"
- "mark complete", "update progress"

## Description
This skill manages implementation plans stored in `.claude/plans/`. It helps create structured plans, track progress across sessions, manage findings, and keep work organized for complex multi-step tasks.

## Instructions

When this skill is triggered, determine the user's intent:

### Intent: Show Current Plan

If user wants to see the current plan:

1. Read `.claude/plans/active_plan.md`
2. Read `.claude/plans/progress.md`
3. Read `.claude/plans/findings.md`
4. Display summary:

```
📋 Active Plan: [Plan Name]

Status: [In Progress | Blocked | Not Started]
Created: [Date]
Progress: [X]% ([N] of [M] phases complete)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Phases

✅ Phase 1: Setup (Complete)
   - Set up project structure
   - Configure dependencies

🔄 Phase 2: Core Implementation (In Progress)
   - [x] Create data models
   - [x] Implement API endpoints
   - [ ] Add validation
   - [ ] Write tests

⏳ Phase 3: Integration (Pending)
   - Connect to external services
   - End-to-end testing

⏳ Phase 4: Polish (Pending)
   - Documentation
   - Performance optimization

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Recent Findings
- API rate limit is 100 req/min (discovered 2024-01-14)
- Need to handle timezone edge cases

## Blockers
(none)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
For each phase:
```
Phase 1: [Phase Name]

What tasks are needed for this phase?
(Enter tasks, or I can suggest based on the goal)
```

**Step 4: Set Success Criteria**
```
What does "done" look like for this plan?

Success criteria help us know when we're finished:
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Deployed to staging
```

**Step 5: Generate Plan**
Create the plan file:

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
- [ ] Task 1.3

### Phase 2: [Name]
- [ ] Task 2.1
- [ ] Task 2.2

### Phase 3: [Name]
- [ ] Task 3.1
- [ ] Task 3.2

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Dependencies
- [Required tools, access, or prerequisites]

## Notes
- [Additional context]
```

**Step 6: Confirm**
```
✅ Plan created: .claude/plans/active_plan.md

📋 [Goal]
   [N] phases, [M] total tasks

Phase 1: [Name] - Ready to start

Would you like to:
1. Start working on Phase 1
2. Review the full plan
3. Modify the plan
```

### Intent: Update Progress

If user wants to update task status:

**Mark Task Complete**
```
User: complete "Create data models"

✅ Marked complete: Create data models

Phase 2 Progress: 2/4 tasks (50%)
Overall Progress: 5/12 tasks (42%)

Remaining in Phase 2:
- [ ] Add validation
- [ ] Write tests
```

**Mark Multiple Tasks**
```
User: complete validation and tests

✅ Marked complete:
- Add validation
- Write tests

🎉 Phase 2 Complete!

Ready to start Phase 3: Integration?
```

### Intent: Add Finding

If user discovered something during implementation:

```
User: /memory-plan finding: The external API requires OAuth2, not API keys

📝 Added to findings.md:

### OAuth2 Required for External API
> Discovered: 2024-01-15
> Phase: Integration

The external API requires OAuth2, not API keys as originally assumed.
This may require additional setup time.

---

Impact assessment:
- May need to add OAuth2 library
- Consider adding to Phase 3 tasks?

Options:
1. Add task "Set up OAuth2 authentication" to Phase 3
2. Just log the finding
3. Mark current phase as blocked
```

### Intent: Manage Blockers

**Add Blocker**
```
User: /memory-plan blocked: waiting for API credentials

🚫 Plan marked as BLOCKED

Blocker: Waiting for API credentials
Added: 2024-01-15

Progress paused at Phase 3: Integration

When the blocker is resolved, say "unblock" to continue.
```

**Remove Blocker**
```
User: /memory-plan unblock

✅ Blocker resolved: Waiting for API credentials

Plan status: In Progress
Resuming Phase 3: Integration

Next task: Connect to external services
```

### Intent: Archive/Complete Plan

When work is finished:

```
User: /memory-plan complete

🎉 Congratulations! Let's wrap up this plan.

Verifying success criteria:
✅ All tests passing
✅ Documentation updated
✅ Deployed to staging

All criteria met!

Archiving plan:
- Moving to: .claude/plans/archive/[date]_[plan-name]/
- Creating completion summary

Summary:
- Duration: 5 days (2024-01-10 to 2024-01-15)
- Phases completed: 4/4
- Total tasks: 12
- Key findings: 3 recorded

Would you like to:
1. Create a decision record for major choices made
2. Add learnings to knowledge base
3. Start a new plan
4. Done
```

## File Paths
- Active plan: `.claude/plans/active_plan.md`
- Progress tracker: `.claude/plans/progress.md`
- Findings: `.claude/plans/findings.md`
- Archive: `.claude/plans/archive/`

## Plan Templates

### Simple Plan (< 1 week)
```markdown
# Active Plan: [Task]

**Created**: [DATE]
**Status**: In Progress
**Goal**: [One sentence]

## Tasks
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Done When
- [ ] [Criterion]
```

### Standard Plan (1-2 weeks)
```markdown
# Active Plan: [Feature/Project]

**Created**: [DATE]
**Status**: Not Started
**Goal**: [Description]

## Overview
[Context paragraph]

## Implementation Steps

### Phase 1: [Name]
- [ ] Task
- [ ] Task

### Phase 2: [Name]
- [ ] Task
- [ ] Task

## Success Criteria
- [ ] Criterion
- [ ] Criterion

## Dependencies
- [Dependency]

## Notes
- [Note]
```

### Complex Plan (2+ weeks)
Includes all standard fields plus:
- Risk assessment
- Rollback plan
- Stakeholder sign-offs
- Milestone dates

## Example Interactions

### Example 1: Quick Plan Creation

**User**: `/memory-plan` create plan for adding dark mode

**Claude**:
```
Let's create a plan for adding dark mode.

I'll suggest some phases based on typical dark mode implementations:

Phase 1: Design System Setup
- Define color tokens (light/dark)
- Create theme context/provider
- Set up CSS variables or theme object

Phase 2: Component Updates
- Update base components
- Handle images/icons
- Test contrast ratios

Phase 3: User Preferences
- Add toggle UI
- Persist preference
- System preference detection

Phase 4: Polish
- Transitions between themes
- Edge cases (emails, PDFs, etc.)
- Documentation

Does this structure work, or would you like to modify it?

User: looks good, add testing to phase 2

✅ Plan created with 4 phases, 15 tasks

📋 Dark Mode Implementation
   Ready to start Phase 1: Design System Setup

First task: Define color tokens (light/dark)
```

### Example 2: Progress Update Session

**User**: `/memory-plan`

**Claude**:
```
📋 Active Plan: Dark Mode Implementation

Progress: 40% (6/15 tasks)
Current Phase: 2 - Component Updates

✅ Phase 1: Design System Setup (Complete)
🔄 Phase 2: Component Updates (In Progress)
   - [x] Update base components
   - [ ] Handle images/icons
   - [ ] Test contrast ratios
   - [ ] Run accessibility tests
⏳ Phase 3: User Preferences
⏳ Phase 4: Polish

What would you like to do?
```

**User**: complete images/icons, found issue with SVGs need fill="currentColor"

**Claude**:
```
✅ Marked complete: Handle images/icons

📝 Added finding:
### SVG Color Inheritance
> Discovered: 2024-01-15

SVGs need `fill="currentColor"` to inherit theme colors properly.

Phase 2 Progress: 2/4 tasks (50%)

Remaining:
- [ ] Test contrast ratios
- [ ] Run accessibility tests
```

### Example 3: Completing a Plan

**User**: `/memory-plan` complete

**Claude**:
```
🎉 Let's verify the success criteria:

✅ All components support dark mode
✅ User preference persists
✅ System preference detected
✅ Accessibility audit passed

All criteria met!

📊 Plan Summary
- Duration: 8 days
- Phases: 4/4 complete
- Tasks: 15/15 complete
- Findings: 3 recorded

Key findings that should be preserved:
1. SVG fill="currentColor" pattern
2. CSS custom properties performance
3. localStorage vs cookie for preference

Would you like me to:
1. Add these to the knowledge base
2. Create a decision record
3. Just archive the plan
```

## Related Skills
- `/memory-start` - Shows active plan at session start
- `/memory-save` - Updates progress when saving session
- `/memory-knowledge` - Store learnings from plan execution

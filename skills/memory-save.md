# Memory Save Skill

Save a session summary and update context for the next session.

## Trigger Phrases
- `/memory-save`
- "save session", "end session", "wrap up"
- "save my progress", "save context"
- "create session summary"

## Description
This skill helps save the current session's work by creating a session summary file and updating the current context for the next session. It prompts the user for key information about what was accomplished and supports specialized templates for different work types.

## Session Templates

The memory system includes specialized templates for different types of work sessions. Templates are located in `templates/session-templates/`:

| Template | Use When | Key Sections |
|----------|----------|--------------|
| `bugfix.md` | Fixing bugs | Problem, Investigation, Root Cause, Fix |
| `feature.md` | Building new features | Requirements, Design, Implementation |
| `refactor.md` | Code refactoring | Current State, Plan, Before/After |
| `research.md` | Research/exploration | Questions, Sources, Findings |
| `review.md` | Code reviews | Review Checklist, Feedback, Verdict |
| `planning.md` | Architecture/planning | Goals, Tasks, Timeline, Risks |

## Instructions

When this skill is triggered, perform the following steps:

### Step 0: Select Session Template (Optional)

First, determine if a specialized template should be used:

**Auto-detection rules:**
1. Check recent git commit messages and file changes
2. If commits mention "fix", "bug", "issue" -> suggest `bugfix` template
3. If commits mention "feat", "add", "implement" -> suggest `feature` template
4. If commits mention "refactor", "clean", "reorganize" -> suggest `refactor` template
5. If no commits but many file reads -> suggest `research` template
6. If session context mentions "PR", "review", "MR" -> suggest `review` template
7. If session context mentions "plan", "design", "architecture" -> suggest `planning` template

**Template selection prompt:**
```
What type of session would you like to save?

1. **General** - Standard session summary (default)
2. **Bug Fix** - For debugging and bug fixes
3. **Feature** - For new feature development
4. **Refactor** - For code refactoring work
5. **Research** - For exploration and research
6. **Review** - For code review sessions
7. **Planning** - For architecture and planning

[Auto-detected: Feature based on commit messages]

Enter number or press Enter for auto-detected/general:
```

If user selects a template:
- Load the template from `templates/session-templates/[type].md`
- Pre-fill what can be determined from git activity
- Prompt for template-specific fields

### Step 1: Gather Session Information
Prompt the user for the following information:

**Required:**
1. **Work Completed**: What did you accomplish this session?
2. **Context for Next Session**: What should the next session know to continue?

**Optional (ask if relevant):**
3. **Decisions Made**: Any significant decisions? (offer to create decision record)
4. **Discoveries**: Any important findings about the codebase?
5. **Open Items**: Incomplete tasks or questions to resolve?

Example prompt:
```
To save your session, please provide:

1. **Work Completed** (required): What did you accomplish?
2. **Decisions Made** (optional): Any significant choices?
3. **Discoveries** (optional): Important findings?
4. **Open Items** (optional): Incomplete tasks?
5. **Next Session Context** (required): What should I know to continue?
```

### Step 2: Generate Filename
Create the filename using the current date and time:
- Format: `YYYY-MM-DD_HH-MM_summary.md`
- Example: `2024-01-15_14-30_summary.md`

Use the system's current timestamp.

### Step 3: Create Session Summary File
Create the file in `.claude/memory/sessions/` using this template:

```markdown
# Session Summary: YYYY-MM-DD HH:MM

## Work Completed
- [Items from user input]
- Files modified: `path/to/file`

## Decisions Made
- [Link to decision record if applicable]
- [Or inline decision description]

## Discoveries
- [Important findings about the codebase]

## Open Items
- [ ] [Incomplete tasks]
- [ ] [Questions to resolve]

## Next Session Should
- [Specific actionable items]

## Context for Resume
[Brief state description for next session to pick up]
```

### Step 4: Update Current Context
Update `.claude/memory/current_context.md` with the new context:

```markdown
# Current Working Context

**Last Updated**: [Current date/time]
**Active Task**: [From user input or derived from work completed]

## What I'm Working On
- [Derived from open items and next session context]

## Important State
- [Blockers, dependencies, key conditions]

## Recent Changes
- [Files modified this session]

## Quick Reference
- [Frequently needed info for continuing work]
```

### Step 5: Update Progress (If Plan Exists)
If `.claude/plans/active_plan.md` exists:
- Check off completed items in `.claude/plans/progress.md`
- Update status if appropriate

### Step 6: Confirm Save
Display confirmation to user:

```
## Session Saved

**Summary Created**: `.claude/memory/sessions/YYYY-MM-DD_HH-MM_summary.md`
**Context Updated**: `.claude/memory/current_context.md`

### What Was Saved:
- Work completed: [count] items
- Decisions: [count or "none"]
- Open items: [count] for next session

### Next Session Will See:
[Brief preview of context for resume]

---
Session saved successfully. See you next time!
```

## File Paths
- Sessions directory: `.claude/memory/sessions/`
- Current context: `.claude/memory/current_context.md`
- Progress: `.claude/plans/progress.md`
- Session templates: `templates/session-templates/`

## Template-Specific Prompts

### Bug Fix Template
When using the bugfix template, also ask:
- What was the bug/issue?
- What was the root cause?
- How was it fixed?
- Were regression tests added?

### Feature Template
When using the feature template, also ask:
- What requirements were addressed?
- What design decisions were made?
- What's the testing status?
- What documentation needs updating?

### Refactor Template
When using the refactor template, also ask:
- What code was refactored?
- Why was it refactored?
- Do all tests still pass?
- What improved (metrics if available)?

### Research Template
When using the research template, also ask:
- What questions were you researching?
- What did you learn?
- What sources were useful?
- Should anything be added to knowledge base?

### Review Template
When using the review template, also ask:
- What PR/MR was reviewed?
- What feedback was given?
- What's the review verdict?
- Are there follow-up items?

### Planning Template
When using the planning template, also ask:
- What was being planned?
- What decisions were made?
- What are the key tasks identified?
- What are the risks?

## Error Handling
- If `.claude/memory/sessions/` doesn't exist, create it
- If user provides minimal info, still create the summary with available data
- Warn if context seems incomplete for resuming work

## Example Interaction

**User**: `/memory-save`

**Claude**:
```
To save your session, please provide:

1. **Work Completed** (required): What did you accomplish?
2. **Next Session Context** (required): What should I know to continue?

Optional:
- Decisions made?
- Important discoveries?
- Open items remaining?
```

**User**:
```
1. Implemented JWT refresh endpoint, added rate limiting middleware
2. Need to test refresh flow and add error handling
- Decision: Using sliding window for rate limiting
- Found that the existing auth middleware doesn't handle expired tokens gracefully
- Still need to add Redis connection pooling
```

**Claude** creates files and responds:
```
## Session Saved

**Summary Created**: `.claude/memory/sessions/2024-01-15_16-45_summary.md`
**Context Updated**: `.claude/memory/current_context.md`

### What Was Saved:
- Work completed: 2 items (JWT refresh, rate limiting)
- Decisions: 1 (sliding window rate limiting)
- Discoveries: 1 (auth middleware token handling)
- Open items: 2 (test refresh flow, Redis pooling)

### Next Session Will See:
Continue with testing JWT refresh flow and implementing error handling.
Redis connection pooling still pending.

---
Session saved successfully!
```

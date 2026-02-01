# Memory Save Skill

Save a session summary and update context for the next session.

## Trigger Phrases
- `/memory-save`
- "save session", "end session", "wrap up"
- "save my progress", "save context"
- "create session summary"

## Description
This skill helps save the current session's work by creating a session summary file and updating the current context for the next session. It prompts the user for key information about what was accomplished.

## Instructions

When this skill is triggered, perform the following steps:

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

---
name: memory-start
description: >
  Load context and resume work from the memory system at session start.
  Reads current working context, active plan, and recent sessions.
---

# Memory Start Skill

Load context and resume work from the memory system at session start.

## Trigger Phrases
- `/memory-start`
- "start session", "resume work", "load context"
- "what was I working on"
- "continue from last session"

## Description
This skill reads and displays context from the Claude Memory System to help resume work seamlessly across sessions. It loads the current working context, active plan (if any), and optionally shows recent session summaries.

## Instructions

When this skill is triggered, perform the following steps:

### Step 1: Read Current Context
Read the file `.claude/memory/current_context.md` if it exists.

If the file exists, extract and note:
- Last Updated date
- Active Task description
- What I'm Working On items
- Important State information
- Recent Changes
- Quick Reference items

If the file does not exist, note that no current context is set.

### Step 2: Check for Active Plan
Read the file `.claude/plans/active_plan.md` if it exists.

If the file exists, extract and note:
- Task Name from the title
- Status (Not Started, In Progress, Blocked, Complete)
- Goal description
- Current phase and incomplete steps
- Any blockers or dependencies

If the file does not exist, note that no active plan is in progress.

### Step 3: List Recent Sessions (Optional)
List files in `.claude/memory/sessions/` directory, sorted by date (newest first).

Show the 3-5 most recent session summaries with their dates.

### Step 4: Display Summary
Present a formatted summary to the user:

```
## Session Context Loaded

### Current Focus
[Summary from current_context.md - what we're working on and immediate goals]

### Active Plan
[If exists: Plan name, status, current phase, next steps]
[If not: No active plan in progress]

### Important State
[Key blockers, dependencies, or conditions to be aware of]

### Recent Sessions
[List of recent session files with dates]

### Suggested Next Steps
[Based on context and plan, suggest what to work on]

---
Ready to continue. What would you like to work on?
```

## File Paths
- Context: `.claude/memory/current_context.md`
- Plan: `.claude/plans/active_plan.md`
- Sessions: `.claude/memory/sessions/`
- Progress: `.claude/plans/progress.md`

## Error Handling
- If `.claude/memory/` directory doesn't exist, inform user the memory system needs to be set up first
- If context file is empty or missing, offer to help create initial context
- Continue gracefully if optional files (plan, sessions) don't exist

## Example Output

```
## Session Context Loaded

### Current Focus
Implementing user authentication system. Immediate goals:
- Complete JWT token refresh logic
- Add password reset endpoint

### Active Plan
**Task**: Authentication System Implementation
**Status**: In Progress (Phase 2 of 3)
**Next Steps**:
- [ ] Implement token refresh endpoint
- [ ] Add rate limiting to auth routes

### Important State
- Blocked on: Waiting for Redis connection string from DevOps
- Dependencies: redis, jsonwebtoken packages installed

### Recent Sessions
- 2024-01-15_14-30_summary.md - Completed login/logout endpoints
- 2024-01-14_10-00_summary.md - Set up auth middleware
- 2024-01-13_16-45_summary.md - Database schema design

### Suggested Next Steps
Continue with token refresh implementation, or resolve Redis blocker first.

---
Ready to continue. What would you like to work on?
```

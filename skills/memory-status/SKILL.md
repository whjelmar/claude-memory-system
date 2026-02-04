---
description: Show current memory system status including context, plans, sessions, and decisions. Use to check what's stored or verify memory state.
---

# Memory Status

Display the current state of the memory system.

## Instructions

When this skill is triggered, gather and display information about the memory system:

### Step 1: Check Directory Structure
Verify these directories exist:
- `.claude/memory/`
- `.claude/memory/sessions/`
- `.claude/memory/decisions/`
- `.claude/memory/knowledge/`
- `.claude/plans/`

### Step 2: Gather Statistics
Count files in each directory:
- Number of session summaries
- Number of decision records
- Number of knowledge files

### Step 3: Read Current Context
Read `.claude/plans/active_plan.md` if it exists and extract:
- Plan name
- Current status
- Progress percentage

### Step 4: Get Recent Activity
List the 3 most recent files by modification date across:
- Sessions
- Decisions
- Knowledge

### Step 5: Display Status
Present a formatted status report:

```
## Memory System Status

### Structure
- Memory directory: [exists/missing]
- Plans directory: [exists/missing]
- Sessions: [N] files
- Decisions: [N] files
- Knowledge: [N] files

### Current Context
[Summary from current_context.md or "Not set"]

### Active Plan
[Plan name and progress or "No active plan"]

### Recent Activity
- [date] [type]: [filename]
- [date] [type]: [filename]
- [date] [type]: [filename]

### Health
[Any warnings about missing files, empty directories, etc.]
```

## File Paths
- Memory: `.claude/memory/`
- Plan: `.claude/plans/active_plan.md`
- Progress: `.claude/plans/progress.md`
- Sessions: `.claude/memory/sessions/`
- Decisions: `.claude/memory/decisions/`
- Knowledge: `.claude/memory/knowledge/`

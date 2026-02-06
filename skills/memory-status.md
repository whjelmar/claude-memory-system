---
name: memory-status
description: >
  Show the current state of the memory system including context summary,
  active plan status, file counts, and recent activity.
---

# Memory Status Skill

Show the current state of the memory system.

## Trigger Phrases
- `/memory-status`
- "memory status", "show memory state"
- "what's in memory", "memory overview"
- "check memory system"

## Description
This skill provides a comprehensive overview of the current memory system state, including context summary, active plan status, file counts, and recent activity.

## Instructions

When this skill is triggered, perform the following steps:

### Step 1: Read Current Context
Read `.claude/memory/current_context.md` and extract:
- Last Updated timestamp
- Active Task
- Current focus items

### Step 2: Check Active Plan
Read `.claude/plans/active_plan.md` if it exists and extract:
- Plan name and status
- Completion percentage (count checked vs unchecked items)
- Current phase

### Step 3: Count Memory Files
Count files in each memory directory:

| Directory | Path | Count |
|-----------|------|-------|
| Sessions | `.claude/memory/sessions/` | [count] files |
| Decisions | `.claude/memory/decisions/` | [count] files |
| Knowledge | `.claude/memory/knowledge/` | [count] files |

### Step 4: Analyze Recent Activity
List the 5 most recently modified files across all memory directories with their modification dates.

### Step 5: Display Status Report
Present a formatted status report:

```
## Memory System Status

### Current Context
**Last Updated**: [date/time]
**Active Task**: [task description]
**Focus**: [current focus items, brief]

### Active Plan
[If exists:]
**Plan**: [name]
**Status**: [status] ([X]% complete)
**Phase**: [current phase]
**Remaining**: [count] tasks

[If not exists:]
No active plan in progress.

### Memory Contents
| Category | Files | Latest |
|----------|-------|--------|
| Sessions | [n] | [date of newest] |
| Decisions | [n] | [date of newest] |
| Knowledge | [n] | [date of newest] |

### Recent Activity
1. [filename] - [date] - [type: session/decision/knowledge]
2. [filename] - [date] - [type]
3. [filename] - [date] - [type]
4. [filename] - [date] - [type]
5. [filename] - [date] - [type]

### System Health
- [x] Memory directory exists
- [x] Current context file present
- [x/o] Active plan present
- [x/o] Sessions directory has files
- [x/o] Decisions directory has files

---
Memory system is [healthy/needs attention].
```

## File Paths
- Memory root: `.claude/memory/`
- Context: `.claude/memory/current_context.md`
- Sessions: `.claude/memory/sessions/`
- Decisions: `.claude/memory/decisions/`
- Knowledge: `.claude/memory/knowledge/`
- Plan: `.claude/plans/active_plan.md`
- Progress: `.claude/plans/progress.md`

## Error Handling
- If memory directory doesn't exist, report "Memory system not initialized"
- If directories are empty, show 0 count (not an error)
- If context file is missing or empty, note it needs setup

## Example Output

```
## Memory System Status

### Current Context
**Last Updated**: 2024-01-15 14:30
**Active Task**: Authentication System Implementation
**Focus**: JWT refresh endpoint, rate limiting

### Active Plan
**Plan**: Authentication System Implementation
**Status**: In Progress (67% complete)
**Phase**: Phase 2 - Token Management
**Remaining**: 4 tasks

### Memory Contents
| Category | Files | Latest |
|----------|-------|--------|
| Sessions | 12 | 2024-01-15 |
| Decisions | 3 | 2024-01-14 |
| Knowledge | 5 | 2024-01-10 |

### Recent Activity
1. 2024-01-15_14-30_summary.md - Jan 15 - session
2. 0003_rate_limiting_strategy.md - Jan 14 - decision
3. 2024-01-14_10-00_summary.md - Jan 14 - session
4. auth_patterns.md - Jan 12 - knowledge
5. 0002_token_storage.md - Jan 12 - decision

### System Health
- [x] Memory directory exists
- [x] Current context file present
- [x] Active plan present
- [x] Sessions directory has files (12)
- [x] Decisions directory has files (3)

---
Memory system is healthy.
```

## Quick Status (Compact Mode)
If user asks for "quick status" or "brief status", show compact version:

```
## Memory Quick Status

Context: Authentication System (updated Jan 15)
Plan: Auth Implementation - 67% complete
Files: 12 sessions, 3 decisions, 5 knowledge
Last activity: 2024-01-15_14-30_summary.md

Status: Healthy
```

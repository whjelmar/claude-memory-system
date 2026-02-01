# Persistent Memory System Architecture

## Overview

This system provides session-to-session memory and context continuity for Claude Code. It combines multiple layers of memory with different purposes and lifespans.

## Directory Structure

```
.claude/
├── memory/
│   ├── ARCHITECTURE.md      # This file
│   ├── USAGE.md             # Usage guide and templates
│   ├── current_context.md   # Active working context (updated each session)
│   ├── sessions/
│   │   └── YYYY-MM-DD_HH-MM_summary.md  # Session summaries
│   ├── decisions/
│   │   └── NNNN_decision_slug.md        # Decision records
│   └── knowledge/
│       └── {topic}.md                    # Accumulated knowledge
└── plans/
    ├── active_plan.md       # Current implementation plan
    ├── findings.md          # Research and discoveries
    └── progress.md          # Task completion status
```

## Memory Layers

### Layer 1: CLAUDE.md (Project Conventions)
- **Location**: Project root
- **Lifespan**: Permanent, version controlled
- **Purpose**: Coding standards, APIs, patterns, gotchas
- **Update frequency**: After significant discoveries
- **Auto-loaded**: Yes (by Claude Code)

### Layer 2: Current Context (.claude/memory/current_context.md)
- **Location**: .claude/memory/
- **Lifespan**: Overwritten each session
- **Purpose**: "What I'm working on right now"
- **Update frequency**: Start and end of each session

### Layer 3: Session Summaries (.claude/memory/sessions/)
- **Location**: .claude/memory/sessions/
- **Lifespan**: Permanent archive
- **Purpose**: Historical record, context recovery
- **Update frequency**: End of each session
- **Format**: `YYYY-MM-DD_HH-MM_summary.md`

### Layer 4: Decision Log (.claude/memory/decisions/)
- **Location**: .claude/memory/decisions/
- **Lifespan**: Permanent
- **Purpose**: Why we chose X over Y
- **Update frequency**: When significant decisions are made
- **Format**: `NNNN_decision_slug.md`

### Layer 5: Knowledge Base (.claude/memory/knowledge/)
- **Location**: .claude/memory/knowledge/
- **Lifespan**: Permanent, evolving
- **Purpose**: Accumulated domain knowledge
- **Update frequency**: As knowledge is discovered

### Layer 6: Active Plans (.claude/plans/)
- **Location**: .claude/plans/
- **Lifespan**: Until task complete
- **Purpose**: Current task tracking
- **Files**:
  - `active_plan.md` - Implementation steps
  - `findings.md` - Research results
  - `progress.md` - What's done/blocked

## Usage Patterns

### Starting a Session
1. Claude reads CLAUDE.md (automatic)
2. Claude reads .claude/memory/current_context.md
3. Claude reads .claude/plans/active_plan.md if exists

### During a Session
1. Update progress.md as tasks complete
2. Log decisions to decisions/ as they're made
3. Update knowledge/ when significant learning occurs

### Ending a Session
1. Create session summary in sessions/
2. Update current_context.md for next session
3. Update CLAUDE.md if patterns discovered
4. Update active_plan.md with remaining work

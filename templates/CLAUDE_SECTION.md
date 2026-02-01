## Session Continuity System

This project uses a file-based memory system for cross-session context preservation.

**Before starting work, read:**
- `.claude/memory/current_context.md` - What we're working on
- `.claude/plans/active_plan.md` - Current plan (if exists)

**Before ending a session:**
1. Create summary in `.claude/memory/sessions/YYYY-MM-DD_HH-MM_summary.md`
2. Update `.claude/memory/current_context.md` for next session
3. Update this CLAUDE.md if new patterns were discovered

**Directory structure:**
```
.claude/
├── memory/
│   ├── current_context.md   # Active working context
│   ├── sessions/            # Session summaries
│   ├── decisions/           # Decision records (ADRs)
│   └── knowledge/           # Domain knowledge
└── plans/
    ├── active_plan.md       # Current implementation plan
    ├── findings.md          # Research discoveries
    └── progress.md          # Task progress tracker
```

**Relevant skills:**
- `/project-workflow` - Session management commands including `/wrap-session`
- `/planning-with-files` - Manus-style task planning
- `/executing-plans` - Resume work from a previous plan

**For parallel work:**
```python
# Spawn research agents in background
Task(subagent_type="Explore", prompt="...", run_in_background=True)
Task(subagent_type="Plan", prompt="...", run_in_background=True)
```

See `.claude/memory/USAGE.md` for full documentation.

# Memory System Usage Guide

## Quick Start

### Starting a Session
At the start of each session, Claude should:
1. Read `.claude/memory/current_context.md` for active context
2. Read `.claude/plans/active_plan.md` if working on a complex task
3. Optionally scan recent sessions in `.claude/memory/sessions/`

### During a Session
- Update `progress.md` as tasks complete
- Add findings to `findings.md` when discovering important information
- Create decision records for significant choices

### Ending a Session
Create a session summary by:
1. Creating a file in `.claude/memory/sessions/` with format `YYYY-MM-DD_HH-MM_summary.md`
2. Updating `.claude/memory/current_context.md` with next-session context
3. If using a plan, updating `.claude/plans/progress.md`

---

## File Templates

### Session Summary Template
```markdown
# Session Summary: YYYY-MM-DD HH:MM

## Work Completed
- [Brief description of accomplishments]
- Files modified: `path/to/file`

## Decisions Made
- [Link to decision record if applicable]

## Discoveries
- [Important findings about the codebase]

## Open Items
- [ ] Incomplete task
- [ ] Question to resolve

## Next Session Should
- [Specific actionable item]

## Context for Resume
[Brief state description for next session to pick up]
```

### Decision Record Template
```markdown
# Decision NNNN: Title

**Date**: YYYY-MM-DD
**Status**: Accepted | Superseded | Deprecated

## Context
[What issue are we facing?]

## Options Considered
1. **Option A**: Description
   - Pros: ...
   - Cons: ...

## Decision
[What we chose and why]

## Consequences
[What changes as a result]
```

---

## Commands & Skills Integration

### Existing Skills to Use
- `/project-workflow` - Full project lifecycle commands
- `/wrap-session` - Session wrap-up (from project-workflow)
- `/planning-with-files` - Create task_plan.md, findings.md, progress.md
- `/executing-plans` - Resume work from a plan

### Parallel Agent Orchestration
Spawn multiple agents for parallel research:
```python
Task(subagent_type="Explore", prompt="...", run_in_background=True)
Task(subagent_type="Plan", prompt="...", run_in_background=True)
```

Check results with `TaskOutput(task_id="...", block=False)`.

---

## Best Practices

1. **Keep context focused**: Don't let files grow too large
2. **Prune old sessions**: Archive or delete sessions older than 30 days
3. **Link decisions**: Reference decision records from session summaries
4. **Update CLAUDE.md**: Add new patterns to main CLAUDE.md when stable
5. **Version control**: Commit memory files to git for history

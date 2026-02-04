---
description: Review session history, decisions, and project progress over time. Use for weekly reviews, standups, retrospectives, or understanding past work.
---

# Memory Review

Review and analyze session history, decisions, and project progress over time.

## Instructions

When this skill is triggered, determine the user's intent:

### Intent: Recent Activity Overview

Default view when no specific request:

```
Memory Review

Period: Last 7 days (2024-01-08 to 2024-01-15)

## Sessions: 8 recorded

| Date | Duration | Focus | Key Outcome |
|------|----------|-------|-------------|
| Jan 15 | 2.5h | Auth refactor | Completed token refresh |
| Jan 14 | 1.5h | Auth refactor | Fixed race condition |
| Jan 13 | 3h | Auth refactor | Started Phase 2 |
| Jan 12 | 2h | Bug fixes | Resolved 3 issues |

## Decisions: 3 made

- #0005: Exponential backoff for retries (Jan 14)
- #0004: Token bucket rate limiting (Jan 12)
- #0003: PostgreSQL for session storage (Jan 10)

## Knowledge: 2 updates

- authentication.md: Added rate limiting section
- api-patterns.md: Added retry patterns

Commands:
- "details [date]" - Show specific session
- "decision [number]" - Review a decision
- "this week" / "last week" / "this month"
- "search [query]" - Find in history
- "standup" - Generate standup summary
- "retro" - Generate retrospective notes
```

### Intent: Time-Based Review

**This Week / Last Week / This Month**

Generate summary for the specified period including:
- Session count and total time
- Main focus areas
- Accomplishments
- Decisions made
- Discoveries
- Blockers encountered

### Intent: Generate Standup Summary

If user asks for standup:

```
## Standup Summary

**Yesterday**:
- Completed token refresh implementation
- Fixed race condition in auth middleware
- Added retry logic with exponential backoff

**Today**:
- Continue Phase 2: Token rotation
- Write tests for refresh flow
- Start Redis connection pooling

**Blockers**:
- None currently
```

### Intent: Generate Retrospective

If user asks for retro/retrospective:

```
## Retrospective: Auth Refactor

### What Went Well
- Clear plan helped track progress
- Decision records captured rationale
- Finding about race condition saved debugging time later

### What Could Be Improved
- Underestimated complexity of token rotation
- Should have checked API rate limits earlier

### Action Items
- [ ] Add API limit checking to research phase
- [ ] Create template for concurrent code review

### Key Learnings
- Always check for race conditions in token handling
- Token bucket is better than fixed window for rate limiting
```

### Intent: Review Specific Decision

If user asks about a specific decision:

1. Read the decision file
2. Show full content with formatting
3. Note if it has been superseded

### Intent: Search History

If user wants to find something:

Delegate to `/memory-search` skill.

## File Paths
- Sessions: `.claude/memory/sessions/`
- Decisions: `.claude/memory/decisions/`
- Knowledge: `.claude/memory/knowledge/`

## Related Skills
- `/memory-search` - Search across memory files
- `/memory-status` - Current state overview

# Memory Review Skill

Review and analyze session history, decisions, and project progress over time.

## Trigger Phrases
- `/memory-review`
- "review sessions", "session history"
- "what did we do", "summary of work"
- "review decisions", "decision history"
- "weekly review", "project review"
- "what happened last week"

## Description
This skill provides tools for reviewing past work, analyzing patterns in sessions and decisions, and generating summaries for standups, retrospectives, or documentation. It helps answer questions like "What did we accomplish?" and "Why did we make that choice?"

## Instructions

When this skill is triggered, determine the user's intent:

### Intent: Recent Activity Overview

Default view when no specific request:

```
📊 Memory Review

Period: Last 7 days (2024-01-08 to 2024-01-15)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Sessions: 8 recorded

| Date | Duration | Focus | Key Outcome |
|------|----------|-------|-------------|
| Jan 15 | 2.5h | Auth refactor | Completed token refresh |
| Jan 14 | 1.5h | Auth refactor | Fixed race condition |
| Jan 13 | 3h | Auth refactor | Started Phase 2 |
| Jan 12 | 2h | Bug fixes | Resolved 3 issues |
| Jan 11 | 1h | Planning | Created auth plan |
| ... | | | |

## Decisions: 3 made

- #0005: Exponential backoff for retries (Jan 14)
- #0004: Token bucket rate limiting (Jan 12)
- #0003: PostgreSQL for session storage (Jan 10)

## Knowledge: 2 updates

- authentication.md: Added rate limiting section
- api-patterns.md: Added retry patterns

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commands:
- "details [date]" - Show specific session
- "decision [number]" - Review a decision
- "this week" / "last week" / "this month"
- "search [query]" - Find in history
- "standup" - Generate standup summary
- "retro" - Generate retrospective notes
```

### Intent: Time-Based Review

**This Week**
```
User: /memory-review this week

📅 This Week's Review (Jan 13 - Jan 19)

## Summary
- 5 sessions, ~12 hours of work
- Focus: Authentication refactor (80%)
- 2 decisions made
- 1 blocker encountered and resolved

## Accomplishments
✅ Completed Phase 1 of auth refactor
✅ Fixed token refresh race condition
✅ Implemented rate limiting
✅ Added retry logic with exponential backoff

## In Progress
🔄 Phase 2: Token rotation (60% complete)

## Decisions Made
- #0005: Exponential backoff for retries
  → Chose over fixed delay for better UX
- #0004: Token bucket rate limiting
  → Handles bursts gracefully

## Discoveries
- Auth endpoint has 5-second rate limit (undocumented)
- Token refresh needs mutex lock for concurrency

## Blockers
- [Resolved] Waiting for staging environment access

## Next Week
- Complete Phase 2
- Start Phase 3: Integration tests
```

**Last Month**
```
User: /memory-review last month

📅 December 2023 Review

## Overview
- 24 sessions recorded
- 8 decisions made
- 3 major features completed

## Major Milestones
✅ Week 1: Payment integration (Stripe)
✅ Week 2: User dashboard redesign
✅ Week 3: Performance optimization
✅ Week 4: Holiday break / bug fixes

## Key Decisions
- #0001: Stripe over PayPal (cost, API quality)
- #0002: React Query for data fetching
- #0003: PostgreSQL for session storage
[... 5 more]

## Knowledge Base Growth
+5 new topics, 12 updates to existing

## Patterns Observed
- Most productive: Tuesday/Wednesday mornings
- Common blockers: Waiting for external dependencies
- Avg session: 2.1 hours

[Full report: .claude/memory/reports/2023-12-review.md]
```

### Intent: Session Details

View a specific session:

```
User: /memory-review session Jan 14

📋 Session: January 14, 2024 (2:30 PM)

Duration: ~1.5 hours
Focus: Auth refactor - Token refresh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Work Completed
- Identified race condition in token refresh
- Implemented mutex lock for concurrent refresh
- Added exponential backoff retry logic
- Updated unit tests for new behavior

## Decisions Made
- Use exponential backoff instead of fixed delay
  (see decision #0005)

## Discoveries
- Token endpoint has undocumented 5-second rate limit

## Context at End
Ready for Phase 3. All tests passing. Token refresh
now stable with retry logic.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Previous session: Jan 13 (Auth refactor start)
Next session: Jan 15 (Completed token work)
```

### Intent: Decision Review

Review decisions with context:

```
User: /memory-review decisions about authentication

🔍 Decisions related to "authentication"

Found 3 decisions:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Decision #0005: Exponential Backoff for Retries
Date: January 14, 2024
Status: Accepted

Context: Token refresh failing under load due to rate limits

Options considered:
1. Fixed delay (simple but poor UX)
2. Exponential backoff (chosen - better UX)
3. No retry (rejected - too fragile)

Consequence: More resilient auth, slight complexity increase

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### Decision #0003: PostgreSQL for Session Storage
Date: January 10, 2024
Status: Accepted

Context: Need persistent session storage for auth tokens

Options considered:
1. Redis (fast but volatile)
2. PostgreSQL (chosen - persistent, familiar)
3. MongoDB (rejected - overkill)

Consequence: Added PostgreSQL dependency, simpler ops

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View full decision: "show decision 5"
```

### Intent: Generate Standup Summary

```
User: /memory-review standup

📢 Standup Summary
Generated: January 15, 2024

## Yesterday
- Fixed token refresh race condition
- Implemented exponential backoff retry
- Updated unit tests (all passing)

## Today
- Continue Phase 2: Token rotation
- Add refresh token invalidation
- Start integration tests if time

## Blockers
None currently

---

Copy-paste ready:
Yesterday: Fixed token refresh race condition with mutex lock,
added exponential backoff retry. All tests passing.

Today: Continuing with token rotation, then integration tests.

No blockers.
```

### Intent: Generate Retrospective Notes

```
User: /memory-review retro

📝 Retrospective Notes
Sprint: Auth Refactor (Jan 10 - Jan 17)

## What Went Well
✅ Clear plan helped maintain focus
✅ Decision records prevented backtracking
✅ Knowledge base captured learnings effectively
✅ Phase-based approach kept progress visible

## What Could Improve
⚠️ Underestimated complexity of token refresh
⚠️ Should have investigated rate limits earlier
⚠️ Missing test coverage for edge cases initially

## Key Learnings
📚 Added to knowledge base:
- Authentication rate limiting patterns
- Mutex patterns for async operations
- Exponential backoff implementation

## Metrics
- Planned: 12 tasks
- Completed: 10 tasks
- Added mid-sprint: 3 tasks
- Decisions made: 3
- Blockers: 1 (resolved in 4 hours)

## Action Items for Next Sprint
- [ ] Add rate limit detection earlier in process
- [ ] Include edge case testing in initial estimates
- [ ] Set up monitoring before starting feature work
```

### Intent: Search History

```
User: /memory-review search "rate limit"

🔍 Search Results: "rate limit"

Found 8 matches across sessions, decisions, and knowledge:

## Sessions (4 matches)
- Jan 14: "Fixed rate limit issue in token refresh..."
- Jan 13: "Discovered rate limit on auth endpoint..."
- Jan 12: "Discussed rate limiting approaches..."
- Jan 10: "Planning: need to handle rate limits..."

## Decisions (2 matches)
- #0005: Exponential backoff (rate limit context)
- #0004: Token bucket rate limiting

## Knowledge (2 matches)
- authentication.md: Rate limiting section
- api-patterns.md: Rate limit handling patterns

View details: "show session Jan 14" or "show decision 5"
```

### Intent: Compare Periods

```
User: /memory-review compare this week vs last week

📊 Week Comparison

                    This Week    Last Week
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sessions            5            7
Total hours         ~12h         ~15h
Decisions           2            3
Knowledge updates   4            2
Blockers            1            0
Tasks completed     8            10

## Focus Areas
This week: Auth refactor (80%), Bug fixes (20%)
Last week: Auth refactor (60%), Planning (40%)

## Velocity
Slight decrease due to complexity of token refresh.
Quality focus over quantity.

## Notable Changes
+ More knowledge captured this week
- One blocker (resolved same day)
= Decision rate consistent
```

## File Paths
- Sessions: `.claude/memory/sessions/`
- Decisions: `.claude/memory/decisions/`
- Knowledge: `.claude/memory/knowledge/`
- Generated reports: `.claude/memory/reports/`

## Report Generation

For longer reviews, generate a markdown report:

```
User: /memory-review generate monthly report

📄 Generating December 2023 report...

Report saved to: .claude/memory/reports/2023-12-review.md

Preview:
---
# Monthly Review: December 2023

## Executive Summary
This month focused on three major initiatives...

[Full report is 45 lines]
---

Would you like me to display the full report?
```

## Example Interactions

### Example 1: Quick Daily Review

**User**: `/memory-review` yesterday

**Claude**:
```
📅 Yesterday: January 14, 2024

1 session recorded (2:30 PM, ~1.5 hours)

## Completed
- Fixed token refresh race condition
- Added exponential backoff retry
- Updated unit tests

## Decisions
- #0005: Exponential backoff for retries

## Discovered
- Auth endpoint has 5-sec rate limit

Ready for today's work?
```

### Example 2: Decision Archaeology

**User**: why did we choose PostgreSQL for sessions?

**Claude**:
```
🔍 Found relevant decision:

Decision #0003: PostgreSQL for Session Storage
Date: January 10, 2024

## Context
We needed persistent storage for auth tokens that survives
server restarts. The team evaluated three options.

## Why PostgreSQL
- ✅ Persistent by default (unlike Redis)
- ✅ Team already familiar with it
- ✅ Can use same connection as main DB
- ✅ Simpler ops than adding new datastore

## Why Not Others
- Redis: Fast but volatile, need persistence config
- MongoDB: Overkill for simple key-value sessions

## Outcome
Working well. Session queries add ~2ms latency which
is acceptable for our use case.

Related session: Jan 10, planning meeting
```

### Example 3: Preparing for 1:1

**User**: `/memory-review` last 2 weeks for my 1:1

**Claude**:
```
📋 Two-Week Summary for 1:1
January 1-15, 2024

## Accomplishments
1. Completed Stripe payment integration
2. Shipped user dashboard v2
3. Started auth refactor (60% complete)

## Challenges
- Token refresh complexity higher than estimated
- Waited 4 hours for staging access (resolved)

## Decisions Made
- Stripe over PayPal (better API, lower fees)
- PostgreSQL for sessions (simplicity)
- Exponential backoff for retries (reliability)

## Learnings
- Rate limiting patterns
- Async mutex for concurrency
- Webhook verification best practices

## Goals for Next 2 Weeks
- Complete auth refactor
- Begin API v2 planning
- Reduce technical debt backlog

## Discussion Points
- Need earlier access to staging environments
- Consider adding rate limit monitoring
- Auth refactor taking longer - adjust sprint capacity?
```

## Related Skills
- `/memory-search` - Search specific terms in history
- `/memory-status` - Quick current state view
- `/memory-save` - Creates the sessions being reviewed

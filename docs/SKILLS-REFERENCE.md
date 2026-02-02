# Slash Commands Reference

Complete reference for all slash commands provided by the Claude Memory System.

---

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Command Reference](#command-reference)
   - [/memory-start](#memory-start)
   - [/memory-save](#memory-save)
   - [/memory-status](#memory-status)
   - [/memory-decide](#memory-decide)
   - [/memory-search](#memory-search)
   - [/memory-knowledge](#memory-knowledge)
   - [/memory-plan](#memory-plan)
   - [/memory-review](#memory-review)
4. [Tips & Tricks](#tips--tricks)

---

## Overview

The Claude Memory System provides 8 slash commands for managing session memory:

### Core Commands (Session Lifecycle)

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/memory-start` | Load context at session start | Beginning of every session |
| `/memory-save` | Save session summary | End of every session |
| `/memory-status` | View memory system state | Anytime to check status |
| `/memory-decide` | Record a decision (ADR) | When making significant choices |

### Extended Commands (Knowledge & Planning)

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/memory-search` | Search across memory files | Finding past decisions or context |
| `/memory-knowledge` | Manage knowledge base | Adding/viewing domain learnings |
| `/memory-plan` | Create and track plans | Multi-session projects |
| `/memory-review` | Review history & reports | Standups, retros, 1:1s |

---

## Installation

### Copy Skills to Claude Code

```bash
# Linux/macOS
cp -r ~/.claude/templates/claude-memory-system/skills/* ~/.claude/skills/

# Windows PowerShell
Copy-Item -Recurse "$env:USERPROFILE\.claude\templates\claude-memory-system\skills\*" "$env:USERPROFILE\.claude\skills\"
```

### Verify Installation

After copying, the commands should be available in Claude Code. Test with:

```
You: /memory-status
```

---

## Command Reference

### /memory-start

**Purpose:** Load context from the previous session to resume work seamlessly.

**Trigger phrases:**
- `/memory-start`
- "start session"
- "resume work"
- "what was I working on"
- "load context"

#### What It Does

1. Reads `.claude/memory/current_context.md`
2. Reads `.claude/plans/active_plan.md` (if exists)
3. Lists recent sessions from `.claude/memory/sessions/`
4. Displays formatted summary

#### Output Format

```
📋 Current Context
Last Updated: 2026-02-01 16:45

Active Task: User authentication refactor
Focus: Implementing token refresh logic

What I'm Working On:
• Token refresh race condition fix
• Adding retry logic with exponential backoff

Important State:
• Using test environment (staging API)
• Feature flag AUTH_V2 is enabled

─────────────────────────────────────────

📊 Active Plan: auth-refactor
Status: In Progress (Phase 2 of 4)

Phase 1: Extract auth module ✅
Phase 2: Implement token flow 🔄 (current)
Phase 3: Refresh token rotation ⏳
Phase 4: Integration tests ⏳

─────────────────────────────────────────

📚 Recent Sessions (last 5)
• 2026-02-01 14:30 - Fixed token validation, started refresh work
• 2026-01-31 16:00 - Completed module extraction
• 2026-01-31 10:15 - Started auth refactor project
• 2026-01-30 15:45 - Planning session for auth work
• 2026-01-30 09:00 - Wrapped up previous feature

─────────────────────────────────────────

💡 Suggested Next Steps:
1. Continue with token refresh implementation
2. Check if race condition fix is working
3. Review open items from last session
```

#### Options

**Quick mode** - Just shows current context without history:
```
You: /memory-start quick
```

**With specific session** - Shows details from a past session:
```
You: /memory-start session 2026-01-30
```

#### Best Practices

1. **Always run at session start** - Even if you remember what you were doing, Claude doesn't
2. **Review before diving in** - Take 30 seconds to orient yourself
3. **Update if stale** - If context is outdated, update it before starting work

---

### /memory-save

**Purpose:** Save a session summary and update context for the next session.

**Trigger phrases:**
- `/memory-save`
- "save session"
- "end session"
- "wrap up"
- "save progress"

#### What It Does

1. Prompts for session details (work completed, decisions, etc.)
2. Creates timestamped session file in `.claude/memory/sessions/`
3. Updates `.claude/memory/current_context.md`
4. Optionally creates decision records

#### Interactive Flow

```
You: /memory-save

Claude: Let's save this session. What work did you complete?

You: - Fixed the token refresh race condition
     - Added mutex lock for concurrent refresh
     - Implemented exponential backoff retry
     - Updated unit tests

Claude: Were any significant decisions made that should be recorded?

You: Yes, decided to use exponential backoff instead of fixed delay

Claude: What discoveries or learnings should be noted?

You: Found that the auth endpoint has an undocumented 5-second rate limit

Claude: Any open items or blockers for next session?

You: None, ready to move to Phase 3

Claude: What should the next session focus on?

You: Start implementing refresh token rotation (Phase 3)

Claude: ✅ Session saved!

Created:
• .claude/memory/sessions/2026-02-01_16-45_summary.md

Updated:
• .claude/memory/current_context.md

Would you like me to create a decision record for the
exponential backoff choice?

You: Yes

Claude: ✅ Created .claude/memory/decisions/0003_exponential_backoff_retry.md
```

#### Quick Mode

For shorter sessions, use quick mode with inline input:

```
You: /memory-save quick "Fixed token refresh bug, moving to Phase 3"

Claude: ✅ Quick session saved!
• Session: .claude/memory/sessions/2026-02-01_16-45_summary.md
• Context updated for next session
```

#### Generated Files

**Session Summary (sessions/2026-02-01_16-45_summary.md):**
```markdown
# Session Summary: 2026-02-01 16:45

## Work Completed
- Fixed the token refresh race condition
- Added mutex lock for concurrent refresh
- Implemented exponential backoff retry
- Updated unit tests

## Decisions Made
- Use exponential backoff instead of fixed delay
  (see decision 0003)

## Discoveries
- Auth endpoint has undocumented 5-second rate limit

## Open Items
(none)

## Next Session Should
- Start implementing refresh token rotation (Phase 3)

## Context for Resume
Auth refactor Phase 2 complete. Token refresh now stable
with mutex lock and retry logic. Ready for Phase 3.
```

**Updated Context (current_context.md):**
```markdown
# Current Working Context

**Last Updated**: 2026-02-01 16:45
**Active Task**: Auth refactor - Phase 3

## What I'm Working On
- Refresh token rotation implementation
- Building on completed Phase 2 work

## Important State
- Token refresh now stable (Phase 2 complete)
- Mutex lock in place for concurrent refresh
- All Phase 2 tests passing

## Recent Changes
- Added exponential backoff retry logic
- Fixed race condition in token refresh
- Discovered 5-second rate limit on auth endpoint

## Quick Reference
- Current phase: 3 of 4
- Previous phase: Completed 2026-02-01
```

---

### /memory-status

**Purpose:** View the current state of the memory system.

**Trigger phrases:**
- `/memory-status`
- "memory status"
- "show memory"
- "check memory system"

#### What It Does

1. Shows current context summary
2. Displays active plan status (if exists)
3. Counts files in each memory category
4. Shows recent activity
5. Reports system health

#### Output Format

```
📊 Memory System Status
═══════════════════════════════════════════

📋 Current Context
Last Updated: 2026-02-01 16:45 (2 hours ago)
Active Task: Auth refactor - Phase 3
Status: Active work in progress

📑 Active Plan
Name: auth-refactor
Status: In Progress
Progress: 50% (2/4 phases complete)

📁 Memory Statistics
┌─────────────┬───────┬──────────────────┐
│ Category    │ Count │ Latest           │
├─────────────┼───────┼──────────────────┤
│ Sessions    │    23 │ 2026-02-01 16:45 │
│ Decisions   │     3 │ 2026-02-01 16:30 │
│ Knowledge   │     5 │ 2026-01-28 14:00 │
└─────────────┴───────┴──────────────────┘

📈 Recent Activity (last 7 days)
• 2026-02-01: 2 sessions, 1 decision
• 2026-01-31: 3 sessions, 0 decisions
• 2026-01-30: 2 sessions, 1 decision
• 2026-01-29: 1 session, 0 decisions

🏥 System Health
✅ All required directories exist
✅ Required files present
✅ Decision numbers sequential
⚠️  2 knowledge files not updated in 30+ days
```

#### Compact Mode

For a quick overview:

```
You: /memory-status compact

Claude:
Memory Status (compact)
• Context: Updated 2h ago | Task: Auth refactor Phase 3
• Plan: auth-refactor (50%)
• Files: 23 sessions, 3 decisions, 5 knowledge
• Health: OK (1 warning)
```

---

### /memory-decide

**Purpose:** Create a decision record (Architecture Decision Record style).

**Trigger phrases:**
- `/memory-decide`
- "record decision"
- "create ADR"
- "log decision"
- "document decision"

#### What It Does

1. Auto-finds the next decision number
2. Prompts for decision details
3. Creates properly formatted decision record
4. Uses ADR template

#### Interactive Flow

```
You: /memory-decide

Claude: What decision needs to be recorded?

You: How to implement rate limiting for our API

Claude: What's the context for this decision?
        (What problem are we solving?)

You: Our API is getting hammered by a few heavy users,
     causing slowdowns for everyone. We need to implement
     rate limiting to ensure fair usage.

Claude: What options did you consider? For each option,
        I'll ask about pros and cons.

You: Three options:
     1. Fixed rate limit (100 requests/minute per user)
     2. Token bucket algorithm
     3. Sliding window with Redis

Claude: Let's go through each:

        Option 1: Fixed rate limit
        What are the pros?

You: Simple to implement, easy to understand and explain to users

Claude: And the cons?

You: Doesn't handle legitimate burst traffic well, can be
     frustrating for power users who do batch operations

Claude: Option 2: Token bucket algorithm
        What are the pros?

You: Handles bursts gracefully, industry standard behavior,
     our rate-limiting library has built-in support

Claude: And the cons?

You: Requires Redis for distributed rate limiting across
     instances, slightly more complex to tune

Claude: Option 3: Sliding window with Redis
        What are the pros?

You: Most accurate rate limiting, smooth rate enforcement

Claude: And the cons?

You: Higher Redis load, more complex to implement and debug

Claude: Which option did you choose and why?

You: Token bucket - it handles bursts gracefully which is
     important for our API consumers who do batch imports.
     Plus our library already supports it.

Claude: What are the consequences of this decision?

You: We need to add Redis to our infrastructure for storing
     token buckets. We also need to document the rate limits
     in our API docs and add rate limit headers to responses.

Claude: ✅ Decision recorded!

Created: .claude/memory/decisions/0004_token_bucket_rate_limiting.md

Summary:
• Decision #4: Token Bucket for Rate Limiting
• Status: Accepted
• Key consequence: Requires Redis infrastructure
```

#### Quick Mode

For simpler decisions:

```
You: /memory-decide quick "Use PostgreSQL for new service"
     "Need a database for the notification service.
     Chose PostgreSQL over MySQL because team has more
     experience and we need better JSON support."

Claude: ✅ Quick decision recorded!
Created: .claude/memory/decisions/0005_postgresql_for_notification_service.md
```

#### Generated Decision Record

```markdown
# Decision 0004: Token Bucket for Rate Limiting

**Date**: 2026-02-01
**Status**: Accepted

## Context

Our API is getting hammered by a few heavy users, causing slowdowns
for everyone. We need to implement rate limiting to ensure fair usage.

## Options Considered

### Option 1: Fixed Rate Limit (100 req/min per user)
**Pros:**
- Simple to implement
- Easy to understand and explain to users

**Cons:**
- Doesn't handle legitimate burst traffic well
- Can be frustrating for power users who do batch operations

### Option 2: Token Bucket Algorithm
**Pros:**
- Handles bursts gracefully
- Industry standard behavior
- Our rate-limiting library has built-in support

**Cons:**
- Requires Redis for distributed rate limiting
- Slightly more complex to tune

### Option 3: Sliding Window with Redis
**Pros:**
- Most accurate rate limiting
- Smooth rate enforcement

**Cons:**
- Higher Redis load
- More complex to implement and debug

## Decision

We chose **Token Bucket Algorithm** because it handles bursts gracefully,
which is important for our API consumers who do batch imports. Additionally,
our existing rate-limiting library has built-in support for this algorithm.

## Consequences

- Must add Redis to infrastructure for storing token buckets across instances
- Need to document rate limits in API documentation
- Should add rate limit headers to responses (X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset)
- May need to tune bucket size and refill rate based on monitoring data
```

---

## Tips & Tricks

### Combining Commands

You can chain commands naturally:

```
You: /memory-start then let's continue with the auth work

Claude: [Shows context]
        Based on the context, you were working on Phase 3 of the
        auth refactor. Let's continue with refresh token rotation...
```

### Session Templates

For recurring session types, create templates:

```
You: /memory-save standup
     # Uses a shorter format suitable for daily standups
```

### Bulk Operations

For importing multiple decisions:

```
You: I have 3 decisions from our architecture meeting to record.
     Let's do them one by one.

Claude: Sure, let's use /memory-decide for each.

You: /memory-decide
     [First decision...]

You: /memory-decide
     [Second decision...]
```

### Reviewing History

```
You: /memory-status then show me all decisions about databases

Claude: [Shows status]
        Searching decisions for "database"...
        Found 2 decisions:
        • 0002: PostgreSQL for main database
        • 0005: Redis for caching layer
```

### Emergency Recovery

If context is lost or corrupted:

```
You: /memory-start

Claude: ⚠️ current_context.md appears to be empty or corrupted.
        Would you like me to:
        1. Reconstruct from recent session summaries
        2. Start fresh with a new context
        3. Show me the raw file contents

You: 1

Claude: Reconstructing from last 3 sessions...
        [Shows reconstructed context]
        Does this look correct?
```

---

## Extended Commands

### /memory-search

**Purpose:** Search across all memory files for specific content.

**Trigger phrases:**
- `/memory-search`
- "search memory", "find in memory"
- "search sessions", "search decisions"

#### Basic Usage

```
You: /memory-search rate limiting

Claude: ## Memory Search Results

        **Query**: "rate limiting"
        **Matches**: 4 results in 3 files

        ### Decisions
        - 0003_rate_limiting.md: Line 1, 15, 22

        ### Sessions
        - 2024-01-14_summary.md: Line 5, 12

        Would you like me to read any of these files?
```

#### Scoped Search

```
You: /memory-search decisions: authentication

Claude: Searching only in decisions/...
        Found 2 matches in decision records.
```

---

### /memory-knowledge

**Purpose:** Interactive knowledge base management.

**Trigger phrases:**
- `/memory-knowledge`
- "add knowledge", "update knowledge"
- "what do we know about"

#### List Knowledge Base

```
You: /memory-knowledge

Claude: 📚 Knowledge Base Contents

        Found 4 knowledge files:

        | Topic | Last Updated |
        |-------|--------------|
        | api-patterns | 2024-01-15 |
        | authentication | 2024-01-14 |
        | stripe-integration | 2024-01-10 |

        Commands: "show [topic]", "add to [topic]", "create [topic]"
```

#### Quick Add

```
You: /memory-knowledge add: Stripe returns 200 even for errors

Claude: Which topic? (1) stripe-integration, (2) api-patterns, (3) new

You: 1

Claude: ✅ Added to stripe-integration.md
```

#### Create New Topic

```
You: /memory-knowledge create testing-patterns

Claude: Creating new knowledge file...

        What's the first piece of knowledge to add?

You: Use factories over fixtures for test data

Claude: ✅ Created testing-patterns.md with initial content
```

---

### /memory-plan

**Purpose:** Create and track implementation plans for multi-session projects.

**Trigger phrases:**
- `/memory-plan`
- "create plan", "show plan", "update plan"
- "what's the plan", "next steps"

#### Show Current Plan

```
You: /memory-plan

Claude: 📋 Active Plan: Auth Refactor

        Status: In Progress
        Progress: 40% (6/15 tasks)

        ✅ Phase 1: Setup (Complete)
        🔄 Phase 2: Implementation (In Progress)
           - [x] Create models
           - [ ] Add validation
           - [ ] Write tests
        ⏳ Phase 3: Integration
        ⏳ Phase 4: Testing

        Commands: "complete [task]", "add finding", "block [reason]"
```

#### Create New Plan

```
You: /memory-plan create: Add dark mode support

Claude: Let's create a plan for dark mode.

        Suggested phases:
        1. Design System Setup
        2. Component Updates
        3. User Preferences
        4. Polish

        Does this structure work?
```

#### Update Progress

```
You: /memory-plan complete "Add validation"

Claude: ✅ Marked complete: Add validation

        Phase 2 Progress: 2/3 tasks
        Overall: 47% complete

        Next task: Write tests
```

#### Add Finding

```
You: /memory-plan finding: API requires OAuth2 not API keys

Claude: 📝 Added to findings.md

        This may impact Phase 3. Add task for OAuth2 setup?
```

---

### /memory-review

**Purpose:** Review session history and generate reports for standups, retros, and documentation.

**Trigger phrases:**
- `/memory-review`
- "review sessions", "what did we do"
- "weekly review", "standup", "retro"

#### Recent Activity

```
You: /memory-review

Claude: 📊 Memory Review (Last 7 days)

        Sessions: 8 recorded
        Decisions: 3 made
        Knowledge: 2 updates

        | Date | Focus | Outcome |
        |------|-------|---------|
        | Jan 15 | Auth | Completed token refresh |
        | Jan 14 | Auth | Fixed race condition |
        ...
```

#### Time-Based Review

```
You: /memory-review this week

Claude: 📅 This Week (Jan 13-19)

        ## Accomplishments
        ✅ Completed Phase 1 auth refactor
        ✅ Fixed token refresh issue
        ✅ Added rate limiting

        ## Decisions Made
        - #0005: Exponential backoff
        - #0004: Token bucket rate limiting

        ## Next Week
        - Complete Phase 2
        - Start integration tests
```

#### Generate Standup

```
You: /memory-review standup

Claude: 📢 Standup Summary

        **Yesterday:**
        - Fixed token refresh race condition
        - Added exponential backoff retry

        **Today:**
        - Continue token rotation
        - Start integration tests

        **Blockers:** None
```

#### Generate Retrospective

```
You: /memory-review retro

Claude: 📝 Retrospective Notes

        ## What Went Well
        ✅ Clear plan helped focus
        ✅ Decision records prevented backtracking

        ## What Could Improve
        ⚠️ Underestimated token refresh complexity
        ⚠️ Should have checked rate limits earlier

        ## Action Items
        - [ ] Add rate limit detection to checklist
        - [ ] Include edge cases in estimates
```

#### Decision Archaeology

```
You: /memory-review why did we choose PostgreSQL?

Claude: 🔍 Found Decision #0003

        **PostgreSQL for Session Storage**
        Date: January 10, 2024

        We chose PostgreSQL because:
        - Persistent by default (vs Redis)
        - Team familiarity
        - Same connection as main DB

        Related session: Jan 10 planning meeting
```

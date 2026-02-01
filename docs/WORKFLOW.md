# Claude Memory System: Complete Workflow Guide

This guide explains how to use the Claude Memory System effectively for maximum productivity and seamless session continuity.

---

## Table of Contents

1. [Philosophy & Core Concepts](#philosophy--core-concepts)
2. [The 6-Layer Memory Architecture](#the-6-layer-memory-architecture)
3. [Daily Workflow](#daily-workflow)
4. [Session Lifecycle](#session-lifecycle)
5. [Decision Recording](#decision-recording)
6. [Knowledge Management](#knowledge-management)
7. [Task Planning](#task-planning)
8. [Multi-Agent Workflows](#multi-agent-workflows)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Philosophy & Core Concepts

### Why This System Exists

Claude Code sessions are ephemeral—when you close a session, the context is lost. This creates friction:
- Starting each session cold, re-explaining what you're working on
- Forgetting why certain decisions were made weeks ago
- Losing track of discoveries and patterns learned during debugging
- No continuity for multi-day or multi-week projects

The Claude Memory System solves this by creating **persistent, file-based memory** that survives across sessions.

### Core Principles

1. **Files as Memory**: Everything is stored in plain markdown files, version-controlled with your project
2. **Layered Context**: Different types of memory have different lifespans and purposes
3. **Explicit Over Implicit**: Write things down rather than relying on recall
4. **Progressive Disclosure**: Start with current context, dig into history only when needed

### What This Is NOT

- Not a database or complex system
- Not automatic—you control what gets remembered
- Not a replacement for documentation—it augments it
- Not required for every project—use it when continuity matters

---

## The 6-Layer Memory Architecture

The system uses 6 distinct layers, each serving a different purpose:

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: CLAUDE.md (Project Root)                              │
│  ├─ Permanent project conventions                               │
│  ├─ Coding standards, API patterns, gotchas                     │
│  └─ Auto-loaded by Claude Code every session                    │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: current_context.md                                    │
│  ├─ "What am I working on RIGHT NOW?"                           │
│  ├─ Updated at start and end of each session                    │
│  └─ The handoff document between sessions                       │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: sessions/ (Session Summaries)                         │
│  ├─ Historical archive of what happened                         │
│  ├─ Created at end of each session                              │
│  └─ Useful for context recovery and auditing                    │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: decisions/ (Decision Records)                         │
│  ├─ WHY we chose X over Y                                       │
│  ├─ ADR-style documentation                                     │
│  └─ Prevents re-litigating past decisions                       │
├─────────────────────────────────────────────────────────────────┤
│  Layer 5: knowledge/ (Knowledge Base)                           │
│  ├─ Domain knowledge accumulated over time                      │
│  ├─ Patterns, quirks, undocumented behaviors                    │
│  └─ Grows organically as you learn                              │
├─────────────────────────────────────────────────────────────────┤
│  Layer 6: plans/ (Active Plans)                                 │
│  ├─ Current task breakdown and progress                         │
│  ├─ Research findings                                           │
│  └─ Deleted or archived when task complete                      │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use Each Layer

| Layer | Use When... | Example |
|-------|-------------|---------|
| CLAUDE.md | Pattern is permanent and project-wide | "Always use snake_case for database columns" |
| current_context.md | Information needed for next session | "Working on auth refactor, stuck on token refresh" |
| sessions/ | You want a record of what happened | "Fixed 3 bugs, discovered memory leak" |
| decisions/ | Choice has long-term implications | "Chose PostgreSQL over MongoDB because..." |
| knowledge/ | Learning applies beyond current task | "The payment API returns 200 even on failure" |
| plans/ | Task is complex and multi-step | "Migration plan: 5 phases, currently on phase 2" |

---

## Daily Workflow

### The 3-Minute Session Start

When you begin a Claude Code session:

```
1. Run /memory-start (or read files manually)
   ↓
2. Review what's shown:
   - Current context: What were we doing?
   - Active plan: What's the next step?
   - Recent sessions: Any relevant history?
   ↓
3. Orient Claude:
   "Let's continue with [task]. Last session we [summary]."
```

**Example:**
```
You: /memory-start

Claude: Reading context from last session...

📋 Current Context (updated 2 hours ago):
- Working on: User authentication refactor
- Blocked on: Token refresh logic failing intermittently
- Next step: Add logging to identify race condition

📊 Active Plan: auth-refactor (Phase 2 of 4, 40% complete)
- ✅ Phase 1: Extract auth to separate module
- 🔄 Phase 2: Implement new token flow
- ⏳ Phase 3: Add refresh token rotation
- ⏳ Phase 4: Integration tests

📚 Recent Sessions:
- 2026-01-31 14:30: Completed module extraction
- 2026-01-30 09:15: Started auth refactor, created plan

You: Let's continue with the token refresh issue. Can you add
     logging around the refresh flow first?
```

### The 5-Minute Session End

Before closing a session:

```
1. Run /memory-save (or write files manually)
   ↓
2. Answer the prompts:
   - What did you accomplish?
   - Any decisions made?
   - What should next session know?
   ↓
3. Verify the files were updated
```

**Example:**
```
You: /memory-save

Claude: Let's save this session. What work did you complete?

You: Fixed the token refresh race condition, added retry logic

Claude: Any decisions made that should be recorded?

You: Yes - decided to use exponential backoff instead of fixed retry

Claude: What should the next session know?

You: Ready to move to Phase 3, all tests passing

Claude: Session saved!
- Created: .claude/memory/sessions/2026-02-01_16-45_summary.md
- Updated: .claude/memory/current_context.md
- Created: .claude/memory/decisions/0003_exponential_backoff.md
```

---

## Session Lifecycle

### Starting Fresh vs. Continuing

**Starting a new task:**
```
You: /memory-start

Claude: [Shows context is stale or unrelated]

You: I'm starting something new. Clear the current context and
     let's work on implementing the payment integration.

Claude: I'll update the context. Should I archive the previous
        context to a session summary first?

You: Yes, then let's create a plan for the payment work.
```

**Continuing existing work:**
```
You: /memory-start

Claude: [Shows relevant context]

You: Perfect, let's pick up where we left off. You mentioned
     we should add logging—let's do that.
```

### Context Handoff Between Sessions

The `current_context.md` file is your handoff document. Think of it as a note to your future self (and Claude).

**Good context handoff:**
```markdown
# Current Working Context

**Last Updated**: 2026-02-01 16:45
**Active Task**: Payment integration - Stripe webhooks

## What I'm Working On
- Implementing Stripe webhook handlers
- Currently on: refund.created event
- Next: Handle dispute events

## Important State
- Using test mode API keys (see .env.example)
- Webhook secret stored in STRIPE_WEBHOOK_SECRET
- Local testing via Stripe CLI: `stripe listen --forward-to localhost:3000/webhooks`

## Blockers
- None currently

## Recent Changes
- Added webhook verification middleware
- Implemented payment_intent.succeeded handler
- Created WebhookEvent model in database

## Quick Reference
- Stripe API docs: https://stripe.com/docs/webhooks
- Our webhook endpoint: POST /api/webhooks/stripe
- Test card: 4242424242424242
```

**Poor context handoff:**
```markdown
# Current Working Context

Working on payments.
```

---

## Decision Recording

### When to Record a Decision

Record a decision when:
- You chose between multiple valid approaches
- The decision affects architecture or design
- Future you might wonder "why did we do it this way?"
- The decision is non-obvious or counterintuitive
- You spent significant time evaluating options

### Using /memory-decide

```
You: /memory-decide

Claude: What decision needs to be recorded?

You: We need to decide how to handle API rate limiting

Claude: What's the context for this decision?

You: Our API is getting hammered by a few heavy users,
     causing slowdowns for everyone

Claude: What options did you consider?

You: 1. Fixed rate limit per user (100 req/min)
     2. Token bucket algorithm
     3. Sliding window with Redis

Claude: Which option did you choose and why?

You: Token bucket - it handles bursts better and the library
     we're using already supports it

Claude: What are the consequences of this decision?

You: Need to add Redis for distributed rate limiting across
     instances. Also need to document rate limits in API docs.

Claude: Decision recorded as 0004_token_bucket_rate_limiting.md
```

### Decision Record Format

```markdown
# Decision 0004: Token Bucket for Rate Limiting

**Date**: 2026-02-01
**Status**: Accepted

## Context

Our API is experiencing load issues from a few heavy users making
excessive requests, causing slowdowns for all users. We need to
implement rate limiting.

## Options Considered

### Option 1: Fixed Rate Limit (100 req/min per user)
- **Pros**: Simple to implement, easy to understand
- **Cons**: Doesn't handle legitimate burst traffic well,
  frustrating UX for power users

### Option 2: Token Bucket Algorithm
- **Pros**: Handles bursts gracefully, industry standard,
  our existing library supports it
- **Cons**: Slightly more complex, requires Redis for distributed

### Option 3: Sliding Window with Redis
- **Pros**: Most accurate rate limiting
- **Cons**: Higher Redis load, more complex implementation

## Decision

We chose **Token Bucket Algorithm** because:
1. Better UX - allows legitimate bursts while preventing abuse
2. Library support - our rate-limiting library has built-in support
3. Industry standard - well-understood behavior for API consumers

## Consequences

- Must add Redis to infrastructure for distributed token storage
- Need to document rate limits in API documentation
- Should add rate limit headers to responses (X-RateLimit-*)
- May need to adjust bucket size based on monitoring
```

---

## Knowledge Management

### What Goes in Knowledge Files

The knowledge base captures learnings that apply beyond the current task:

- **API quirks**: "Stripe returns 200 even on validation errors, check the error object"
- **Debugging tips**: "To debug auth issues, check the session cookie expiry first"
- **Performance insights**: "The user query is slow because of N+1—always eager load roles"
- **Undocumented behavior**: "The legacy endpoint requires Content-Type even for GET"
- **Environment specifics**: "Staging uses a different OAuth callback URL"

### Creating Knowledge Files

Knowledge files are organized by topic:

```
.claude/memory/knowledge/
├── stripe-integration.md      # Everything about our Stripe setup
├── authentication.md          # Auth system quirks and patterns
├── database-patterns.md       # Query optimization, migrations
├── testing-strategies.md      # What works for testing this codebase
└── deployment.md              # Deployment process and gotchas
```

**Example knowledge file:**

```markdown
# Stripe Integration Knowledge

## API Quirks

### Error Handling
Stripe returns HTTP 200 for many error cases. Always check:
```javascript
if (response.error) {
  // This is an error, not a success!
}
```

### Webhook Verification
The raw body must be used for signature verification. If using
Express, ensure body-parser doesn't parse the webhook endpoint:
```javascript
app.use('/webhooks/stripe', express.raw({ type: 'application/json' }));
```

## Testing

### Test Cards
- Success: 4242424242424242
- Decline: 4000000000000002
- 3D Secure: 4000002760003184

### Webhook Testing
Use Stripe CLI for local testing:
```bash
stripe listen --forward-to localhost:3000/webhooks/stripe
```

## Common Issues

### "No signatures found matching the expected signature"
Usually means the webhook secret is wrong or the body was
parsed before verification. Check:
1. STRIPE_WEBHOOK_SECRET matches dashboard
2. Raw body is being used for verification
```

### Updating Knowledge

When you discover something new:

```
You: I just discovered that the payment API times out after
     exactly 30 seconds, not the documented 60 seconds.

Claude: That's useful knowledge! Should I add this to the
        Stripe integration knowledge file?

You: Yes, add it under a "Timeouts" section.

Claude: Updated .claude/memory/knowledge/stripe-integration.md
```

---

## Task Planning

### When to Create a Plan

Create a plan for tasks that are:
- Multi-step or multi-phase
- Spanning multiple sessions
- Complex enough to lose track of
- Involving research before implementation

### The Planning Files

```
.claude/plans/
├── active_plan.md   # The current task breakdown
├── findings.md      # Research discoveries
└── progress.md      # What's done, in progress, blocked
```

### Creating a Plan

```
You: I need to migrate our database from MySQL to PostgreSQL.
     Let's create a plan for this.

Claude: I'll create a plan. Let me first understand the scope...
        [Explores codebase]

        Based on my analysis, here's a migration plan:

# Active Plan: MySQL to PostgreSQL Migration

**Created**: 2026-02-01
**Status**: Not Started
**Goal**: Migrate production database with zero downtime

## Overview
Migrate 15 tables, ~2M rows from MySQL 5.7 to PostgreSQL 14.
Key challenges: timestamp handling, JSON columns, stored procedures.

## Implementation Steps

### Phase 1: Preparation (Day 1-2)
- [ ] Audit all SQL queries for MySQL-specific syntax
- [ ] Identify stored procedures and triggers
- [ ] Set up PostgreSQL in staging environment
- [ ] Create migration scripts with pgloader

### Phase 2: Application Updates (Day 3-5)
- [ ] Update ORM configuration
- [ ] Fix MySQL-specific queries
- [ ] Handle timestamp precision differences
- [ ] Update JSON column handling

### Phase 3: Data Migration (Day 6)
- [ ] Run pgloader migration
- [ ] Verify data integrity
- [ ] Run application test suite

### Phase 4: Switchover (Day 7)
- [ ] Final data sync
- [ ] Switch connection strings
- [ ] Monitor for issues
- [ ] Rollback plan ready

## Success Criteria
- [ ] All data migrated with integrity verified
- [ ] Application test suite passes 100%
- [ ] Query performance equal or better
- [ ] Zero downtime during switchover
```

### Tracking Progress

Update `progress.md` as you work:

```markdown
# Progress Tracker

## Completed
- [x] Phase 1: Preparation
  - Audited 47 queries, found 12 MySQL-specific
  - 3 stored procedures identified
  - PostgreSQL staging environment ready
  - pgloader scripts tested

## In Progress
- [ ] Phase 2: Application Updates
  - [x] Updated ORM configuration
  - [x] Fixed 8/12 MySQL-specific queries
  - [ ] 4 queries remaining (complex date handling)
  - [ ] JSON column handling

## Blocked
- Waiting for DBA to provision production PostgreSQL instance

## Next Up
- Complete remaining query fixes
- Then: JSON column migration
```

### Recording Findings

Use `findings.md` for research discoveries:

```markdown
# Research Findings

## Date Handling Differences
MySQL DATETIME vs PostgreSQL TIMESTAMP:
- MySQL: microsecond precision optional
- PostgreSQL: microsecond precision default
- Solution: Use TIMESTAMP(3) for millisecond precision

## JSON Column Migration
MySQL JSON type maps directly to PostgreSQL JSONB.
However, our queries use MySQL's JSON_EXTRACT which needs
to become PostgreSQL's -> operator.

Before:
```sql
SELECT JSON_EXTRACT(data, '$.email') FROM users;
```

After:
```sql
SELECT data->>'email' FROM users;
```

## Performance Notes
PostgreSQL EXPLAIN ANALYZE shows our main user query is
3x faster due to better index utilization.
```

---

## Multi-Agent Workflows

### When to Use Parallel Agents

Use parallel agents for:
- Independent research tasks
- Exploring multiple parts of codebase
- Gathering information before making decisions

### Spawning Research Agents

```python
# Spawn agents to research in parallel
Task(
    subagent_type="Explore",
    prompt="Find all authentication code and summarize the auth flow",
    run_in_background=True
)

Task(
    subagent_type="Explore",
    prompt="Find all places where user permissions are checked",
    run_in_background=True
)

Task(
    subagent_type="Plan",
    prompt="Design a new role-based access control system",
    run_in_background=True
)
```

### Collecting Results

```python
# Check on agent progress
TaskOutput(task_id="abc123", block=False)

# Wait for completion
TaskOutput(task_id="abc123", block=True)
```

### Recording Agent Findings

After agents complete, consolidate their findings:

```
You: The research agents finished. Let's consolidate what they
     found into the findings.md file.

Claude: I'll summarize the agent results:

Agent 1 (Auth Flow):
- Auth starts in middleware/auth.js
- Token validation in services/token.js
- Session stored in Redis

Agent 2 (Permission Checks):
- 23 files check permissions
- Inconsistent patterns: some use middleware, some inline
- No centralized permission service

Agent 3 (RBAC Design):
- Recommends centralized permission service
- Suggests role hierarchy with inheritance
- Proposes caching layer for performance

Should I add this to findings.md?

You: Yes, and let's also add a decision record about the
     centralized permission service approach.
```

---

## Best Practices

### DO ✅

1. **Start every session with `/memory-start`**
   - Even if you remember what you were doing
   - Claude doesn't remember—give it context

2. **End every session with `/memory-save`**
   - 5 minutes of documentation saves 20 minutes of re-orientation
   - Future you will thank present you

3. **Keep context files focused**
   - current_context.md should be < 50 lines
   - If it's getting long, some content belongs in knowledge/

4. **Record decisions immediately**
   - Don't wait until the end of session
   - Context is freshest right after deciding

5. **Update CLAUDE.md for permanent patterns**
   - When a pattern proves stable, promote it
   - CLAUDE.md is auto-loaded—it's the most accessible memory

6. **Version control your memory files**
   - Commit .claude/ directory to git
   - Enables history and collaboration

7. **Prune regularly**
   - Run `prune-sessions.sh 30` monthly
   - Archive or delete stale knowledge files

### DON'T ❌

1. **Don't over-document**
   - Not every session needs a detailed summary
   - If nothing significant happened, a one-liner is fine

2. **Don't duplicate CLAUDE.md content**
   - CLAUDE.md is for permanent standards
   - Don't repeat its content in other files

3. **Don't let files grow unbounded**
   - Session summaries should be < 1 page
   - Knowledge files should focus on one topic
   - Split large files into focused ones

4. **Don't create plans for simple tasks**
   - One-step tasks don't need formal plans
   - Plans are for multi-phase, multi-session work

5. **Don't forget to update progress**
   - Stale progress.md is worse than none
   - Mark completed items immediately

---

## Troubleshooting

### "Claude doesn't seem to remember our previous session"

Claude doesn't have persistent memory—that's why this system exists.

**Fix**: Start with `/memory-start` or manually tell Claude to read the context files:
```
You: Please read .claude/memory/current_context.md and
     .claude/plans/active_plan.md to get up to speed.
```

### "My context file is getting too long"

Long context files slow down session starts and can exceed context limits.

**Fix**:
1. Move stable knowledge to `.claude/memory/knowledge/`
2. Move old details to session summaries
3. Keep only what's needed for the *next* session

### "I forgot to save my session"

It happens. You can reconstruct from:
1. Git diff to see what changed
2. Your memory of what you did
3. Chat history if still available

**Prevention**: Add the Stop hook to remind you.

### "Decision numbers are out of sync"

The auto-numbering looks for the highest existing number.

**Fix**: Run `scripts/validate-memory.sh` to check for gaps, then renumber manually or leave gaps (they're harmless).

### "My hooks aren't running"

Check:
1. Hook is in the correct settings.json location
2. Command path is correct
3. Script has execute permissions (chmod +x)
4. Test the command manually in terminal

### "MCP server won't start"

Check:
1. Dependencies installed: `cd mcp-server && npm install`
2. Compiled: `npm run build`
3. Project root is set: Check MEMORY_PROJECT_ROOT env var
4. Test manually: `node dist/index.js /path/to/project`

---

## Quick Reference Card

```
┌────────────────────────────────────────────────────────────────┐
│                    CLAUDE MEMORY SYSTEM                        │
├────────────────────────────────────────────────────────────────┤
│  SESSION START                                                 │
│  • /memory-start                                               │
│  • Read current_context.md + active_plan.md                    │
├────────────────────────────────────────────────────────────────┤
│  DURING SESSION                                                │
│  • Update progress.md as you complete tasks                    │
│  • /memory-decide for significant choices                      │
│  • Add discoveries to knowledge/ files                         │
├────────────────────────────────────────────────────────────────┤
│  SESSION END                                                   │
│  • /memory-save                                                │
│  • Creates session summary + updates context                   │
├────────────────────────────────────────────────────────────────┤
│  KEY FILES                                                     │
│  • CLAUDE.md - Permanent standards (auto-loaded)               │
│  • current_context.md - Session handoff                        │
│  • sessions/ - Historical archive                              │
│  • decisions/ - Why we chose X over Y                          │
│  • knowledge/ - Accumulated learnings                          │
│  • plans/ - Current task tracking                              │
├────────────────────────────────────────────────────────────────┤
│  UTILITIES                                                     │
│  • /memory-status - Show system state                          │
│  • validate-memory.sh - Check integrity                        │
│  • prune-sessions.sh 30 - Archive old sessions                 │
│  • index-knowledge.sh - Generate knowledge index               │
└────────────────────────────────────────────────────────────────┘
```

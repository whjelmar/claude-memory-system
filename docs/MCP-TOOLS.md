# MCP Tools Reference

This document provides detailed documentation for all MCP tools provided by the Claude Memory System server.

---

## Table of Contents

1. [Overview](#overview)
2. [Setup & Configuration](#setup--configuration)
3. [Tool Reference](#tool-reference)
   - [memory_read_context](#memory_read_context)
   - [memory_save_session](#memory_save_session)
   - [memory_log_decision](#memory_log_decision)
   - [memory_add_knowledge](#memory_add_knowledge)
   - [memory_search](#memory_search)
4. [Error Handling](#error-handling)
5. [Examples](#examples)

---

## Overview

The MCP (Model Context Protocol) server provides programmatic access to memory operations. While the slash commands are designed for interactive use, MCP tools are designed for:

- Automated workflows
- Agent-to-agent communication
- Integration with other tools
- Batch operations

### When to Use MCP Tools vs Slash Commands

| Use Case | Slash Commands | MCP Tools |
|----------|---------------|-----------|
| Interactive session save | ✅ `/memory-save` | |
| Automated end-of-session save | | ✅ `memory_save_session` |
| Exploring context interactively | ✅ `/memory-start` | |
| Programmatic context retrieval | | ✅ `memory_read_context` |
| Manual decision recording | ✅ `/memory-decide` | |
| Bulk decision import | | ✅ `memory_log_decision` |
| Searching while chatting | | ✅ `memory_search` |

---

## Setup & Configuration

### Installation

```bash
cd ~/.claude/templates/claude-memory-system/mcp-server
npm install
npm run build
```

### Configuration in Claude Code

Add to your MCP configuration (usually in `.claude/settings.json` or project-level config):

```json
{
  "mcpServers": {
    "claude-memory": {
      "command": "node",
      "args": [
        "C:/Users/YOU/.claude/templates/claude-memory-system/mcp-server/dist/index.js"
      ],
      "env": {
        "MEMORY_PROJECT_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MEMORY_PROJECT_ROOT` | Yes | Path to the project root containing `.claude/` directory |

### Verifying Installation

The server should appear in your available MCP tools. You can test with:

```
You: What MCP tools are available from claude-memory?

Claude: The claude-memory server provides these tools:
- memory_read_context
- memory_save_session
- memory_log_decision
- memory_add_knowledge
- memory_search
```

---

## Tool Reference

### memory_read_context

Reads the current context and active plan from the memory system.

#### Parameters

None required.

#### Returns

```typescript
{
  current_context: {
    content: string;           // Full content of current_context.md
    last_modified: string;     // ISO timestamp of last modification
    exists: boolean;           // Whether file exists
  };
  active_plan: {
    content: string;           // Full content of active_plan.md
    last_modified: string;     // ISO timestamp of last modification
    exists: boolean;           // Whether file exists
  };
  summary: {
    has_active_work: boolean;  // Whether there's active context
    last_session: string;      // ISO timestamp of most recent session
    plan_status: string;       // Status from active plan if exists
  };
}
```

#### Example Usage

```
Claude: [Calling memory_read_context]

Result:
{
  "current_context": {
    "content": "# Current Working Context\n\n**Last Updated**: 2026-02-01...",
    "last_modified": "2026-02-01T16:45:00Z",
    "exists": true
  },
  "active_plan": {
    "content": "# Active Plan: Auth Refactor\n\n**Status**: In Progress...",
    "last_modified": "2026-02-01T14:30:00Z",
    "exists": true
  },
  "summary": {
    "has_active_work": true,
    "last_session": "2026-02-01T16:45:00Z",
    "plan_status": "In Progress"
  }
}
```

---

### memory_save_session

Saves a session summary and updates the current context for the next session.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `summary` | string | Yes | Brief summary of the session (1-2 sentences) |
| `work_completed` | string[] | Yes | List of completed work items |
| `decisions` | string[] | No | List of decisions made (brief descriptions) |
| `discoveries` | string[] | No | List of discoveries/learnings |
| `open_items` | string[] | No | List of incomplete items or blockers |
| `next_steps` | string[] | Yes | What the next session should focus on |
| `next_context` | string | No | Custom context for next session (auto-generated if not provided) |

#### Returns

```typescript
{
  session_file: string;         // Path to created session file
  context_updated: boolean;     // Whether context was updated
  timestamp: string;            // ISO timestamp of save
}
```

#### Example Usage

```
Claude: [Calling memory_save_session with parameters]

Parameters:
{
  "summary": "Fixed token refresh race condition and added retry logic",
  "work_completed": [
    "Identified race condition in token refresh",
    "Implemented mutex lock for refresh operation",
    "Added exponential backoff retry",
    "Updated tests for new behavior"
  ],
  "decisions": [
    "Use exponential backoff (recorded in decision 0003)"
  ],
  "discoveries": [
    "Token endpoint has undocumented 5-second rate limit"
  ],
  "open_items": [],
  "next_steps": [
    "Move to Phase 3: Refresh token rotation",
    "Document the rate limit in knowledge base"
  ]
}

Result:
{
  "session_file": ".claude/memory/sessions/2026-02-01_16-45_summary.md",
  "context_updated": true,
  "timestamp": "2026-02-01T16:45:32Z"
}
```

#### Generated Session File

```markdown
# Session Summary: 2026-02-01 16:45

## Summary
Fixed token refresh race condition and added retry logic

## Work Completed
- Identified race condition in token refresh
- Implemented mutex lock for refresh operation
- Added exponential backoff retry
- Updated tests for new behavior

## Decisions Made
- Use exponential backoff (recorded in decision 0003)

## Discoveries
- Token endpoint has undocumented 5-second rate limit

## Open Items
(none)

## Next Session Should
- Move to Phase 3: Refresh token rotation
- Document the rate limit in knowledge base

## Context for Resume
Ready to begin Phase 3 of auth refactor. All tests passing.
Token refresh is now stable with retry logic.
```

---

### memory_log_decision

Creates an auto-numbered decision record (ADR).

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `title` | string | Yes | Short title for the decision |
| `context` | string | Yes | Background and problem statement |
| `options` | Option[] | Yes | Options that were considered |
| `decision` | string | Yes | The chosen option and rationale |
| `consequences` | string | Yes | What changes as a result |
| `status` | string | No | Status (default: "Accepted") |

**Option type:**
```typescript
{
  name: string;      // Option name (e.g., "Redis Cache")
  pros: string[];    // List of advantages
  cons: string[];    // List of disadvantages
}
```

#### Returns

```typescript
{
  file: string;          // Path to created decision file
  number: number;        // Assigned decision number
  slug: string;          // Generated slug from title
}
```

#### Example Usage

```
Claude: [Calling memory_log_decision with parameters]

Parameters:
{
  "title": "Token Bucket for Rate Limiting",
  "context": "Our API is experiencing load issues from heavy users making excessive requests, causing slowdowns for all users.",
  "options": [
    {
      "name": "Fixed Rate Limit",
      "pros": ["Simple to implement", "Easy to understand"],
      "cons": ["Doesn't handle bursts", "Frustrating UX"]
    },
    {
      "name": "Token Bucket",
      "pros": ["Handles bursts gracefully", "Library support", "Industry standard"],
      "cons": ["Requires Redis", "Slightly more complex"]
    },
    {
      "name": "Sliding Window",
      "pros": ["Most accurate"],
      "cons": ["Higher Redis load", "Complex implementation"]
    }
  ],
  "decision": "Token Bucket - handles bursts gracefully and our library has built-in support",
  "consequences": "Must add Redis to infrastructure. Need to document rate limits in API docs."
}

Result:
{
  "file": ".claude/memory/decisions/0004_token_bucket_for_rate_limiting.md",
  "number": 4,
  "slug": "token_bucket_for_rate_limiting"
}
```

---

### memory_add_knowledge

Adds or updates a knowledge file on a specific topic.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `topic` | string | Yes | Topic name (becomes filename) |
| `content` | string | Yes | Knowledge content in markdown |
| `append` | boolean | No | If true, appends to existing file (default: false) |
| `section` | string | No | If appending, which section to add under |

#### Returns

```typescript
{
  file: string;          // Path to knowledge file
  created: boolean;      // True if new file, false if updated
  topic: string;         // Normalized topic name
}
```

#### Example Usage

**Creating new knowledge:**
```
Claude: [Calling memory_add_knowledge with parameters]

Parameters:
{
  "topic": "stripe-integration",
  "content": "# Stripe Integration\n\n## Webhook Verification\n\nThe raw body must be used for signature verification..."
}

Result:
{
  "file": ".claude/memory/knowledge/stripe-integration.md",
  "created": true,
  "topic": "stripe-integration"
}
```

**Appending to existing:**
```
Claude: [Calling memory_add_knowledge with parameters]

Parameters:
{
  "topic": "stripe-integration",
  "content": "### Timeout Behavior\nThe API times out after 30 seconds (not 60 as documented).",
  "append": true,
  "section": "API Quirks"
}

Result:
{
  "file": ".claude/memory/knowledge/stripe-integration.md",
  "created": false,
  "topic": "stripe-integration"
}
```

---

### memory_search

Searches across memory files for specific content.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | string | Yes | Search query (supports basic regex) |
| `scope` | string | No | Where to search: "sessions", "decisions", "knowledge", "all" (default: "all") |
| `limit` | number | No | Maximum results to return (default: 10) |
| `context_lines` | number | No | Lines of context around matches (default: 2) |

#### Returns

```typescript
{
  results: SearchResult[];
  total_matches: number;
  scope_searched: string;
}

// SearchResult:
{
  file: string;           // Path to file
  matches: Match[];       // All matches in this file
}

// Match:
{
  line_number: number;    // Line number of match
  content: string;        // Matching line
  context_before: string[]; // Lines before match
  context_after: string[];  // Lines after match
}
```

#### Example Usage

```
Claude: [Calling memory_search with parameters]

Parameters:
{
  "query": "token refresh",
  "scope": "all",
  "limit": 5
}

Result:
{
  "results": [
    {
      "file": ".claude/memory/sessions/2026-02-01_16-45_summary.md",
      "matches": [
        {
          "line_number": 8,
          "content": "- Fixed token refresh race condition",
          "context_before": ["## Work Completed"],
          "context_after": ["- Implemented mutex lock"]
        }
      ]
    },
    {
      "file": ".claude/memory/decisions/0003_exponential_backoff.md",
      "matches": [
        {
          "line_number": 12,
          "content": "Token refresh was failing intermittently under load",
          "context_before": ["## Context"],
          "context_after": ["due to race condition between concurrent requests"]
        }
      ]
    }
  ],
  "total_matches": 2,
  "scope_searched": "all"
}
```

**Scoped search:**
```
Parameters:
{
  "query": "PostgreSQL",
  "scope": "decisions",
  "limit": 10
}
```

---

## Error Handling

All tools return structured errors:

```typescript
{
  error: {
    code: string;        // Error code (e.g., "FILE_NOT_FOUND")
    message: string;     // Human-readable message
    details?: object;    // Additional context
  }
}
```

### Common Error Codes

| Code | Description | Resolution |
|------|-------------|------------|
| `MEMORY_NOT_INITIALIZED` | `.claude/memory/` doesn't exist | Run setup.sh first |
| `FILE_NOT_FOUND` | Requested file doesn't exist | Check file path |
| `PERMISSION_DENIED` | Can't read/write file | Check file permissions |
| `INVALID_PARAMETERS` | Missing or invalid parameters | Check parameter types |
| `SEARCH_ERROR` | Search query failed | Simplify regex pattern |

---

## Examples

### Automated Session Save Workflow

```python
# At end of session, automatically save
result = memory_save_session(
    summary="Completed database migration prep",
    work_completed=[
        "Audited all MySQL-specific queries",
        "Created pgloader configuration",
        "Set up PostgreSQL staging environment"
    ],
    decisions=["Chose pgloader over manual scripts"],
    discoveries=["Found 3 stored procedures that need rewriting"],
    next_steps=["Begin query migration", "Rewrite stored procedures"]
)

print(f"Session saved to: {result['session_file']}")
```

### Knowledge Accumulation

```python
# When discovering something useful, add to knowledge base
memory_add_knowledge(
    topic="database-migration",
    content="""
### pgloader Tips

1. Always use `--debug` for first run to catch issues
2. JSON columns map directly to JSONB
3. Watch for timestamp precision differences
""",
    append=True,
    section="Tools"
)
```

### Pre-Session Context Loading

```python
# At session start, load and display context
context = memory_read_context()

if context['summary']['has_active_work']:
    print("Resuming previous work...")
    print(f"Last session: {context['summary']['last_session']}")
    print(f"Plan status: {context['summary']['plan_status']}")
else:
    print("No active context found. Starting fresh.")
```

### Searching for Past Decisions

```python
# Before making a decision, check if similar was made before
results = memory_search(
    query="rate limiting",
    scope="decisions"
)

if results['total_matches'] > 0:
    print("Found relevant past decisions:")
    for result in results['results']:
        print(f"  - {result['file']}")
```

---
name: memory-search
description: >
  Search across memory files for specific content.
  Searches sessions, decisions, and knowledge files by query.
---

# Memory Search Skill

Search across memory files for specific content.

## Trigger Phrases
- `/memory-search`
- "search memory", "find in memory"
- "search sessions", "search decisions", "search knowledge"
- "find decision about", "when did we decide"

## Description
This skill searches across all memory files (sessions, decisions, knowledge) to find relevant content based on a query. Useful for finding past decisions, recalling when something was discussed, or locating specific knowledge.

## Instructions

When this skill is triggered, perform the following steps:

### Step 1: Get Search Query
If the user provided a query inline, use it. Otherwise prompt:

```
What would you like to search for?

You can also specify a scope:
- `sessions` - Only search session summaries
- `decisions` - Only search decision records
- `knowledge` - Only search knowledge files
- `all` - Search everything (default)

Example: "search decisions for rate limiting"
```

### Step 2: Determine Scope
Parse the user's request to determine scope:
- If they mention "sessions" or "session summaries" → scope: sessions
- If they mention "decisions" or "ADR" → scope: decisions
- If they mention "knowledge" → scope: knowledge
- Otherwise → scope: all

### Step 3: Search Files
Search the appropriate directories:

| Scope | Directory |
|-------|-----------|
| sessions | `.claude/memory/sessions/*.md` |
| decisions | `.claude/memory/decisions/*.md` |
| knowledge | `.claude/memory/knowledge/*.md` |
| all | All of the above |

For each file, search for the query (case-insensitive) and note:
- Filename
- Line number(s) where matches occur
- Context around the match (2-3 lines before/after)

### Step 4: Display Results
Present results in a formatted summary:

```
## Memory Search Results

**Query**: "[search term]"
**Scope**: [sessions/decisions/knowledge/all]
**Matches**: [count] results in [count] files

---

### Sessions

#### 2024-01-15_14-30_summary.md
> Line 12: "Implemented **rate limiting** middleware..."
> Line 15: "Decision: Use sliding window **rate limiting**"

#### 2024-01-10_09-00_summary.md
> Line 8: "Discussed **rate limiting** strategies..."

---

### Decisions

#### 0003_rate_limiting_strategy.md
> Line 1: "# Decision 0003: **Rate Limiting** Strategy"
> Line 15: "Chose token bucket **rate limiting**..."

---

### Knowledge

No matches found.

---

**Tip**: Use `/memory-status` to see all available files, or read a specific file for full context.
```

### Step 5: Offer Follow-up Actions
After showing results, offer:

```
Would you like me to:
1. Read any of these files in full?
2. Narrow the search to a specific scope?
3. Search for a different term?
```

## File Paths
- Sessions: `.claude/memory/sessions/`
- Decisions: `.claude/memory/decisions/`
- Knowledge: `.claude/memory/knowledge/`

## Search Features

### Basic Search
Simple text matching (case-insensitive):
```
/memory-search authentication
```

### Scoped Search
Limit to specific file types:
```
/memory-search decisions: JWT
/memory-search sessions: bug fix
/memory-search knowledge: API patterns
```

### Date Filtering
Find content from specific time periods:
```
/memory-search sessions from last week: deployment
/memory-search decisions in January: database
```

## Error Handling
- If no matches found, suggest:
  - Trying different search terms
  - Broadening the scope
  - Checking if memory system has content
- If memory directory doesn't exist, inform user to run setup
- If a directory is empty, note it and continue searching others

## Example Interactions

### Example 1: General Search

**User**: `/memory-search rate limiting`

**Claude**:
```
## Memory Search Results

**Query**: "rate limiting"
**Scope**: all
**Matches**: 4 results in 3 files

---

### Decisions

#### 0003_rate_limiting_strategy.md
> Line 1: # Decision 0003: Rate Limiting Strategy
> Line 8: Context: API experiencing abuse from heavy users
> Line 22: Chose token bucket algorithm for rate limiting

---

### Sessions

#### 2024-01-14_16-30_summary.md
> Line 5: - Implemented rate limiting middleware
> Line 12: - Decision: Using 100 req/min per user

#### 2024-01-13_10-00_summary.md
> Line 8: - Researched rate limiting approaches

---

Would you like me to read any of these files in full?
```

### Example 2: Scoped Search

**User**: `search decisions for database`

**Claude**:
```
## Memory Search Results

**Query**: "database"
**Scope**: decisions
**Matches**: 2 results in 2 files

---

### Decisions

#### 0001_database_choice.md
> Line 1: # Decision 0001: Database Choice
> Line 10: Chose PostgreSQL for primary database

#### 0005_redis_session_storage.md
> Line 15: PostgreSQL database too slow for session lookups

---

Would you like me to read either decision in full?
```

### Example 3: No Results

**User**: `/memory-search kubernetes`

**Claude**:
```
## Memory Search Results

**Query**: "kubernetes"
**Scope**: all
**Matches**: 0 results

No matches found for "kubernetes" in any memory files.

**Suggestions**:
- Try related terms: "k8s", "container", "deployment", "docker"
- Check what's available: `/memory-status`
- The topic may not have been discussed yet

Would you like to search for a different term?
```

## Integration with MCP

This skill has a corresponding MCP tool `memory_search` that can be used programmatically:

```typescript
memory_search({
  query: "rate limiting",
  scope: "decisions",  // or "sessions", "knowledge", "all"
  limit: 10,
  context_lines: 2
})
```

Use the MCP tool for automated searches or integration with other tools.

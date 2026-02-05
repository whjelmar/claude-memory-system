---
description: Search across memory files for specific content. Use to find past decisions, recall when something was discussed, or locate specific knowledge.
---

# Memory Search

Search across memory files for specific content.

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
- If they mention "sessions" or "session summaries" -> scope: sessions
- If they mention "decisions" or "ADR" -> scope: decisions
- If they mention "knowledge" -> scope: knowledge
- Otherwise -> scope: all

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

---

### Decisions

#### 0003_rate_limiting_strategy.md
> Line 1: "# Decision 0003: **Rate Limiting** Strategy"
> Line 15: "Chose token bucket **rate limiting**..."

---

### Knowledge

No matches found.

---

**Tip**: Use `/memory-status` to see all available files.
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

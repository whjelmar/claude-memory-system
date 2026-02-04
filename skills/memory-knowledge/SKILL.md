---
description: Manage knowledge base for domain learnings and patterns. Use to add, view, search, or organize accumulated knowledge about the codebase.
---

# Memory Knowledge

Interactive knowledge base management for accumulating and organizing domain learnings.

## Instructions

When this skill is triggered, determine the user's intent and proceed accordingly:

### Intent: List Knowledge Base

If the user wants to see what's in the knowledge base:

```
Knowledge Base Contents

Found [N] knowledge files:

| Topic | Last Updated | Size |
|-------|--------------|------|
| api-patterns | 2024-01-15 | 2.3 KB |
| authentication | 2024-01-14 | 1.8 KB |
| database-quirks | 2024-01-10 | 945 B |

Commands:
- "show [topic]" - View a specific knowledge file
- "add to [topic]" - Add content to existing file
- "create [topic]" - Create new knowledge file
- "search [query]" - Search across knowledge
```

### Intent: View Knowledge File

If the user wants to see a specific topic:

1. Read the file from `.claude/memory/knowledge/[topic].md`
2. Display with formatting

### Intent: Add Knowledge

If the user wants to add new knowledge:

**Step 1: Identify Topic**
```
What topic does this knowledge relate to?

Existing topics:
- api-patterns
- authentication
- database-quirks

Or enter a new topic name:
```

**Step 2: Get Content**
```
What knowledge would you like to add?

Tips:
- Use markdown formatting
- Include code examples where helpful
- Note any gotchas or edge cases
- Add "Discovered: [date]" for context
```

**Step 3: Confirm and Save**

### Intent: Create Knowledge File

If creating a new knowledge file, use this template:

```markdown
# [Topic Title]

> Last Updated: [DATE]
> Related: [links to related knowledge files]

## Overview
[Brief description of what this knowledge covers]

## Key Points
- Point 1
- Point 2

## Details

### [Section 1]
[Content]

## Code Examples
```[language]
// Example code
```

## Gotchas & Edge Cases
- Gotcha 1
- Gotcha 2

## References
- [Link 1]
```

### Intent: Quick Add (Inline)

If user provides knowledge inline:
```
/memory-knowledge add: The Stripe API returns 200 even for validation errors
```

Process:
1. Parse the topic from context or ask
2. Append to existing file or create new one
3. Format nicely with timestamp
4. Confirm

## File Paths
- Knowledge directory: `.claude/memory/knowledge/`
- Index file: `.claude/memory/knowledge/INDEX.md`

## Knowledge File Best Practices

### What to Include
- Specific, actionable information
- Code examples when relevant
- Context about when/why discovered
- Links to related knowledge
- Gotchas and edge cases

### What NOT to Include
- Temporary task-specific notes (use sessions/)
- Decisions with rationale (use decisions/)
- Generic documentation (link to external docs instead)

## Related Skills
- `/memory-search` - Search across knowledge files
- `/memory-status` - See knowledge base stats

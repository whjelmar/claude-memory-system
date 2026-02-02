# Memory Knowledge Skill

Interactive knowledge base management for accumulating and organizing domain learnings.

## Trigger Phrases
- `/memory-knowledge`
- "add knowledge", "update knowledge"
- "what do we know about", "knowledge about"
- "create knowledge file", "add to knowledge base"

## Description
This skill provides interactive management of the knowledge base - creating new knowledge files, updating existing ones, viewing what's in the knowledge base, and organizing knowledge by topic.

## Instructions

When this skill is triggered, determine the user's intent and proceed accordingly:

### Intent: List Knowledge Base

If the user wants to see what's in the knowledge base:

```
📚 Knowledge Base Contents

Found [N] knowledge files:

| Topic | Last Updated | Size |
|-------|--------------|------|
| api-patterns | 2024-01-15 | 2.3 KB |
| authentication | 2024-01-14 | 1.8 KB |
| database-quirks | 2024-01-10 | 945 B |
| stripe-integration | 2024-01-08 | 3.1 KB |

Commands:
- "show [topic]" - View a specific knowledge file
- "add to [topic]" - Add content to existing file
- "create [topic]" - Create new knowledge file
- "search [query]" - Search across knowledge
```

### Intent: View Knowledge File

If the user wants to see a specific topic:

1. Read the file from `.claude/memory/knowledge/[topic].md`
2. Display with formatting:

```
📖 Knowledge: API Patterns
Last Updated: 2024-01-15

---

[File contents displayed here]

---

Options:
- "add section" - Add new content to this file
- "update [section]" - Modify a specific section
- "back" - Return to knowledge list
```

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
```
I'll add this to the knowledge base:

Topic: [topic]
Content preview:
---
[First 200 chars of content...]
---

Options:
1. Save as shown
2. Add to existing section (if file exists)
3. Edit content
4. Cancel
```

**Step 4: Update Index**
After saving, update `.claude/memory/knowledge/INDEX.md` if it exists.

### Intent: Create Knowledge File

If creating a new knowledge file:

**Step 1: Topic Name**
```
What should this knowledge file be called?
(Use kebab-case, e.g., "stripe-webhooks", "auth-patterns")
```

**Step 2: Initial Content**
Prompt for content using the standard knowledge file template:

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

### [Section 2]
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
- [Link 2]
```

**Step 3: Save and Confirm**
```
✅ Created knowledge file: .claude/memory/knowledge/[topic].md

The knowledge base now contains [N] topics.

Would you like to:
1. View the new file
2. Add more knowledge
3. Done
```

### Intent: Quick Add (Inline)

If user provides knowledge inline:
```
/memory-knowledge add: The Stripe API returns 200 even for validation errors

Topic: stripe-integration
```

Process:
1. Parse the topic from context or ask
2. Append to existing file or create new one
3. Format nicely with timestamp
4. Confirm:

```
✅ Added to stripe-integration.md:

### API Response Quirk
> Added: 2024-01-15

The Stripe API returns 200 even for validation errors. Always check
the `error` object in the response body.

---

Knowledge base updated. [N] total topics.
```

### Intent: Organize Knowledge

If user wants to reorganize:

```
📁 Knowledge Organization

Current structure:
├── api-patterns.md (3 sections)
├── authentication.md (5 sections)
├── database-quirks.md (2 sections)
└── stripe-integration.md (4 sections)

Options:
1. Merge files - Combine related topics
2. Split file - Break large file into multiple
3. Rename topic - Change file name
4. Archive - Move to archive folder
5. Delete - Remove knowledge file

What would you like to do?
```

## File Paths
- Knowledge directory: `.claude/memory/knowledge/`
- Index file: `.claude/memory/knowledge/INDEX.md`

## Knowledge File Best Practices

### Good Knowledge Entry
```markdown
### Payment Webhook Timing
> Discovered: 2024-01-15
> Context: Debugging delayed order confirmations

Stripe webhooks can be delayed up to 5 minutes during high load.
Don't rely on immediate webhook delivery for time-sensitive operations.

**Workaround**: Poll the PaymentIntent status API as backup.

```javascript
// Polling fallback
async function checkPaymentStatus(paymentIntentId) {
  const intent = await stripe.paymentIntents.retrieve(paymentIntentId);
  return intent.status === 'succeeded';
}
```
```

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

## Example Interactions

### Example 1: Quick Add

**User**: `/memory-knowledge` The auth endpoint rate limits to 10 req/sec per IP

**Claude**:
```
I'll add this to the knowledge base.

Which topic does this relate to?
1. authentication (existing)
2. api-patterns (existing)
3. Create new topic

User: 1

✅ Added to authentication.md:

### Rate Limiting
> Added: 2024-01-15

The auth endpoint rate limits to 10 req/sec per IP.

---

Authentication knowledge updated (now 6 sections).
```

### Example 2: View and Update

**User**: `/memory-knowledge` show stripe-integration

**Claude**:
```
📖 Knowledge: Stripe Integration
Last Updated: 2024-01-14

---

## Webhook Verification

The raw body must be used for signature verification...

## Test Cards

- Success: 4242424242424242
- Decline: 4000000000000002
...

---

Options:
- "add section" - Add new content
- "update [section]" - Modify existing
```

**User**: add section about idempotency keys

**Claude**:
```
What should I add about idempotency keys?

User: Always use idempotency keys for POST requests. Stripe
      recommends UUID v4. Keys expire after 24 hours.

✅ Added new section to stripe-integration.md:

## Idempotency Keys
> Added: 2024-01-15

Always use idempotency keys for POST requests. Stripe recommends
UUID v4. Keys expire after 24 hours.

---

Stripe integration knowledge updated (now 5 sections).
```

### Example 3: Create New Topic

**User**: `/memory-knowledge` create testing-strategies

**Claude**:
```
Creating new knowledge file: testing-strategies.md

What's the main focus of this knowledge?

User: Patterns and tips for testing our codebase effectively

Got it. Let me set up the structure:

# Testing Strategies

> Last Updated: 2024-01-15

## Overview
Patterns and tips for testing our codebase effectively.

## Key Points
- [To be added]

---

What's the first piece of knowledge to add?

User: Use factories instead of fixtures for test data - they're
      more flexible and self-documenting

✅ Created testing-strategies.md with initial content:

## Test Data Patterns
> Added: 2024-01-15

Use factories instead of fixtures for test data - they're more
flexible and self-documenting.

---

Knowledge base now has 5 topics. Would you like to add more?
```

## Integration with MCP

This skill uses the `memory_add_knowledge` MCP tool for file operations:

```typescript
memory_add_knowledge({
  topic: "stripe-integration",
  content: "### New Section\n\nContent here...",
  append: true
})
```

## Related Skills
- `/memory-search` - Search across knowledge files
- `/memory-status` - See knowledge base stats

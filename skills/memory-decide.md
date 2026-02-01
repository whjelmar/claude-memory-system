# Memory Decide Skill

Create a new decision record (ADR) in the memory system.

## Trigger Phrases
- `/memory-decide`
- "record decision", "create decision record"
- "log decision", "document decision"
- "ADR", "architecture decision"

## Description
This skill helps create properly numbered decision records (ADRs - Architecture Decision Records) in the memory system. It auto-detects the next decision number, prompts for decision details, and creates a formatted record.

## Instructions

When this skill is triggered, perform the following steps:

### Step 1: Find Next Decision Number
Scan the `.claude/memory/decisions/` directory for existing decision files.

Decision files follow the format: `NNNN_decision_slug.md`
Examples:
- `0001_database_choice.md`
- `0002_authentication_strategy.md`
- `0003_rate_limiting_approach.md`

Find the highest existing number and increment by 1. If no files exist, start at `0001`.

### Step 2: Prompt for Decision Details
Ask the user for the following information:

**Required:**
1. **Decision Title**: Brief title describing the decision
2. **Context**: What problem or situation led to this decision?
3. **Options Considered**: What alternatives were evaluated?
4. **Chosen Option**: Which option was selected and why?

**Optional:**
5. **Consequences**: What changes as a result of this decision?
6. **Status**: Accepted (default), Superseded, or Deprecated

Example prompt:
```
To create a decision record, please provide:

1. **Title** (required): What is this decision about?
   Example: "Use PostgreSQL for primary database"

2. **Context** (required): What problem are we solving?
   Example: "Need to choose a database that supports complex queries and scales well"

3. **Options** (required): What alternatives did you consider?
   Format each option with pros/cons if possible

4. **Decision** (required): What did you choose and why?

5. **Consequences** (optional): What changes as a result?
```

### Step 3: Generate Slug
Create a URL-friendly slug from the title:
- Convert to lowercase
- Replace spaces with underscores
- Remove special characters
- Limit to 50 characters

Example: "Use PostgreSQL for Primary Database" -> `use_postgresql_for_primary_database`

### Step 4: Create Decision File
Create the file at `.claude/memory/decisions/NNNN_slug.md` using this template:

```markdown
# Decision NNNN: [Title]

**Date**: YYYY-MM-DD
**Status**: Accepted

## Context
[What issue are we facing? What motivated this decision?]

## Options Considered

### Option 1: [Name]
[Description]
- **Pros**: [advantages]
- **Cons**: [disadvantages]

### Option 2: [Name]
[Description]
- **Pros**: [advantages]
- **Cons**: [disadvantages]

[Additional options as needed]

## Decision
[What we chose and the rationale behind the choice]

## Consequences
[What changes as a result of this decision]
- [Positive consequence]
- [Negative consequence or trade-off]
- [Required follow-up actions]
```

### Step 5: Confirm Creation
Display confirmation to user:

```
## Decision Record Created

**File**: `.claude/memory/decisions/NNNN_slug.md`
**Title**: Decision NNNN: [Title]
**Date**: YYYY-MM-DD
**Status**: Accepted

### Summary
[Brief summary of the decision]

### Options Evaluated
1. [Option 1 name]
2. [Option 2 name]
[...]

### Chosen: [Selected option]

---
Decision recorded. Reference this as "Decision NNNN" in future discussions.
```

## File Paths
- Decisions directory: `.claude/memory/decisions/`
- File format: `NNNN_slug.md` (zero-padded 4-digit number)

## Error Handling
- If `.claude/memory/decisions/` doesn't exist, create it
- If user provides incomplete info, ask follow-up questions
- If slug collision occurs (rare), append number: `0005_api_design_2.md`

## Example Interaction

**User**: `/memory-decide`

**Claude**:
```
To create a decision record, please provide:

1. **Title**: What is this decision about?
2. **Context**: What problem are we solving?
3. **Options**: What alternatives did you consider?
4. **Decision**: What did you choose and why?
5. **Consequences** (optional): What changes as a result?
```

**User**:
```
1. Use Redis for session storage
2. Need fast session lookups and the ability to expire sessions automatically. Current file-based sessions are too slow.
3. Options:
   - Redis: Fast, built-in expiry, widely supported
   - Memcached: Fast but no persistence, simpler
   - PostgreSQL: Already have it, but slower for this use case
4. Redis - best balance of speed, features (expiry, persistence), and ecosystem support
5. Need to add Redis to infrastructure, update deployment scripts, handle connection pooling
```

**Claude** creates file and responds:
```
## Decision Record Created

**File**: `.claude/memory/decisions/0004_use_redis_for_session_storage.md`
**Title**: Decision 0004: Use Redis for Session Storage
**Date**: 2024-01-15
**Status**: Accepted

### Summary
Chose Redis over Memcached and PostgreSQL for session storage due to its combination of speed, built-in expiry support, and persistence capabilities.

### Options Evaluated
1. Redis - Fast, built-in expiry, persistence
2. Memcached - Fast but no persistence
3. PostgreSQL - Already available but slower

### Chosen: Redis

---
Decision recorded. Reference this as "Decision 0004" in future discussions.
```

## Quick Decision Mode
If user provides all info inline, skip the prompts and create directly:

**User**: `/memory-decide Use JWT for API auth because it's stateless and works well with microservices. Considered session cookies but they don't scale across services.`

**Claude** parses the input and creates the record immediately.

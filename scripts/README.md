# Memory System Utility Scripts

This directory contains utility scripts for maintaining and managing the Claude Memory System.

Each script is available in both Bash (`.sh`) and PowerShell (`.ps1`) versions for cross-platform compatibility.

## Scripts Overview

### Core Utilities

| Script | Purpose |
|--------|---------|
| `next-decision-number` | Get the next sequential decision number |
| `prune-sessions` | Archive old session summaries |
| `index-knowledge` | Generate a knowledge base index |
| `validate-memory` | Check memory system integrity |

### Enhanced Features

| Script | Purpose |
|--------|---------|
| `auto-summary` | Generate draft session summary from git diff |
| `link-knowledge` | Find and create cross-references in knowledge base |
| `memory-analytics` | Generate analytics about memory usage |
| `generate-dashboard` | Create a markdown dashboard with metrics |

---

## next-decision-number

Scans the decisions directory and outputs the next available decision number, zero-padded to 4 digits.

### Usage

**Bash:**
```bash
./scripts/next-decision-number.sh [project-dir]
```

**PowerShell:**
```powershell
.\scripts\next-decision-number.ps1 [-ProjectDir <path>]
```

### Examples

```bash
# Get next number for current project
./scripts/next-decision-number.sh
# Output: 0001

# Get next number for specific project
./scripts/next-decision-number.sh /path/to/project
# Output: 0042
```

### When to Use

- Before creating a new decision record
- When automating decision record creation
- To verify the current decision count

---

## prune-sessions

Archives session summaries older than N days by moving them to an archive subdirectory.

### Usage

**Bash:**
```bash
./scripts/prune-sessions.sh [days] [project-dir]
```

**PowerShell:**
```powershell
.\scripts\prune-sessions.ps1 [-Days <number>] [-ProjectDir <path>]
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| days | 30 | Number of days to keep recent sessions |
| project-dir | . | Path to project root |

### Examples

```bash
# Archive sessions older than 30 days (default)
./scripts/prune-sessions.sh

# Archive sessions older than 7 days
./scripts/prune-sessions.sh 7

# Archive sessions older than 90 days in specific project
./scripts/prune-sessions.sh 90 /path/to/project
```

### Output

```
Pruning sessions older than 30 days...
Sessions directory: /project/.claude/memory/sessions

Created archive directory: /project/.claude/memory/sessions/archive

=== Prune Summary ===
Days threshold: 30
Files archived: 5

Archived files:
  - 2024-12-01_14-30_summary.md
  - 2024-12-05_09-15_summary.md
  ...

Archive location: /project/.claude/memory/sessions/archive
```

### When to Use

- Weekly or monthly maintenance
- When session directory becomes cluttered
- Before starting a new project phase

---

## index-knowledge

Generates an INDEX.md file for the knowledge base, containing a table of contents with titles, descriptions, and modification dates.

### Usage

**Bash:**
```bash
./scripts/index-knowledge.sh [project-dir]
```

**PowerShell:**
```powershell
.\scripts\index-knowledge.ps1 [-ProjectDir <path>]
```

### Examples

```bash
# Index knowledge base in current project
./scripts/index-knowledge.sh

# Index knowledge base in specific project
./scripts/index-knowledge.sh /path/to/project
```

### Generated Index Format

The script generates `.claude/memory/knowledge/INDEX.md`:

```markdown
# Knowledge Base Index

**Generated**: 2025-01-15 10:30

## Topics

**Total topics: 3**

---

### [API Authentication](api_authentication.md)

This document covers the authentication patterns used in our API,
including OAuth2 flows and API key management...

*Last modified: 2025-01-10*

---

### [Database Schema](database_schema.md)

Overview of the PostgreSQL database schema including tables,
relationships, and indexing strategies...

*Last modified: 2025-01-08*
```

### When to Use

- After adding new knowledge files
- Weekly as part of maintenance
- Before sharing knowledge base with team

---

## validate-memory

Checks the memory system for structural integrity and common issues.

### Usage

**Bash:**
```bash
./scripts/validate-memory.sh [project-dir]
```

**PowerShell:**
```powershell
.\scripts\validate-memory.ps1 [-ProjectDir <path>]
```

### Checks Performed

1. **Directory Structure** - Verifies all required directories exist:
   - `.claude/memory/`
   - `.claude/memory/sessions/`
   - `.claude/memory/decisions/`
   - `.claude/memory/knowledge/`
   - `.claude/plans/`

2. **Required Files** - Checks for essential files:
   - `ARCHITECTURE.md`
   - `USAGE.md`
   - `current_context.md`

3. **Template Placeholders** - Warns if files contain unfilled placeholders like `[DATE]`, `[NAME]`, etc.

4. **Decision Sequence** - Validates decision numbers are sequential (warns about gaps)

5. **Empty Files** - Warns about zero-byte markdown files

### Exit Codes

| Code | Status |
|------|--------|
| 0 | Valid (may include warnings) |
| 1 | Invalid (errors found) |

### Example Output

```
Validating memory system...
Project directory: /path/to/project

=== Directory Structure ===
[OK]    .claude/memory exists
[OK]    .claude/memory/sessions exists
[OK]    .claude/memory/decisions exists
[OK]    .claude/memory/knowledge exists
[OK]    .claude/plans exists

=== Required Files ===
[OK]    .claude/memory/ARCHITECTURE.md exists
[OK]    .claude/memory/USAGE.md exists
[OK]    .claude/memory/current_context.md exists

=== Template Placeholders ===
[WARN]  .claude/memory/current_context.md contains unfilled template placeholders
[OK]    .claude/plans/active_plan.md has no template placeholders

=== Decision Sequence ===
[OK]    Decision numbers are sequential (1-5)
    Total decisions: 5

=== Empty Files Check ===
[OK]    No empty markdown files found

===============================
=== Validation Summary ===
===============================
Errors:   0
Warnings: 1

Status: VALID with warnings - Consider addressing warnings
```

### When to Use

- After initial setup to verify installation
- Before committing memory system changes
- When troubleshooting memory system issues
- As part of CI/CD pipeline

---

## Automation Examples

### Cron (Linux/macOS)

Add to crontab with `crontab -e`:

```cron
# Run session pruning weekly on Sundays at 2 AM
0 2 * * 0 /path/to/project/scripts/prune-sessions.sh 30 /path/to/project

# Rebuild knowledge index daily at midnight
0 0 * * * /path/to/project/scripts/index-knowledge.sh /path/to/project

# Validate memory system daily at 1 AM
0 1 * * * /path/to/project/scripts/validate-memory.sh /path/to/project
```

### Windows Task Scheduler

Create scheduled tasks using PowerShell:

```powershell
# Weekly session pruning
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-File C:\project\scripts\prune-sessions.ps1 -Days 30 -ProjectDir C:\project"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
Register-ScheduledTask -TaskName "PruneClaudeSessions" -Action $action -Trigger $trigger

# Daily knowledge index
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-File C:\project\scripts\index-knowledge.ps1 -ProjectDir C:\project"
$trigger = New-ScheduledTaskTrigger -Daily -At 12am
Register-ScheduledTask -TaskName "IndexClaudeKnowledge" -Action $action -Trigger $trigger

# Daily validation
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-File C:\project\scripts\validate-memory.ps1 -ProjectDir C:\project"
$trigger = New-ScheduledTaskTrigger -Daily -At 1am
Register-ScheduledTask -TaskName "ValidateClaudeMemory" -Action $action -Trigger $trigger
```

### Git Hooks

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Validate memory system before commits

./scripts/validate-memory.sh
if [ $? -ne 0 ]; then
    echo "Memory system validation failed. Fix errors before committing."
    exit 1
fi
```

---

## Troubleshooting

### Scripts not executable (Linux/macOS)

```bash
chmod +x scripts/*.sh
```

### PowerShell execution policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Missing directories

Run the setup script first:

```bash
./setup.sh
# or
.\setup.ps1
```

---

---

## auto-summary

Generates a draft session summary by analyzing git changes since the last session.

### Usage

**Bash:**
```bash
./scripts/auto-summary.sh [project-dir] [options]
```

**PowerShell:**
```powershell
.\scripts\auto-summary.ps1 [-ProjectDir <path>] [-Output <file>] [-Since <timestamp>]
```

### Options

| Option | Description |
|--------|-------------|
| `--output FILE` | Write to file instead of stdout |
| `--since TIMESTAMP` | Diff since this time (default: last session) |
| `--help` | Show help |

### Example Output

```markdown
# Session Summary: 2024-01-15 16:30

## Git Activity
- Files changed: 5
- Insertions: +120
- Deletions: -45
- Commits: 3

### Changed Files
- src/auth/token.ts (modified)
- src/api/routes.ts (modified)
- tests/auth.test.ts (added)

### Commit Messages
- "Fix token refresh race condition"
- "Add retry logic with backoff"

## Draft Summary
Modified authentication and API code with new tests.
Focused on token handling improvements.

## Work Completed (fill in)
- [ ]

## Decisions Made
- [ ]

## Next Steps
- [ ]
```

### When to Use

- At the end of a session to draft your summary
- When you forgot what you worked on
- To capture git activity automatically

---

## link-knowledge

Scans knowledge files and suggests/creates cross-references between related topics.

### Usage

**Bash:**
```bash
./scripts/link-knowledge.sh [project-dir] [options]
```

**PowerShell:**
```powershell
.\scripts\link-knowledge.ps1 [-ProjectDir <path>] [-AutoInsert] [-DryRun]
```

### Options

| Option | Description |
|--------|-------------|
| `--auto-insert` | Automatically insert suggested links |
| `--dry-run` | Show changes without modifying files |
| `--help` | Show help |

### Example Output

```
Scanning knowledge base for cross-references...

=== Suggested Links ===

File: authentication.md
  Line 15: "token refresh" -> [Token Patterns](./token-patterns.md)
  Line 23: "rate limiting" -> [API Patterns](./api-patterns.md)

File: api-patterns.md
  Line 8: "OAuth2" -> [Authentication](./authentication.md)

=== Summary ===
Files scanned: 5
Links suggested: 3
```

### When to Use

- After adding new knowledge files
- When knowledge base grows large
- To improve discoverability

---

## memory-analytics

Generates analytics about memory system usage patterns.

### Usage

**Bash:**
```bash
./scripts/memory-analytics.sh [project-dir] [options]
```

**PowerShell:**
```powershell
.\scripts\memory-analytics.ps1 [-ProjectDir <path>] [-Json]
```

### Options

| Option | Description |
|--------|-------------|
| `--json` | Output as JSON for programmatic use |
| `--help` | Show help |

### Example Output

```
=== Memory System Analytics ===

## Overview
- Total sessions: 45
- Total decisions: 12
- Knowledge topics: 8
- Active plan: Auth Refactor

## Activity Trends
This week:  5 sessions, 2 decisions
Last week:  7 sessions, 1 decision
This month: 23 sessions, 5 decisions

## Most Active
- Day: Tuesday (12 sessions)
- Hour: 2-3 PM (18 sessions)

## Knowledge Health
| Topic | Last Updated | Status |
|-------|--------------|--------|
| auth | 2 days | Fresh |
| api | 15 days | Recent |
| db | 45 days | Stale |
```

### When to Use

- Weekly/monthly reviews
- Understanding work patterns
- Identifying stale content

---

## generate-dashboard

Creates a comprehensive markdown dashboard summarizing memory system state.

### Usage

**Bash:**
```bash
./scripts/generate-dashboard.sh [project-dir] [output-file]
```

**PowerShell:**
```powershell
.\scripts\generate-dashboard.ps1 [-ProjectDir <path>] [-Output <file>]
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| output-file | `.claude/memory/DASHBOARD.md` | Where to save dashboard |

### Generated Dashboard

```markdown
# Memory System Dashboard
Generated: 2024-01-15 10:30

## Overview
| Metric | Value |
|--------|-------|
| Total Sessions | 45 |
| Total Decisions | 12 |
| Knowledge Topics | 8 |
| Active Plan | Auth Refactor (60%) |

## Weekly Activity
Week        | Sessions | Decisions
------------|----------|----------
This week   | ████░ 5  | 2
Last week   | ██████░ 7| 1
2 weeks ago | ███░ 4   | 3

## Knowledge Base Health
| Topic | Last Updated | Status |
|-------|--------------|--------|
| authentication | 2 days | 🟢 Fresh |
| api-patterns | 15 days | 🟡 Recent |
| database | 45 days | 🔴 Stale |

## Recommendations
- ⚠️ Update stale knowledge: database (45 days old)
- 💡 3 sessions without decisions - review if any were made
- ✅ Memory system healthy overall

## Quick Actions
- `/memory-status` - Current state
- `/memory-review this week` - Recent activity
- `/memory-knowledge` - Update knowledge base
```

### When to Use

- Start of week for overview
- Before standups/reviews
- Share with team members

---

## Contributing

When modifying these scripts:

1. Update both `.sh` and `.ps1` versions
2. Ensure consistent behavior between versions
3. Update this README with any new features
4. Test on both Windows and Unix systems

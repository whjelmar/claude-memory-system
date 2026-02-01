# Claude Memory System

A comprehensive persistent memory system for cross-session context preservation in Claude Code. Never lose your place again.

## The Problem

Claude Code sessions are ephemeral. When you close a session:
- Claude forgets what you were working on
- You spend time re-explaining context
- Past decisions get re-litigated
- Discoveries and learnings are lost

## The Solution

File-based persistent memory that survives across sessions:
- **Session handoffs** - Pick up exactly where you left off
- **Decision records** - Never forget why you chose X over Y
- **Knowledge base** - Accumulate project learnings over time
- **Task planning** - Track multi-session projects

---

## Quick Start (5 minutes)

```bash
# 1. Clone to templates directory
git clone https://github.com/whjelmar/claude-memory-system.git ~/.claude/templates/claude-memory-system

# 2. Run full setup in your project (includes slash commands)
cd /path/to/your/project
bash ~/.claude/templates/claude-memory-system/setup.sh --full
```

Or on Windows PowerShell:
```powershell
& "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1" -Full
```

Then use it:
```
You: /memory-start          # Load context at session start
You: [work on your project]
You: /memory-save           # Save session at end
```

### Setup Options

| Option | Bash | PowerShell | Description |
|--------|------|------------|-------------|
| Basic | `setup.sh` | `setup.ps1` | Project memory structure only |
| With skills | `setup.sh --install-skills` | `setup.ps1 -InstallSkills` | + slash commands |
| With MCP | `setup.sh --build-mcp` | `setup.ps1 -BuildMcp` | + MCP server |
| Everything | `setup.sh --full` | `setup.ps1 -Full` | All features |

**[→ Full Quick Start Guide](docs/QUICK-START.md)**

---

## Core Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                     SESSION LIFECYCLE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   START SESSION                DURING SESSION               │
│   ─────────────                ──────────────                │
│   /memory-start                • Work normally               │
│   • Loads context              • /memory-decide for choices  │
│   • Shows active plan          • Update progress.md          │
│   • Lists recent sessions      • Add to knowledge base       │
│                                                              │
│                        END SESSION                           │
│                        ───────────                           │
│                        /memory-save                          │
│                        • Creates session summary             │
│                        • Updates context for next time       │
│                        • Records decisions made              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**[→ Complete Workflow Guide](docs/WORKFLOW.md)**

---

## Features

### Slash Commands

| Command | Description |
|---------|-------------|
| `/memory-start` | Load context and resume previous work |
| `/memory-save` | Save session summary, update context |
| `/memory-status` | View memory system state |
| `/memory-decide` | Record a decision (ADR-style) |

**[→ Skills Reference](docs/SKILLS-REFERENCE.md)**

### MCP Tools (Programmatic Access)

| Tool | Description |
|------|-------------|
| `memory_read_context` | Read current context programmatically |
| `memory_save_session` | Save session with structured data |
| `memory_log_decision` | Create auto-numbered decision record |
| `memory_add_knowledge` | Add/update knowledge files |
| `memory_search` | Search across all memory files |

**[→ MCP Tools Reference](docs/MCP-TOOLS.md)**

### Automation Hooks

- **SessionStart**: Auto-reminder to load context
- **Stop**: Reminder to save session before exiting

### Utility Scripts

| Script | Description |
|--------|-------------|
| `validate-memory.sh` | Check system integrity |
| `prune-sessions.sh` | Archive old sessions |
| `index-knowledge.sh` | Generate knowledge index |
| `next-decision-number.sh` | Get next decision number |

---

## The 6-Layer Memory Architecture

```
Layer 1: CLAUDE.md ─────────── Permanent project conventions (auto-loaded)
Layer 2: current_context.md ── What I'm working on right now
Layer 3: sessions/ ─────────── Historical session summaries
Layer 4: decisions/ ────────── Why we chose X over Y (ADRs)
Layer 5: knowledge/ ────────── Accumulated domain knowledge
Layer 6: plans/ ────────────── Active task tracking
```

Each layer serves a different purpose with different lifespans:

| Layer | Lifespan | Purpose |
|-------|----------|---------|
| CLAUDE.md | Permanent | Coding standards, patterns, gotchas |
| current_context.md | Per session | Handoff to next session |
| sessions/ | Permanent archive | What happened, when |
| decisions/ | Permanent | Why we made choices |
| knowledge/ | Permanent, evolving | Domain learnings |
| plans/ | Until task complete | Current task tracking |

**[→ Architecture Deep Dive](docs/WORKFLOW.md#the-6-layer-memory-architecture)**

---

## Directory Structure

After setup:

```
your-project/
├── CLAUDE.md                      # Project conventions (auto-loaded)
└── .claude/
    ├── memory/
    │   ├── ARCHITECTURE.md        # System documentation
    │   ├── USAGE.md               # Templates and guidelines
    │   ├── current_context.md     # Active working context
    │   ├── sessions/              # Session summaries
    │   │   └── 2026-02-01_16-45_summary.md
    │   ├── decisions/             # Decision records
    │   │   └── 0001_use_postgresql.md
    │   └── knowledge/             # Domain knowledge
    │       └── api-patterns.md
    └── plans/
        ├── active_plan.md         # Current implementation plan
        ├── findings.md            # Research discoveries
        └── progress.md            # Task progress tracker
```

---

## Installation Options

### Option 1: Manual Setup (Recommended for first time)

```bash
# Clone
git clone https://github.com/whjelmar/claude-memory-system.git ~/.claude/templates/claude-memory-system

# Run in project
cd /path/to/project
bash ~/.claude/templates/claude-memory-system/setup.sh
```

### Option 2: Shell Alias

Add to `~/.bashrc` or `~/.zshrc`:
```bash
alias claude-memory='bash ~/.claude/templates/claude-memory-system/setup.sh'
```

Then run `claude-memory` in any project.

### Option 3: Auto-Setup Hook

Add to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "[ ! -f .claude/memory/ARCHITECTURE.md ] && bash ~/.claude/templates/claude-memory-system/setup.sh . 2>/dev/null || true"
      }]
    }]
  }
}
```

### Option 4: With MCP Server

```bash
# Install MCP server
cd ~/.claude/templates/claude-memory-system/mcp-server
npm install
npm run build

# Add to Claude Code config (see docs/MCP-TOOLS.md)
```

---

## Example Session

### Starting Work

```
You: /memory-start

Claude: 📋 Current Context (updated 2 hours ago)
        Active Task: User authentication refactor
        Focus: Token refresh implementation

        📊 Active Plan: auth-refactor (Phase 2 of 4)
        ✅ Phase 1: Extract auth module
        🔄 Phase 2: Implement token flow (current)

        📚 Recent Sessions:
        • 2026-02-01 14:30 - Fixed token validation
        • 2026-01-31 16:00 - Completed extraction

        Ready to continue with token refresh?

You: Yes, let's add retry logic for failed refreshes.
```

### Recording a Decision

```
You: /memory-decide

Claude: What decision needs to be recorded?

You: How to handle retry logic for token refresh

Claude: [Interactive prompts for context, options, decision]

Claude: ✅ Created decision 0003_exponential_backoff_retry.md
```

### Ending the Session

```
You: /memory-save

Claude: What work did you complete?

You: Implemented retry logic with exponential backoff

Claude: ✅ Session saved!
        • Created session summary
        • Updated context for next session
        • Decision record linked
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Quick Start](docs/QUICK-START.md) | Get running in 5 minutes |
| [Workflow Guide](docs/WORKFLOW.md) | Complete usage patterns and best practices |
| [Skills Reference](docs/SKILLS-REFERENCE.md) | Detailed slash command documentation |
| [MCP Tools](docs/MCP-TOOLS.md) | Programmatic API reference |
| [Updating](docs/UPDATING.md) | Mid-session updates and version management |

---

## Integration with Claude Code Skills

Works alongside these built-in skills:
- `/project-workflow` - Session management
- `/planning-with-files` - Manus-style task planning
- `/executing-plans` - Resume from previous plans
- `/architecture-decision-records` - Formal ADR creation

---

## Updating

### Quick Update (between sessions)

```bash
cd ~/.claude/templates/claude-memory-system && git pull
cp -r skills/* ~/.claude/skills/  # Update slash commands
```

### Mid-Session Update

When you update while Claude is running:

```bash
# In terminal: pull and copy skills
cd ~/.claude/templates/claude-memory-system && git pull
cp -r skills/* ~/.claude/skills/
```

Then tell Claude to reload:

```
You: The memory system was just updated. Please reload the skills
     by reading ~/.claude/skills/memory-*.md

Claude: [Reads updated skills]
        Reloaded! New features are now available.
```

**[→ Full Update Guide](docs/UPDATING.md)** - Covers differential updates, MCP server updates, breaking changes, and rollback procedures

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `scripts/validate-memory.sh` to verify
5. Submit a pull request

---

## License

MIT

---

## Cheat Sheet

```
┌─────────────────────────────────────────────────────────────┐
│                    CLAUDE MEMORY SYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│  SESSION START          │  SESSION END                      │
│  /memory-start          │  /memory-save                     │
├─────────────────────────┼───────────────────────────────────┤
│  CHECK STATUS           │  RECORD DECISION                  │
│  /memory-status         │  /memory-decide                   │
├─────────────────────────┴───────────────────────────────────┤
│  KEY FILES                                                   │
│  • current_context.md - Session handoff                      │
│  • sessions/ - Historical archive                            │
│  • decisions/ - Why we chose X over Y                        │
│  • knowledge/ - Domain learnings                             │
│  • plans/active_plan.md - Current task                       │
├─────────────────────────────────────────────────────────────┤
│  MAINTENANCE                                                 │
│  • validate-memory.sh - Check integrity                      │
│  • prune-sessions.sh 30 - Archive old sessions               │
│  • index-knowledge.sh - Generate index                       │
└─────────────────────────────────────────────────────────────┘
```

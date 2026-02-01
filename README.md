# Claude Memory System

A file-based persistent memory system for cross-session context preservation in Claude Code.

## Features

- **Session continuity**: Pick up where you left off across sessions
- **Decision logging**: Track why you chose X over Y (ADRs)
- **Task planning**: Manus-style file-based planning with progress tracking
- **Knowledge accumulation**: Build project-specific knowledge over time
- **Parallel agents**: Patterns for spawning background research agents

## Quick Start

### 1. Clone to your Claude templates directory

**Bash (Linux/macOS/Git Bash on Windows):**
```bash
git clone https://github.com/whjelmar/claude-memory-system.git ~/.claude/templates/claude-memory-system
```

**PowerShell (Windows):**
```powershell
git clone https://github.com/whjelmar/claude-memory-system.git "$env:USERPROFILE\.claude\templates\claude-memory-system"
```

### 2. Run setup in your project

**Bash:**
```bash
bash ~/.claude/templates/claude-memory-system/setup.sh
```

**PowerShell:**
```powershell
& "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1"
```

### 3. (Optional) Add SessionStart hook for auto-setup

This automatically sets up the memory system when Claude Code starts in a project that doesn't have it.

Edit your Claude settings file:
- **Linux/macOS**: `~/.claude/settings.json`
- **Windows**: `%USERPROFILE%\.claude\settings.json`

Add or merge this hook configuration:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "[ ! -f .claude/memory/ARCHITECTURE.md ] && bash ~/.claude/templates/claude-memory-system/setup.sh . 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

> **Note**: Claude Code runs bash even on Windows, so the hook command uses bash syntax.

---

## Installation Options Summary

| Method | When to Use | Command |
|--------|-------------|---------|
| **Manual** | One-off setup | `bash ~/.claude/templates/claude-memory-system/setup.sh` |
| **Alias** | Frequent use | Add alias, then run `claude-memory` |
| **SessionStart Hook** | Auto-setup on new projects | Add hook to settings.json |

### Shell Alias Setup

**Bash (`~/.bashrc` or `~/.zshrc`):**
```bash
alias claude-memory='bash ~/.claude/templates/claude-memory-system/setup.sh'
```

**PowerShell (`$PROFILE`):**
```powershell
function claude-memory { & "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1" }
```

---

## What Gets Created

```
your-project/
├── CLAUDE.md                    # Updated with memory system section
└── .claude/
    ├── memory/
    │   ├── ARCHITECTURE.md      # System documentation
    │   ├── USAGE.md             # Templates and guidelines
    │   ├── current_context.md   # Active working context
    │   ├── sessions/            # Session summaries
    │   ├── decisions/           # Decision records (ADRs)
    │   └── knowledge/           # Domain knowledge
    └── plans/
        ├── active_plan.md       # Current implementation plan
        ├── findings.md          # Research discoveries
        └── progress.md          # Task progress tracker
```

---

## Usage

### Session Start
Read these files to restore context:
```
.claude/memory/current_context.md   # What we're working on
.claude/plans/active_plan.md        # Current plan (if exists)
```

### During Session
- Update `progress.md` as tasks complete
- Create decision records in `decisions/` for significant choices
- Add to `findings.md` when discovering important information

### Session End
1. Create summary: `.claude/memory/sessions/YYYY-MM-DD_HH-MM_summary.md`
2. Update `current_context.md` for next session
3. Update `CLAUDE.md` if new patterns were discovered

### Parallel Agent Orchestration
```python
# Spawn research agents in background
Task(subagent_type="Explore", prompt="Find all auth code", run_in_background=True)
Task(subagent_type="Plan", prompt="Design new feature", run_in_background=True)

# Check results
TaskOutput(task_id="...", block=False)
```

---

## Skills Integration

Works with these Claude Code skills:
- `/project-workflow` - Session management including `/wrap-session`
- `/planning-with-files` - Manus-style task planning
- `/executing-plans` - Resume work from previous sessions
- `/architecture-decision-records` - Formal ADR creation

---

## Updating Templates

Pull the latest templates:

**Bash:**
```bash
cd ~/.claude/templates/claude-memory-system && git pull
```

**PowerShell:**
```powershell
Push-Location "$env:USERPROFILE\.claude\templates\claude-memory-system"; git pull; Pop-Location
```

---

## File Templates

See [USAGE.md](templates/USAGE.md) for:
- Session summary template
- Decision record template
- Knowledge file template

---

## License

MIT

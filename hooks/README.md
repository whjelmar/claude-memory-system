# Claude Memory System Hooks

Automation hooks to integrate the memory system with Claude Code sessions.

## Overview

These hooks automate memory system operations at key points in your Claude Code workflow:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `session-start` | SessionStart | Initialize context, show reminders |
| `session-end` | Stop | Remind to save context, show changes |

## Hook Descriptions

### session-start.sh / session-start.ps1

Runs when a Claude Code session begins.

**Actions:**
1. Locates project root (looks for `.claude/` or `.git/`)
2. Checks if memory system is initialized (`.claude/memory/ARCHITECTURE.md` exists)
3. If not initialized, attempts to run setup script
4. If initialized, displays:
   - Last modification date of current context
   - First 5 lines of `current_context.md` as a quick reminder
   - Tip to read full memory files

**Exit Codes:**
- `0` - Success, memory system ready
- `1` - Setup needed or failed

### session-end.sh / session-end.ps1

Runs when a Claude Code session ends (Stop hook).

**Actions:**
1. Checks if `current_context.md` was modified today
2. If not modified, reminds user to save session summary
3. Lists files modified according to `git status`

**Exit Codes:**
- `0` - Success (silent if no reminders needed)
- `1` - Warning (context may need update)

## Installation

### Method 1: Project Settings (Recommended)

Create or edit `.claude/settings.json` in your project:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/session-start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
```

### Method 2: User Settings (Global)

Edit your user settings at:
- **Windows:** `%APPDATA%\Claude\settings.json`
- **macOS:** `~/Library/Application Support/Claude/settings.json`
- **Linux:** `~/.config/claude/settings.json`

Use absolute paths for global hooks:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/claude-memory-system/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### Windows-Specific Configuration

For PowerShell on Windows:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File hooks/session-start.ps1"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File hooks/session-end.ps1"
          }
        ]
      }
    ]
  }
}
```

### Cross-Platform Configuration

For projects used on both Unix and Windows, you can use conditional logic or install both:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/session-start.sh 2>/dev/null || powershell -ExecutionPolicy Bypass -File hooks/session-start.ps1"
          }
        ]
      }
    ]
  }
}
```

## Using Matchers

Matchers let you run hooks only for specific projects or paths:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "**/my-project/**",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

### Hook Not Running

1. **Check file permissions:**
   ```bash
   chmod +x hooks/session-start.sh
   chmod +x hooks/session-end.sh
   ```

2. **Verify settings.json syntax:**
   ```bash
   cat .claude/settings.json | python -m json.tool
   ```

3. **Test hook manually:**
   ```bash
   bash hooks/session-start.sh
   echo $?  # Should be 0
   ```

### PowerShell Execution Policy

If PowerShell scripts won't run:

```powershell
# Check current policy
Get-ExecutionPolicy

# For current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or use bypass in the command (already included in examples)
powershell -ExecutionPolicy Bypass -File hooks/session-start.ps1
```

### Path Issues

1. **Relative paths** work when hooks are in the project directory
2. **Absolute paths** are needed for global user settings
3. **Windows paths** use backslashes but JSON needs escaping: `"C:\\path\\to\\hook.ps1"`

### Hook Errors

- Hooks that exit with non-zero codes may show warnings
- Check hook output for error messages
- Ensure all required files exist (`.claude/memory/` directory)

### Git Not Found

The session-end hook uses git for status. If git isn't available:
- The hook will still run
- Git-related output will be skipped
- No error will be shown

## Customization

### Modifying Context Preview Lines

In `session-start.sh`, change the number of preview lines:

```bash
# Show more context lines
head -n 10 "$CONTEXT_FILE"
```

### Adding Custom Checks

Add your own checks to the hooks:

```bash
# Example: Check for TODO items
if grep -q "TODO" "$CONTEXT_FILE"; then
    echo "Reminder: You have pending TODOs in your context"
fi
```

### Integrating with Other Tools

```bash
# Example: Send notification on session end
if [[ "$NEEDS_UPDATE" == "true" ]]; then
    notify-send "Claude Session" "Remember to save your context!"
fi
```

## Files Reference

```
hooks/
├── README.md              # This documentation
├── session-start.sh       # Bash session start hook
├── session-start.ps1      # PowerShell session start hook
├── session-end.sh         # Bash session end hook
├── session-end.ps1        # PowerShell session end hook
└── settings-example.json  # Example Claude Code settings
```

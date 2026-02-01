# Quick Start Guide

Get up and running with the Claude Memory System in 5 minutes.

---

## 1. Install (2 minutes)

### Clone the repository

```bash
# Linux/macOS/Git Bash
git clone https://github.com/whjelmar/claude-memory-system.git ~/.claude/templates/claude-memory-system

# Windows PowerShell
git clone https://github.com/whjelmar/claude-memory-system.git "$env:USERPROFILE\.claude\templates\claude-memory-system"
```

### Run setup in your project

```bash
# Navigate to your project
cd /path/to/your/project

# Run setup (Linux/macOS/Git Bash)
bash ~/.claude/templates/claude-memory-system/setup.sh

# Or PowerShell
& "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1"
```

### Install slash commands (optional but recommended)

```bash
# Linux/macOS
cp -r ~/.claude/templates/claude-memory-system/skills/* ~/.claude/skills/

# Windows PowerShell
Copy-Item -Recurse "$env:USERPROFILE\.claude\templates\claude-memory-system\skills\*" "$env:USERPROFILE\.claude\skills\"
```

---

## 2. Your First Session (1 minute)

### Start the session

```
You: /memory-start

Claude: No previous context found. This looks like a fresh start!
        What are you working on today?

You: I'm building a REST API for a todo app.

Claude: Got it! I'll help you build the todo API. Let me set up
        the initial context...
```

### Work on your project

Just work normally with Claude. When you:
- Make a significant decision → use `/memory-decide`
- Discover something important → mention it for the knowledge base
- Complete a task → Claude can update progress

### End the session

```
You: /memory-save

Claude: Let's save this session. What did you accomplish?

You: Set up Express server, created Todo model, implemented
     GET and POST endpoints

Claude: Any decisions made?

You: Decided to use MongoDB for flexibility with todo metadata

Claude: What should next session focus on?

You: Implement PUT and DELETE, then add authentication

Claude: ✅ Session saved! See you next time.
```

---

## 3. Next Session (30 seconds)

```
You: /memory-start

Claude: 📋 Welcome back! Here's where we left off:

        Last session (2 hours ago):
        - Set up Express server
        - Created Todo model
        - Implemented GET/POST endpoints

        Next up:
        - Implement PUT and DELETE
        - Add authentication

        Ready to continue?

You: Yes, let's implement the PUT endpoint first.
```

---

## That's It!

You now know the core workflow:
1. **Start**: `/memory-start`
2. **Work**: Build your project
3. **End**: `/memory-save`

---

## Optional Enhancements

### Auto-setup for new projects

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

### Check memory status anytime

```
You: /memory-status

Claude: 📊 Memory System Status
        • 5 sessions recorded
        • 2 decisions logged
        • 1 knowledge file
        • Last activity: 10 minutes ago
```

### Record decisions

```
You: /memory-decide

Claude: What decision needs to be recorded?

You: Using JWT for authentication instead of sessions

Claude: [Walks through decision recording]

Claude: ✅ Created decision 0003_jwt_authentication.md
```

---

## Next Steps

- Read the [Complete Workflow Guide](./WORKFLOW.md) for advanced usage
- Check [Skills Reference](./SKILLS-REFERENCE.md) for command details
- See [MCP Tools](./MCP-TOOLS.md) for programmatic access

---

## Cheat Sheet

```
┌────────────────────────────────────────┐
│         MEMORY SYSTEM CHEAT SHEET      │
├────────────────────────────────────────┤
│  SESSION START                         │
│  /memory-start                         │
├────────────────────────────────────────┤
│  SESSION END                           │
│  /memory-save                          │
├────────────────────────────────────────┤
│  CHECK STATUS                          │
│  /memory-status                        │
├────────────────────────────────────────┤
│  RECORD DECISION                       │
│  /memory-decide                        │
├────────────────────────────────────────┤
│  KEY FILES                             │
│  .claude/memory/current_context.md     │
│  .claude/memory/sessions/              │
│  .claude/memory/decisions/             │
│  .claude/memory/knowledge/             │
│  .claude/plans/active_plan.md          │
└────────────────────────────────────────┘
```

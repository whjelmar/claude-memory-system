# Updating the Claude Memory System

This guide covers how to update the memory system, including mid-session updates when new features are released.

---

## Table of Contents

1. [Quick Update (Between Sessions)](#quick-update-between-sessions)
2. [Mid-Session Updates](#mid-session-updates)
3. [What Gets Updated](#what-gets-updated)
4. [Handling Breaking Changes](#handling-breaking-changes)
5. [Rollback Procedures](#rollback-procedures)

---

## Quick Update (Between Sessions)

The simplest update when you're not in an active session:

```bash
# Pull latest changes
cd ~/.claude/templates/claude-memory-system
git pull

# Re-copy skills (if skills were updated)
cp -r skills/* ~/.claude/skills/

# Rebuild MCP server (if MCP was updated)
cd mcp-server && npm install && npm run build
```

---

## Mid-Session Updates

When you want to update while Claude is running, you have several options depending on what changed.

### Option 1: Hot-Reload Skills Only

If only skill files (slash commands) were updated:

```bash
# In a terminal (not through Claude), pull and copy
cd ~/.claude/templates/claude-memory-system && git pull
cp -r skills/* ~/.claude/skills/
```

Then tell Claude to reload:

```
You: The memory system skills were just updated. Please reload
     the skill definitions by re-reading them from ~/.claude/skills/

Claude: I'll reload the memory system skills...
        [Reads updated skill files]
        Skills reloaded. The updated commands are now available.
```

### Option 2: Update Scripts and Hooks

Scripts and hooks can be updated without restarting:

```bash
# Pull latest
cd ~/.claude/templates/claude-memory-system && git pull
```

The updated scripts will be used on next invocation. No reload needed.

### Option 3: Update MCP Server (Requires Restart)

If the MCP server code changed, you need to rebuild and restart:

```bash
# Rebuild
cd ~/.claude/templates/claude-memory-system/mcp-server
git pull
npm install
npm run build
```

Then restart Claude Code to reload the MCP server, or if your setup supports it:

```
You: The MCP server was updated. Can you reconnect to the
     claude-memory MCP server?

Claude: I'll attempt to reconnect to the MCP server...
        [Reconnects or indicates restart needed]
```

**Note:** Most MCP configurations require a full Claude Code restart to reload servers.

### Option 4: Update Templates for New Projects

Template updates only affect new project setups:

```bash
cd ~/.claude/templates/claude-memory-system && git pull
```

Existing projects keep their current templates. To update an existing project's templates:

```bash
# Backup existing
cp -r .claude/memory .claude/memory.bak

# Copy new templates (preserves your data files)
cp ~/.claude/templates/claude-memory-system/templates/ARCHITECTURE.md .claude/memory/
cp ~/.claude/templates/claude-memory-system/templates/USAGE.md .claude/memory/
```

---

## Differential Updates

### Check What Changed

Before updating, see what's new:

```bash
cd ~/.claude/templates/claude-memory-system

# See commits since your last pull
git log --oneline HEAD..origin/main

# See changed files
git diff --name-only HEAD..origin/main

# See detailed changes
git diff HEAD..origin/main
```

### Update Only What You Need

If you only want specific updates:

```bash
# Fetch without merging
git fetch origin

# Cherry-pick specific changes
git checkout origin/main -- skills/memory-start.md

# Or update specific directories
git checkout origin/main -- scripts/
```

### Tell Claude What Changed

After updating, inform Claude about new capabilities:

```
You: I just updated the memory system from the repo. The changes include:
     - New `/memory-search` command for searching across memory files
     - Updated session summary format with better structure
     - New `prune-sessions.sh` script

     Please read the updated skill files to learn the new features.

Claude: I'll read the updated skills to understand the new features...
        [Reads ~/.claude/skills/memory-*.md]

        Got it! I now have access to:
        - /memory-search - I can search across sessions, decisions,
          and knowledge files
        - Updated /memory-save - Uses improved summary structure
        - prune-sessions.sh - Available for archiving old sessions

        Would you like to try any of these new features?
```

---

## What Gets Updated

Different components have different update mechanisms:

| Component | Location | Update Method | Restart Required? |
|-----------|----------|---------------|-------------------|
| Skills (slash commands) | `~/.claude/skills/` | Copy files, tell Claude to reload | No |
| Setup scripts | Template directory | Git pull | No |
| Utility scripts | Template directory | Git pull | No |
| Hooks | Template directory | Git pull | No |
| MCP server | Template directory | Rebuild + restart | Yes |
| Templates | Template directory | Git pull (new projects only) | No |
| Project memory files | `.claude/memory/` | Never auto-updated | N/A |

### Files That Are NEVER Overwritten

Your project-specific data is never touched by updates:

```
.claude/memory/current_context.md    # Your context
.claude/memory/sessions/*            # Your session history
.claude/memory/decisions/*           # Your decisions
.claude/memory/knowledge/*           # Your knowledge base
.claude/plans/*                      # Your active plans
```

---

## Mid-Session Update Workflow

Here's a complete workflow for updating mid-session:

### Step 1: Save Current Work

```
You: /memory-save

Claude: [Saves current session]
```

### Step 2: Pull Updates (in terminal)

```bash
cd ~/.claude/templates/claude-memory-system
git pull
```

### Step 3: Check What Changed

```bash
git log --oneline -5  # See recent changes
```

### Step 4: Apply Updates

```bash
# Skills
cp -r skills/* ~/.claude/skills/

# MCP (if changed)
cd mcp-server && npm install && npm run build
```

### Step 5: Reload in Claude

```
You: I just updated the memory system. Please reload the skills
     from ~/.claude/skills/memory-*.md

Claude: [Reads updated skills]
        Reloaded! New features available:
        - [lists new capabilities]
```

### Step 6: Continue Working

```
You: /memory-start

Claude: [Uses updated /memory-start with new features]
```

---

## Handling Breaking Changes

Occasionally, updates may include breaking changes. Here's how to handle them:

### Check for Breaking Changes

```bash
# Look for BREAKING in commit messages
git log --oneline --grep="BREAKING"

# Check the changelog
cat CHANGELOG.md
```

### Common Breaking Changes

| Change | Impact | Migration |
|--------|--------|-----------|
| Skill parameter changes | Commands may work differently | Re-read skill docs |
| File format changes | Old files may need migration | Run migration script |
| Directory structure changes | Paths may change | Re-run setup.sh |
| MCP tool schema changes | Tool calls may fail | Restart Claude Code |

### Migration Scripts

If a breaking change requires migration, we provide scripts:

```bash
# Check for migration scripts
ls scripts/migrate-*.sh

# Run migration
bash scripts/migrate-v2-to-v3.sh
```

---

## Rollback Procedures

If an update causes issues:

### Rollback Skills

```bash
cd ~/.claude/templates/claude-memory-system
git checkout HEAD~1 -- skills/
cp -r skills/* ~/.claude/skills/
```

### Rollback Everything

```bash
cd ~/.claude/templates/claude-memory-system
git log --oneline -10  # Find the commit to rollback to
git checkout <commit-hash>
```

### Rollback MCP Server

```bash
cd ~/.claude/templates/claude-memory-system
git checkout HEAD~1 -- mcp-server/
cd mcp-server && npm install && npm run build
# Restart Claude Code
```

---

## Staying Updated

### Watch for Updates

```bash
# Check for updates without pulling
cd ~/.claude/templates/claude-memory-system
git fetch
git log --oneline HEAD..origin/main
```

### Automatic Update Checks

Add to your shell profile for update notifications:

```bash
# .bashrc or .zshrc
claude_memory_check_updates() {
    cd ~/.claude/templates/claude-memory-system 2>/dev/null || return
    git fetch -q
    local behind=$(git rev-list --count HEAD..origin/main)
    if [ "$behind" -gt 0 ]; then
        echo "📦 Claude Memory System: $behind updates available"
    fi
    cd - > /dev/null
}

# Run on shell start (optional)
claude_memory_check_updates
```

---

## Update Checklist

Use this checklist when updating:

```
□ Save current session (/memory-save)
□ Check what changed (git log, CHANGELOG.md)
□ Look for breaking changes
□ Pull updates (git pull)
□ Copy skills (cp -r skills/* ~/.claude/skills/)
□ Rebuild MCP if needed (npm run build)
□ Restart Claude Code if MCP changed
□ Tell Claude to reload skills
□ Test new features
□ Resume work (/memory-start)
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│                    UPDATE CHEAT SHEET                        │
├─────────────────────────────────────────────────────────────┤
│  CHECK FOR UPDATES                                           │
│  cd ~/.claude/templates/claude-memory-system                 │
│  git fetch && git log --oneline HEAD..origin/main            │
├─────────────────────────────────────────────────────────────┤
│  QUICK UPDATE                                                │
│  git pull                                                    │
│  cp -r skills/* ~/.claude/skills/                            │
├─────────────────────────────────────────────────────────────┤
│  FULL UPDATE (with MCP)                                      │
│  git pull                                                    │
│  cp -r skills/* ~/.claude/skills/                            │
│  cd mcp-server && npm install && npm run build               │
│  [Restart Claude Code]                                       │
├─────────────────────────────────────────────────────────────┤
│  TELL CLAUDE TO RELOAD                                       │
│  "Please reload memory skills from ~/.claude/skills/"        │
├─────────────────────────────────────────────────────────────┤
│  ROLLBACK                                                    │
│  git checkout HEAD~1 -- skills/                              │
│  cp -r skills/* ~/.claude/skills/                            │
└─────────────────────────────────────────────────────────────┘
```

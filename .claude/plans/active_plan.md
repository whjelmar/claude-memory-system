# Active Plan: Claude Memory System Enhancement

**Created**: 2026-02-01
**Status**: In Progress
**Goal**: Transform file-based memory system into a full-featured Claude Code plugin with slash commands, MCP tools, and automation

## Overview

This plan enhances the existing file-based memory system by adding:
1. Custom slash commands for common operations
2. MCP server with programmatic tools
3. Automation hooks for session lifecycle
4. Utility scripts for maintenance tasks

## Implementation Steps

### Phase 1: Slash Commands (Parallel)
Create skill files in `skills/` directory:

- [ ] `/memory-start` - Read and display context files at session start
- [ ] `/memory-save` - Interactive session summary creation
- [ ] `/memory-status` - Show current memory state overview
- [ ] `/memory-decide` - Create decision record with auto-numbering

### Phase 2: MCP Server (Parallel)
Create MCP server in `mcp-server/` directory:

- [ ] Package setup (package.json, tsconfig.json)
- [ ] Server entry point with stdio transport
- [ ] Tool: `memory_read_context` - Read current context
- [ ] Tool: `memory_save_session` - Save session summary
- [ ] Tool: `memory_log_decision` - Create decision record
- [ ] Tool: `memory_add_knowledge` - Add knowledge entry
- [ ] Tool: `memory_search` - Search across all memory files

### Phase 3: Automation Hooks (Parallel)
Create hook scripts in `hooks/` directory:

- [ ] SessionStart hook - Auto-inject context reminder
- [ ] Stop hook - Prompt for session summary
- [ ] Hook configuration templates for settings.json

### Phase 4: Utility Scripts (Parallel)
Create utilities in `scripts/` directory:

- [ ] `next-decision-number.sh/.ps1` - Get next decision number
- [ ] `prune-sessions.sh/.ps1` - Archive old sessions
- [ ] `index-knowledge.sh/.ps1` - Generate knowledge index
- [ ] `validate-memory.sh/.ps1` - Check memory system integrity

### Phase 5: Documentation Update
- [ ] Update README.md with new features
- [ ] Add CONTRIBUTING.md
- [ ] Update USAGE.md with command reference
- [ ] Add examples directory

## Success Criteria
- [ ] All 4 slash commands work correctly
- [ ] MCP server runs and all tools function
- [ ] Hooks integrate with Claude Code
- [ ] Utility scripts work on both bash and PowerShell
- [ ] Documentation is complete and accurate

## Dependencies
- Claude Code skill format knowledge
- MCP SDK for TypeScript
- Claude Code hooks API

## Architecture Decisions

### AD-001: Skill vs MCP Tools
Skills are used for interactive workflows (user-facing commands).
MCP tools are used for programmatic access (agent-callable functions).
Both can coexist and complement each other.

### AD-002: TypeScript for MCP Server
Using TypeScript for the MCP server because:
- Official MCP SDK is TypeScript-first
- Better type safety for tool schemas
- Easier integration with Claude Code ecosystem

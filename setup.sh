#!/bin/bash
# Memory System Setup Script (Bash)
# Run this in any project to set up the persistent memory system
#
# Usage: bash ~/.claude/templates/claude-memory-system/setup.sh
#    or: bash ~/.claude/templates/claude-memory-system/setup.sh /path/to/project
#
# Options:
#   --install-skills    Also install slash commands to ~/.claude/skills/
#   --build-mcp         Also build the MCP server (requires Node.js)
#   --full              Install everything (skills + MCP)

set -e

# Determine script location (works even when called via symlink)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
SKILLS_DIR="$SCRIPT_DIR/skills"
MCP_DIR="$SCRIPT_DIR/mcp-server"

# Parse arguments
PROJECT_DIR=""
INSTALL_SKILLS=false
BUILD_MCP=false

for arg in "$@"; do
    case $arg in
        --install-skills)
            INSTALL_SKILLS=true
            ;;
        --build-mcp)
            BUILD_MCP=true
            ;;
        --full)
            INSTALL_SKILLS=true
            BUILD_MCP=true
            ;;
        -*)
            echo "Unknown option: $arg"
            echo "Usage: setup.sh [project_dir] [--install-skills] [--build-mcp] [--full]"
            exit 1
            ;;
        *)
            PROJECT_DIR="$arg"
            ;;
    esac
done

# Default project dir to current directory
PROJECT_DIR="${PROJECT_DIR:-.}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Claude Memory System Setup                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Project directory: $PROJECT_DIR"
echo ""

# =============================================================================
# PHASE 1: Project Setup (memory directories and templates)
# =============================================================================

echo "Phase 1: Setting up project memory structure..."
echo ""

# Create directory structure
echo "  Creating directories..."
mkdir -p "$PROJECT_DIR/.claude/memory/sessions"
mkdir -p "$PROJECT_DIR/.claude/memory/decisions"
mkdir -p "$PROJECT_DIR/.claude/memory/knowledge"
mkdir -p "$PROJECT_DIR/.claude/plans"

# Copy template files (only if they don't exist or are still templates)
echo "  Copying templates..."

copy_if_template() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ ! -f "$dest" ]; then
        cp "$src" "$dest"
        echo "    Created: $name"
    elif grep -q "\[DATE\]\|\[NAME\]\|\[Brief description\]" "$dest" 2>/dev/null; then
        # File exists but is still a template, overwrite
        cp "$src" "$dest"
        echo "    Updated: $name (was still a template)"
    else
        echo "    Skipped: $name (already has content)"
    fi
}

copy_if_template "$TEMPLATE_DIR/ARCHITECTURE.md" "$PROJECT_DIR/.claude/memory/ARCHITECTURE.md" ".claude/memory/ARCHITECTURE.md"
copy_if_template "$TEMPLATE_DIR/USAGE.md" "$PROJECT_DIR/.claude/memory/USAGE.md" ".claude/memory/USAGE.md"
copy_if_template "$TEMPLATE_DIR/current_context.md" "$PROJECT_DIR/.claude/memory/current_context.md" ".claude/memory/current_context.md"
copy_if_template "$TEMPLATE_DIR/active_plan.md" "$PROJECT_DIR/.claude/plans/active_plan.md" ".claude/plans/active_plan.md"
copy_if_template "$TEMPLATE_DIR/findings.md" "$PROJECT_DIR/.claude/plans/findings.md" ".claude/plans/findings.md"
copy_if_template "$TEMPLATE_DIR/progress.md" "$PROJECT_DIR/.claude/plans/progress.md" ".claude/plans/progress.md"

# Create .gitkeep files
echo "  Creating .gitkeep files..."
echo "# Session summaries stored here" > "$PROJECT_DIR/.claude/memory/sessions/.gitkeep"
echo "# Decision records stored here" > "$PROJECT_DIR/.claude/memory/decisions/.gitkeep"
echo "# Domain knowledge files stored here" > "$PROJECT_DIR/.claude/memory/knowledge/.gitkeep"

# Update or create CLAUDE.md
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"

if [ -f "$CLAUDE_MD" ]; then
    if ! grep -q "Session Continuity System" "$CLAUDE_MD"; then
        echo "" >> "$CLAUDE_MD"
        cat "$TEMPLATE_DIR/CLAUDE_SECTION.md" >> "$CLAUDE_MD"
        echo "  Updated: CLAUDE.md (added memory system section)"
    else
        echo "  Skipped: CLAUDE.md (memory section already exists)"
    fi
else
    echo "# CLAUDE.md" > "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    echo "Project instructions for Claude Code." >> "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    cat "$TEMPLATE_DIR/CLAUDE_SECTION.md" >> "$CLAUDE_MD"
    echo "  Created: CLAUDE.md"
fi

echo ""
echo "  ✓ Phase 1 complete: Project memory structure ready"
echo ""

# =============================================================================
# PHASE 2: Install Skills (slash commands)
# =============================================================================

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"

if [ "$INSTALL_SKILLS" = true ]; then
    echo "Phase 2: Installing slash commands..."
    echo ""

    mkdir -p "$CLAUDE_SKILLS_DIR"

    for skill in "$SKILLS_DIR"/*.md; do
        if [ -f "$skill" ]; then
            skill_name=$(basename "$skill" .md)
            skill_dir="$CLAUDE_SKILLS_DIR/$skill_name"
            mkdir -p "$skill_dir"
            cp "$skill" "$skill_dir/SKILL.md"
            echo "  Installed: /$(echo "$skill_name")"
        fi
    done

    echo ""
    echo "  ✓ Phase 2 complete: Slash commands installed"
    echo ""
else
    echo "Phase 2: Skipped (use --install-skills to install slash commands)"
    echo ""
fi

# =============================================================================
# PHASE 3: Build MCP Server
# =============================================================================

if [ "$BUILD_MCP" = true ]; then
    echo "Phase 3: Building MCP server..."
    echo ""

    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        cd "$MCP_DIR"

        if [ ! -d "node_modules" ]; then
            echo "  Installing dependencies..."
            npm install --silent
        fi

        echo "  Building TypeScript..."
        npm run build --silent

        cd - > /dev/null

        echo ""
        echo "  ✓ Phase 3 complete: MCP server built"
        echo ""
        echo "  To use the MCP server, add to your Claude settings:"
        echo "  {"
        echo "    \"mcpServers\": {"
        echo "      \"claude-memory\": {"
        echo "        \"command\": \"node\","
        echo "        \"args\": [\"$MCP_DIR/dist/index.js\"],"
        echo "        \"env\": { \"MEMORY_PROJECT_ROOT\": \"\${workspaceFolder}\" }"
        echo "      }"
        echo "    }"
        echo "  }"
        echo ""
    else
        echo "  ⚠ Node.js not found. Skipping MCP server build."
        echo "  Install Node.js and run: cd $MCP_DIR && npm install && npm run build"
        echo ""
    fi
else
    echo "Phase 3: Skipped (use --build-mcp to build MCP server)"
    echo ""
fi

# =============================================================================
# Summary
# =============================================================================

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Project files created:"
echo "  .claude/memory/ARCHITECTURE.md    - System documentation"
echo "  .claude/memory/USAGE.md           - Usage guide"
echo "  .claude/memory/current_context.md - Session handoff"
echo "  .claude/plans/active_plan.md      - Task planning"
echo "  .claude/plans/findings.md         - Research notes"
echo "  .claude/plans/progress.md         - Progress tracking"
echo ""

if [ "$INSTALL_SKILLS" = true ]; then
    echo "Slash commands installed:"
    echo "  /memory-start   - Load context at session start"
    echo "  /memory-save    - Save session summary"
    echo "  /memory-status  - Show memory system state"
    echo "  /memory-decide  - Record a decision (ADR)"
    echo ""
fi

echo "Quick start:"
echo "  1. Start a session with: /memory-start"
echo "  2. Work on your project"
echo "  3. End session with: /memory-save"
echo ""

if [ "$INSTALL_SKILLS" = false ]; then
    echo "To install slash commands, run:"
    echo "  $0 --install-skills"
    echo ""
fi

if [ "$BUILD_MCP" = false ]; then
    echo "To build MCP server (for programmatic access), run:"
    echo "  $0 --build-mcp"
    echo ""
fi

echo "Full documentation: $SCRIPT_DIR/docs/"
echo ""

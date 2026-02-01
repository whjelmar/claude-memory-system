#!/bin/bash
# Memory System Setup Script (Bash)
# Run this in any project to set up the persistent memory system
#
# Usage: bash ~/.claude/templates/claude-memory-system/setup.sh
#    or: bash ~/.claude/templates/claude-memory-system/setup.sh /path/to/project

set -e

# Determine script location (works even when called via symlink)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"
PROJECT_DIR="${1:-.}"

echo "Setting up Claude Code memory system in: $PROJECT_DIR"
echo ""

# Create directory structure
echo "Creating directories..."
mkdir -p "$PROJECT_DIR/.claude/memory/sessions"
mkdir -p "$PROJECT_DIR/.claude/memory/decisions"
mkdir -p "$PROJECT_DIR/.claude/memory/knowledge"
mkdir -p "$PROJECT_DIR/.claude/plans"

# Copy template files
echo "Copying templates..."
cp "$TEMPLATE_DIR/ARCHITECTURE.md" "$PROJECT_DIR/.claude/memory/"
cp "$TEMPLATE_DIR/USAGE.md" "$PROJECT_DIR/.claude/memory/"
cp "$TEMPLATE_DIR/current_context.md" "$PROJECT_DIR/.claude/memory/"
cp "$TEMPLATE_DIR/active_plan.md" "$PROJECT_DIR/.claude/plans/"
cp "$TEMPLATE_DIR/findings.md" "$PROJECT_DIR/.claude/plans/"
cp "$TEMPLATE_DIR/progress.md" "$PROJECT_DIR/.claude/plans/"

# Create .gitkeep files
echo "# Session summaries stored here" > "$PROJECT_DIR/.claude/memory/sessions/.gitkeep"
echo "# Decision records stored here" > "$PROJECT_DIR/.claude/memory/decisions/.gitkeep"
echo "# Domain knowledge files stored here" > "$PROJECT_DIR/.claude/memory/knowledge/.gitkeep"

# Update or create CLAUDE.md
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"

if [ -f "$CLAUDE_MD" ]; then
    # Check if section already exists
    if ! grep -q "Session Continuity System" "$CLAUDE_MD"; then
        echo "" >> "$CLAUDE_MD"
        cat "$TEMPLATE_DIR/CLAUDE_SECTION.md" >> "$CLAUDE_MD"
        echo "Updated: CLAUDE.md (added memory system section)"
    else
        echo "Skipped: CLAUDE.md (memory section already exists)"
    fi
else
    echo "# CLAUDE.md" > "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    echo "Project instructions for Claude Code." >> "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    cat "$TEMPLATE_DIR/CLAUDE_SECTION.md" >> "$CLAUDE_MD"
    echo "Created: CLAUDE.md"
fi

echo ""
echo "Memory system setup complete!"
echo ""
echo "Files created:"
echo "  .claude/memory/ARCHITECTURE.md"
echo "  .claude/memory/USAGE.md"
echo "  .claude/memory/current_context.md"
echo "  .claude/plans/active_plan.md"
echo "  .claude/plans/findings.md"
echo "  .claude/plans/progress.md"
echo ""
echo "Usage:"
echo "  - Read current_context.md at session start"
echo "  - Update progress.md during work"
echo "  - Create session summaries at session end"
echo ""

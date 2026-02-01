#!/bin/bash
# Claude Memory System - Session Start Hook
# Runs on SessionStart to initialize memory context
#
# Exit codes:
#   0 - Success (memory system ready)
#   1 - Setup needed (will attempt auto-setup)
#   2 - Error

set -e

# Configuration
MEMORY_DIR=".claude/memory"
ARCHITECTURE_FILE="$MEMORY_DIR/ARCHITECTURE.md"
CONTEXT_FILE="$MEMORY_DIR/current_context.md"
SETUP_SCRIPT="scripts/setup.sh"

# Find project root (look for .claude directory or git root)
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.claude" ]] || [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$PWD"
}

PROJECT_ROOT=$(find_project_root)
cd "$PROJECT_ROOT"

# Check if memory system is set up
if [[ ! -f "$ARCHITECTURE_FILE" ]]; then
    echo "Memory system not initialized."

    # Attempt auto-setup if setup script exists
    if [[ -f "$SETUP_SCRIPT" ]]; then
        echo "Running setup..."
        bash "$SETUP_SCRIPT"
        if [[ $? -eq 0 ]]; then
            echo "Memory system initialized successfully."
        else
            echo "Setup failed. Please run setup manually." >&2
            exit 1
        fi
    else
        echo "Please initialize the memory system first." >&2
        echo "Run: bash scripts/setup.sh" >&2
        exit 1
    fi
fi

# Memory system is ready - provide context hint
if [[ -f "$CONTEXT_FILE" ]]; then
    # Get modification date
    if [[ "$(uname)" == "Darwin" ]]; then
        MOD_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$CONTEXT_FILE" 2>/dev/null || echo "unknown")
    else
        MOD_DATE=$(stat -c "%y" "$CONTEXT_FILE" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    fi

    echo "--- Memory Context (last updated: $MOD_DATE) ---"
    head -n 5 "$CONTEXT_FILE" 2>/dev/null || true
    echo "..."
    echo "---"
    echo ""
    echo "Tip: Read .claude/memory/ for full project context"
else
    echo "Memory system ready but no current context found."
    echo "Consider running: /memory-bank:read"
fi

exit 0

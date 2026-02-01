#!/bin/bash
# Claude Memory System - Session End Hook
# Runs on Stop to remind about saving context
#
# Exit codes:
#   0 - Success
#   1 - Warning (context may need update)

set -e

# Configuration
MEMORY_DIR=".claude/memory"
CONTEXT_FILE="$MEMORY_DIR/current_context.md"
DECISIONS_FILE="$MEMORY_DIR/decisions.md"

# Find project root
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

# Check if memory system exists
if [[ ! -d "$MEMORY_DIR" ]]; then
    # Silently exit if memory system not set up
    exit 0
fi

TODAY=$(date +%Y-%m-%d)
NEEDS_UPDATE=false

# Check if current_context.md was modified today
if [[ -f "$CONTEXT_FILE" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        MOD_DATE=$(stat -f "%Sm" -t "%Y-%m-%d" "$CONTEXT_FILE" 2>/dev/null || echo "")
    else
        MOD_DATE=$(stat -c "%y" "$CONTEXT_FILE" 2>/dev/null | cut -d' ' -f1 || echo "")
    fi

    if [[ "$MOD_DATE" != "$TODAY" ]]; then
        NEEDS_UPDATE=true
    fi
else
    NEEDS_UPDATE=true
fi

# Check git status for modified files
GIT_STATUS=""
if command -v git &> /dev/null && [[ -d ".git" ]]; then
    GIT_STATUS=$(git status --porcelain 2>/dev/null || true)
fi

# Output reminders if needed
if [[ "$NEEDS_UPDATE" == "true" ]] || [[ -n "$GIT_STATUS" ]]; then
    echo ""
    echo "=== Session End: Memory System Check ==="

    if [[ "$NEEDS_UPDATE" == "true" ]]; then
        echo ""
        echo "! Context not updated today."
        echo "  Consider saving a session summary to: $CONTEXT_FILE"
        echo "  Run: /memory-bank:save"
    fi

    if [[ -n "$GIT_STATUS" ]]; then
        echo ""
        echo "Modified files in workspace:"
        echo "$GIT_STATUS" | head -20
        TOTAL=$(echo "$GIT_STATUS" | wc -l | tr -d ' ')
        if [[ "$TOTAL" -gt 20 ]]; then
            echo "... and $((TOTAL - 20)) more files"
        fi
    fi

    echo ""
    echo "=== End of Session Check ==="
fi

exit 0

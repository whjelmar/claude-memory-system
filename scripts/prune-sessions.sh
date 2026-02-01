#!/bin/bash
# prune-sessions.sh
# Archives session summaries older than N days
#
# Usage: ./prune-sessions.sh [days] [project-dir]
#   days:        Number of days to keep (default: 30)
#   project-dir: Optional path to project root (default: current directory)
#
# Behavior:
#   - Finds session files older than N days
#   - Moves them to .claude/memory/sessions/archive/
#   - Creates archive directory if needed
#   - Outputs summary of archived files
#
# Exit codes: 0 on success, 1 on error

set -e

# Parse arguments
DAYS="${1:-30}"
PROJECT_DIR="${2:-.}"

# Validate days is a number
if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: Days must be a positive integer" >&2
    exit 1
fi

# Resolve to absolute path
if command -v realpath &> /dev/null; then
    PROJECT_DIR=$(realpath "$PROJECT_DIR")
else
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
fi

SESSIONS_DIR="$PROJECT_DIR/.claude/memory/sessions"
ARCHIVE_DIR="$SESSIONS_DIR/archive"

echo "Pruning sessions older than $DAYS days..."
echo "Sessions directory: $SESSIONS_DIR"
echo ""

# Check if sessions directory exists
if [ ! -d "$SESSIONS_DIR" ]; then
    echo "Sessions directory does not exist. Nothing to prune."
    exit 0
fi

# Create archive directory if needed
if [ ! -d "$ARCHIVE_DIR" ]; then
    mkdir -p "$ARCHIVE_DIR"
    echo "Created archive directory: $ARCHIVE_DIR"
fi

# Find and archive old session files
# Session files are named YYYY-MM-DD_HH-MM_summary.md
archived_count=0
archived_files=""

# Use find to get files older than N days
while IFS= read -r -d '' file; do
    filename=$(basename "$file")

    # Skip .gitkeep and already archived files
    if [[ "$filename" == ".gitkeep" ]] || [[ "$file" == *"/archive/"* ]]; then
        continue
    fi

    # Move to archive
    mv "$file" "$ARCHIVE_DIR/"
    archived_files="$archived_files  - $filename\n"
    ((archived_count++)) || true

done < <(find "$SESSIONS_DIR" -maxdepth 1 -type f -name "*.md" -mtime +$DAYS -print0 2>/dev/null)

echo ""
echo "=== Prune Summary ==="
echo "Days threshold: $DAYS"
echo "Files archived: $archived_count"

if [ $archived_count -gt 0 ]; then
    echo ""
    echo "Archived files:"
    echo -e "$archived_files"
    echo "Archive location: $ARCHIVE_DIR"
else
    echo "No sessions found older than $DAYS days."
fi

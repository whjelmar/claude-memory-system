#!/bin/bash
# next-decision-number.sh
# Scans the decisions directory and outputs the next available decision number
#
# Usage: ./next-decision-number.sh [project-dir]
#   project-dir: Optional path to project root (default: current directory)
#
# Output: Next decision number, zero-padded to 4 digits (e.g., "0001", "0042")
# Exit codes: 0 on success, 1 on error

set -e

# Get project directory (default to current)
PROJECT_DIR="${1:-.}"

# Resolve to absolute path
if command -v realpath &> /dev/null; then
    PROJECT_DIR=$(realpath "$PROJECT_DIR")
else
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
fi

DECISIONS_DIR="$PROJECT_DIR/.claude/memory/decisions"

# Check if decisions directory exists
if [ ! -d "$DECISIONS_DIR" ]; then
    # No decisions directory yet, start at 0001
    echo "0001"
    exit 0
fi

# Find the highest existing decision number
# Decision files are named NNNN_*.md (e.g., 0001_choose_framework.md)
highest=0

for file in "$DECISIONS_DIR"/[0-9][0-9][0-9][0-9]_*.md; do
    # Check if glob matched any files
    [ -e "$file" ] || continue

    # Extract the number from filename
    filename=$(basename "$file")
    number="${filename%%_*}"

    # Remove leading zeros for arithmetic comparison
    number_int=$((10#$number))

    if [ "$number_int" -gt "$highest" ]; then
        highest=$number_int
    fi
done

# Calculate next number and zero-pad to 4 digits
next=$((highest + 1))
printf "%04d\n" "$next"

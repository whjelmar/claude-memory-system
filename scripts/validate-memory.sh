#!/bin/bash
# validate-memory.sh
# Validates the integrity of the memory system structure
#
# Usage: ./validate-memory.sh [project-dir]
#   project-dir: Optional path to project root (default: current directory)
#
# Checks performed:
#   - Required directories exist
#   - Required files exist (ARCHITECTURE.md, USAGE.md, current_context.md)
#   - Decision numbers are sequential (warns if gaps)
#   - No empty template files (files still containing [DATE] or [NAME] placeholders)
#
# Exit codes: 0 if valid, 1 if issues found

set -e

# Get project directory (default to current)
PROJECT_DIR="${1:-.}"

# Resolve to absolute path
if command -v realpath &> /dev/null; then
    PROJECT_DIR=$(realpath "$PROJECT_DIR")
else
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
fi

MEMORY_DIR="$PROJECT_DIR/.claude/memory"
PLANS_DIR="$PROJECT_DIR/.claude/plans"

echo "Validating memory system..."
echo "Project directory: $PROJECT_DIR"
echo ""

# Track issues
errors=0
warnings=0

# Helper functions
error() {
    echo "[ERROR] $1"
    ((errors++)) || true
}

warn() {
    echo "[WARN]  $1"
    ((warnings++)) || true
}

ok() {
    echo "[OK]    $1"
}

echo "=== Directory Structure ==="

# Check required directories
required_dirs=(
    ".claude/memory"
    ".claude/memory/sessions"
    ".claude/memory/decisions"
    ".claude/memory/knowledge"
    ".claude/plans"
)

for dir in "${required_dirs[@]}"; do
    full_path="$PROJECT_DIR/$dir"
    if [ -d "$full_path" ]; then
        ok "$dir exists"
    else
        error "$dir does not exist"
    fi
done

echo ""
echo "=== Required Files ==="

# Check required files
required_files=(
    ".claude/memory/ARCHITECTURE.md"
    ".claude/memory/USAGE.md"
    ".claude/memory/current_context.md"
)

for file in "${required_files[@]}"; do
    full_path="$PROJECT_DIR/$file"
    if [ -f "$full_path" ]; then
        ok "$file exists"
    else
        error "$file does not exist"
    fi
done

echo ""
echo "=== Template Placeholders ==="

# Check for unfilled template placeholders
placeholder_patterns='\[DATE\]|\[NAME\]|\[Brief description\]|\[Current focus area\]|\[Immediate goals\]|\[Key variables\]|\[What issue\]'

files_to_check=(
    ".claude/memory/current_context.md"
    ".claude/plans/active_plan.md"
    ".claude/plans/findings.md"
    ".claude/plans/progress.md"
)

for file in "${files_to_check[@]}"; do
    full_path="$PROJECT_DIR/$file"
    if [ -f "$full_path" ]; then
        if grep -qE "$placeholder_patterns" "$full_path" 2>/dev/null; then
            warn "$file contains unfilled template placeholders"
        else
            ok "$file has no template placeholders"
        fi
    fi
done

echo ""
echo "=== Decision Sequence ==="

# Check decision numbers for gaps
DECISIONS_DIR="$PROJECT_DIR/.claude/memory/decisions"

if [ -d "$DECISIONS_DIR" ]; then
    # Collect decision numbers
    decision_numbers=()

    for file in "$DECISIONS_DIR"/[0-9][0-9][0-9][0-9]_*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")
        number="${filename%%_*}"
        number_int=$((10#$number))
        decision_numbers+=($number_int)
    done

    # Sort numbers
    IFS=$'\n' sorted_numbers=($(sort -n <<<"${decision_numbers[*]}")); unset IFS

    if [ ${#sorted_numbers[@]} -eq 0 ]; then
        ok "No decisions found (this is fine for new projects)"
    else
        # Check for gaps
        expected=1
        gaps_found=false
        for num in "${sorted_numbers[@]}"; do
            if [ "$num" -ne "$expected" ]; then
                warn "Gap in decision sequence: expected $expected, found $num"
                gaps_found=true
            fi
            expected=$((num + 1))
        done

        if [ "$gaps_found" = false ]; then
            ok "Decision numbers are sequential (1-${sorted_numbers[-1]})"
        fi

        echo "    Total decisions: ${#sorted_numbers[@]}"
    fi
else
    error "Decisions directory does not exist"
fi

echo ""
echo "=== Empty Files Check ==="

# Check for completely empty files (0 bytes)
find_empty_files() {
    local dir="$1"
    local pattern="$2"

    if [ -d "$dir" ]; then
        while IFS= read -r -d '' file; do
            if [ ! -s "$file" ]; then
                warn "Empty file: ${file#$PROJECT_DIR/}"
            fi
        done < <(find "$dir" -name "$pattern" -type f -print0 2>/dev/null)
    fi
}

find_empty_files "$MEMORY_DIR" "*.md"
find_empty_files "$PLANS_DIR" "*.md"

# If no warnings about empty files, report OK
if [ $warnings -eq 0 ] || ! find "$MEMORY_DIR" "$PLANS_DIR" -name "*.md" -type f -empty 2>/dev/null | grep -q .; then
    ok "No empty markdown files found"
fi

echo ""
echo "==============================="
echo "=== Validation Summary ==="
echo "==============================="
echo "Errors:   $errors"
echo "Warnings: $warnings"

if [ $errors -gt 0 ]; then
    echo ""
    echo "Status: INVALID - Fix errors before using memory system"
    exit 1
elif [ $warnings -gt 0 ]; then
    echo ""
    echo "Status: VALID with warnings - Consider addressing warnings"
    exit 0
else
    echo ""
    echo "Status: VALID - Memory system is properly configured"
    exit 0
fi

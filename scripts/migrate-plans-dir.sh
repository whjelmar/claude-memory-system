#!/bin/bash
# migrate-plans-dir.sh
# Migrates .claude/plan (singular) to .claude/plans (plural) for standardization
#
# Usage: ./migrate-plans-dir.sh [options] [directory]
#   directory: Directory to scan (default: current directory)
#
# Options:
#   --recursive, -r    Scan subdirectories for projects with .claude/plan
#   --dry-run, -n      Show what would be done without making changes
#   --force, -f        Overwrite existing files in .claude/plans (default: merge)
#   --remove-old       Remove .claude/plan after successful migration
#   --help, -h         Show this help message
#
# Exit codes:
#   0 - Success (or nothing to migrate)
#   1 - Error during migration
#   2 - Invalid arguments

set -e

# Colors for output (if terminal supports it)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Default options
RECURSIVE=false
DRY_RUN=false
FORCE=false
REMOVE_OLD=false
TARGET_DIR="."

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --recursive|-r)
            RECURSIVE=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --remove-old)
            REMOVE_OLD=true
            shift
            ;;
        --help|-h)
            head -n 17 "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 2
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Resolve target directory to absolute path
if command -v realpath &> /dev/null; then
    TARGET_DIR=$(realpath "$TARGET_DIR")
else
    TARGET_DIR=$(cd "$TARGET_DIR" && pwd)
fi

# Counters
migrated=0
skipped=0
errors=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC}   $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1"
}

# Migrate a single project's .claude/plan to .claude/plans
migrate_project() {
    local project_dir="$1"
    local plan_dir="$project_dir/.claude/plan"
    local plans_dir="$project_dir/.claude/plans"

    # Check if singular plan directory exists
    if [ ! -d "$plan_dir" ]; then
        return 0
    fi

    log_info "Found: $plan_dir"

    # Check if plans (plural) already exists
    if [ -d "$plans_dir" ]; then
        log_info "  Target exists: $plans_dir"

        # Migrate each file from plan to plans
        for file in "$plan_dir"/*; do
            if [ ! -e "$file" ]; then
                continue  # No files in directory
            fi

            local filename=$(basename "$file")
            local target_file="$plans_dir/$filename"

            if [ -e "$target_file" ]; then
                if [ "$FORCE" = true ]; then
                    if [ "$DRY_RUN" = true ]; then
                        log_dry "  Would overwrite: $filename"
                    else
                        cp "$file" "$target_file"
                        log_ok "  Overwrote: $filename"
                    fi
                else
                    # Compare files - if identical, skip; if different, warn
                    if diff -q "$file" "$target_file" > /dev/null 2>&1; then
                        log_info "  Identical (skipped): $filename"
                    else
                        log_warn "  Conflict (not overwritten): $filename"
                        log_warn "    Source: $file"
                        log_warn "    Target: $target_file"
                        log_warn "    Use --force to overwrite"
                        ((skipped++)) || true
                    fi
                fi
            else
                if [ "$DRY_RUN" = true ]; then
                    log_dry "  Would copy: $filename"
                else
                    cp "$file" "$target_file"
                    log_ok "  Copied: $filename"
                fi
            fi
        done
    else
        # No plans directory - simple rename/move
        if [ "$DRY_RUN" = true ]; then
            log_dry "  Would rename: plan -> plans"
        else
            mv "$plan_dir" "$plans_dir"
            log_ok "  Renamed: plan -> plans"
        fi
        ((migrated++)) || true
        return 0
    fi

    # Remove old directory if requested and migration successful
    if [ "$REMOVE_OLD" = true ]; then
        if [ "$DRY_RUN" = true ]; then
            log_dry "  Would remove: $plan_dir"
        else
            rm -rf "$plan_dir"
            log_ok "  Removed: $plan_dir"
        fi
    else
        log_info "  Old directory kept: $plan_dir (use --remove-old to delete)"
    fi

    ((migrated++)) || true
}

# Main execution
echo "=============================================="
echo "  Claude Memory System - Plans Directory Migration"
echo "=============================================="
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY-RUN MODE - No changes will be made${NC}"
    echo ""
fi

echo "Target directory: $TARGET_DIR"
echo "Options: recursive=$RECURSIVE, force=$FORCE, remove-old=$REMOVE_OLD"
echo ""

if [ "$RECURSIVE" = true ]; then
    # Find all .claude/plan directories
    log_info "Scanning for .claude/plan directories..."

    while IFS= read -r plan_dir; do
        if [ -n "$plan_dir" ]; then
            project_dir=$(dirname "$(dirname "$plan_dir")")
            migrate_project "$project_dir"
        fi
    done < <(find "$TARGET_DIR" -type d -name "plan" -path "*/.claude/plan" 2>/dev/null)
else
    # Single project mode
    migrate_project "$TARGET_DIR"
fi

echo ""
echo "=============================================="
echo "  Migration Summary"
echo "=============================================="
echo "  Migrated: $migrated"
echo "  Skipped (conflicts): $skipped"
echo "  Errors: $errors"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "This was a dry run. Use without --dry-run to apply changes."
fi

if [ "$skipped" -gt 0 ]; then
    echo "Some files were skipped due to conflicts."
    echo "Use --force to overwrite, or manually resolve differences."
fi

if [ "$errors" -gt 0 ]; then
    exit 1
fi

exit 0

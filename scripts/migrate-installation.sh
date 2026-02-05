#!/bin/bash
# migrate-installation.sh
# Comprehensive migration script for claude-memory-system installations
#
# Fixes:
#   1. Skills structure: Converts flat .md files to directory/SKILL.md format
#   2. Plans directory: Migrates .claude/plan (singular) to .claude/plans (plural)
#
# Usage: ./migrate-installation.sh [options] [directory]
#   directory: Project or home directory to migrate (default: current directory)
#
# Options:
#   --skills-only      Only migrate skills in ~/.claude/skills
#   --plans-only       Only migrate .claude/plan directories
#   --recursive, -r    Scan subdirectories for projects to migrate
#   --dry-run, -n      Show what would be done without making changes
#   --force, -f        Overwrite existing files without prompting
#   --help, -h         Show this help message
#
# Exit codes:
#   0 - Success
#   1 - Error during migration
#   2 - Invalid arguments

set -e

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# Default options
SKILLS_ONLY=false
PLANS_ONLY=false
RECURSIVE=false
DRY_RUN=false
FORCE=false
TARGET_DIR="."

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skills-only)
            SKILLS_ONLY=true
            shift
            ;;
        --plans-only)
            PLANS_ONLY=true
            shift
            ;;
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
        --help|-h)
            head -n 20 "$0" | tail -n +2 | sed 's/^# //' | sed 's/^#//'
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

# Resolve target directory
if command -v realpath &> /dev/null; then
    TARGET_DIR=$(realpath "$TARGET_DIR")
else
    TARGET_DIR=$(cd "$TARGET_DIR" && pwd)
fi

# Counters
skills_migrated=0
plans_migrated=0
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
    ((errors++)) || true
}

log_dry() {
    echo -e "${YELLOW}[DRY-RUN]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${BOLD}$1${NC}"
    echo "=============================================="
}

# =============================================================================
# SKILL MIGRATION
# =============================================================================

migrate_skills() {
    local skills_dir="$HOME/.claude/skills"

    if [ ! -d "$skills_dir" ]; then
        log_info "Skills directory not found: $skills_dir"
        return 0
    fi

    log_header "Migrating Skills Structure"
    log_info "Skills directory: $skills_dir"

    # Find flat .md files (old format)
    local found_old=false
    for skill_file in "$skills_dir"/*.md; do
        if [ -f "$skill_file" ]; then
            found_old=true
            local skill_name=$(basename "$skill_file" .md)

            # Skip if already has a directory version
            if [ -d "$skills_dir/$skill_name" ]; then
                log_info "Directory exists for $skill_name, removing old flat file"
                if [ "$DRY_RUN" = true ]; then
                    log_dry "Would remove: $skill_file"
                else
                    rm "$skill_file"
                    log_ok "Removed: $skill_file"
                fi
                continue
            fi

            log_info "Converting: $skill_name.md -> $skill_name/SKILL.md"

            if [ "$DRY_RUN" = true ]; then
                log_dry "Would create directory: $skills_dir/$skill_name/"
                log_dry "Would move content to: $skills_dir/$skill_name/SKILL.md"
                log_dry "Would add frontmatter if missing"
            else
                # Create directory
                mkdir -p "$skills_dir/$skill_name"

                # Read original content
                local content=$(cat "$skill_file")

                # Check if it already has frontmatter
                if [[ "$content" == ---* ]]; then
                    # Already has frontmatter, just move
                    mv "$skill_file" "$skills_dir/$skill_name/SKILL.md"
                else
                    # Extract description from content (look for ## Description section)
                    local description=""
                    if echo "$content" | grep -q "^## Description"; then
                        description=$(echo "$content" | sed -n '/^## Description/,/^##/p' | head -n 2 | tail -n 1 | sed 's/^[[:space:]]*//')
                    fi

                    # If no description found, try to get from first paragraph after title
                    if [ -z "$description" ]; then
                        description=$(echo "$content" | sed -n '3p' | head -c 100)
                    fi

                    # Default description if still empty
                    if [ -z "$description" ]; then
                        description="Memory system skill for $skill_name"
                    fi

                    # Create new file with frontmatter
                    {
                        echo "---"
                        echo "description: $description"
                        echo "---"
                        echo ""
                        # Remove old trigger phrases section (Claude Code doesn't use it)
                        echo "$content" | sed '/^## Trigger Phrases/,/^##/{ /^## Trigger Phrases/d; /^##/!d; }'
                    } > "$skills_dir/$skill_name/SKILL.md"

                    # Remove old file
                    rm "$skill_file"
                fi

                log_ok "Migrated: $skill_name"
                ((skills_migrated++)) || true
            fi
        fi
    done

    if [ "$found_old" = false ]; then
        log_info "No flat skill files found - skills already migrated or not installed"
    fi
}

# =============================================================================
# PLANS DIRECTORY MIGRATION
# =============================================================================

migrate_plans_dir() {
    local project_dir="$1"
    local plan_dir="$project_dir/.claude/plan"
    local plans_dir="$project_dir/.claude/plans"

    if [ ! -d "$plan_dir" ]; then
        return 0
    fi

    log_info "Found: $plan_dir"

    if [ -d "$plans_dir" ]; then
        log_info "  Target exists: $plans_dir"

        # Merge files
        for file in "$plan_dir"/*; do
            if [ ! -e "$file" ]; then
                continue
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
                    if diff -q "$file" "$target_file" > /dev/null 2>&1; then
                        log_info "  Identical (skipped): $filename"
                    else
                        log_warn "  Conflict: $filename (use --force to overwrite)"
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

        # Remove old directory
        if [ "$DRY_RUN" = true ]; then
            log_dry "  Would remove: $plan_dir"
        else
            rm -rf "$plan_dir"
            log_ok "  Removed: $plan_dir"
        fi
    else
        # Simple rename
        if [ "$DRY_RUN" = true ]; then
            log_dry "  Would rename: plan -> plans"
        else
            mv "$plan_dir" "$plans_dir"
            log_ok "  Renamed: plan -> plans"
        fi
    fi

    ((plans_migrated++)) || true
}

migrate_all_plans() {
    log_header "Migrating Plans Directories"

    if [ "$RECURSIVE" = true ]; then
        log_info "Scanning recursively for .claude/plan directories..."

        while IFS= read -r plan_dir; do
            if [ -n "$plan_dir" ]; then
                project_dir=$(dirname "$(dirname "$plan_dir")")
                migrate_plans_dir "$project_dir"
            fi
        done < <(find "$TARGET_DIR" -type d -name "plan" -path "*/.claude/plan" 2>/dev/null)
    else
        migrate_plans_dir "$TARGET_DIR"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

echo ""
echo -e "${BOLD}=============================================="
echo "  Claude Memory System - Installation Migration"
echo "==============================================${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}DRY-RUN MODE - No changes will be made${NC}"
    echo ""
fi

echo "Target: $TARGET_DIR"
echo "Options: recursive=$RECURSIVE, force=$FORCE"
echo ""

# Run migrations
if [ "$PLANS_ONLY" = false ]; then
    migrate_skills
fi

if [ "$SKILLS_ONLY" = false ]; then
    migrate_all_plans
fi

# Summary
log_header "Migration Summary"
echo "  Skills migrated: $skills_migrated"
echo "  Plans directories migrated: $plans_migrated"
echo "  Errors: $errors"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "This was a dry run. Run without --dry-run to apply changes."
    echo ""
fi

if [ "$errors" -gt 0 ]; then
    exit 1
fi

echo -e "${GREEN}Migration complete!${NC}"
echo ""

# Remind about reinstalling skills
if [ "$skills_migrated" -gt 0 ] || [ "$SKILLS_ONLY" = true ]; then
    echo "Note: If you have the claude-memory-system source, you can reinstall"
    echo "      updated skills with: ./setup.sh --install-skills"
    echo ""
fi

exit 0

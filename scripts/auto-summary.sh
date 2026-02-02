#!/bin/bash
# auto-summary.sh
# Analyzes git diff and generates a draft session summary
#
# Usage: ./auto-summary.sh [project-dir] [--output FILE] [--since TIMESTAMP]
#   project-dir: Optional path to project root (default: current directory)
#   --output: Write summary to file instead of stdout
#   --since: Generate diff since specific timestamp (ISO format or git ref)
#
# Behavior:
#   - Gets git diff since last commit or since session start
#   - Analyzes changed files (count, types, additions/deletions)
#   - Extracts commit messages
#   - Generates a draft session summary in markdown format
#
# Exit codes: 0 on success, 1 on error

set -e

# Parse arguments
PROJECT_DIR=""
OUTPUT_FILE=""
SINCE_REF=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --since)
            SINCE_REF="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./auto-summary.sh [project-dir] [--output FILE] [--since TIMESTAMP]"
            echo ""
            echo "Options:"
            echo "  project-dir    Path to project root (default: current directory)"
            echo "  --output FILE  Write summary to file instead of stdout"
            echo "  --since REF    Generate diff since specific timestamp or git ref"
            echo ""
            echo "Examples:"
            echo "  ./auto-summary.sh"
            echo "  ./auto-summary.sh /path/to/project --output session.md"
            echo "  ./auto-summary.sh --since 'HEAD~5'"
            echo "  ./auto-summary.sh --since '2024-01-15 10:00'"
            exit 0
            ;;
        *)
            if [ -z "$PROJECT_DIR" ]; then
                PROJECT_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Default project directory
PROJECT_DIR="${PROJECT_DIR:-.}"

# Resolve to absolute path
if command -v realpath &> /dev/null; then
    PROJECT_DIR=$(realpath "$PROJECT_DIR")
else
    PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)
fi

# Change to project directory
cd "$PROJECT_DIR"

# Check if git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository: $PROJECT_DIR" >&2
    exit 1
fi

# Get session start timestamp from current_context.md if exists
CONTEXT_FILE="$PROJECT_DIR/.claude/memory/current_context.md"
SESSION_START=""

if [ -f "$CONTEXT_FILE" ]; then
    # Try to extract "Last Updated" timestamp
    SESSION_START=$(grep -oP '(?<=\*\*Last Updated\*\*:\s).+' "$CONTEXT_FILE" 2>/dev/null || true)
fi

# Determine the reference point for diff
if [ -n "$SINCE_REF" ]; then
    # Use provided reference
    DIFF_REF="$SINCE_REF"
elif [ -n "$SESSION_START" ]; then
    # Try to find commits since session start
    # Convert timestamp to git-friendly format
    DIFF_REF=$(git rev-list -n1 --before="$SESSION_START" HEAD 2>/dev/null || echo "HEAD~10")
else
    # Default: show uncommitted changes or last 10 commits
    if git diff --quiet && git diff --cached --quiet; then
        DIFF_REF="HEAD~10"
    else
        DIFF_REF="HEAD"
    fi
fi

# Current date/time
CURRENT_DATETIME=$(date +"%Y-%m-%d %H:%M")
CURRENT_DATE=$(date +"%Y-%m-%d")
CURRENT_TIME=$(date +"%H-%M")

# Get git statistics
# Staged changes
STAGED_STATS=$(git diff --cached --stat 2>/dev/null || true)
STAGED_NUMSTAT=$(git diff --cached --numstat 2>/dev/null || true)

# Unstaged changes
UNSTAGED_STATS=$(git diff --stat 2>/dev/null || true)
UNSTAGED_NUMSTAT=$(git diff --cached --numstat 2>/dev/null || true)

# Combined diff statistics
COMBINED_NUMSTAT=$(git diff HEAD --numstat 2>/dev/null || true)

# Count files, insertions, deletions
if [ -n "$COMBINED_NUMSTAT" ]; then
    FILES_CHANGED=$(echo "$COMBINED_NUMSTAT" | wc -l | tr -d ' ')
    INSERTIONS=$(echo "$COMBINED_NUMSTAT" | awk '{s+=$1} END {print s+0}')
    DELETIONS=$(echo "$COMBINED_NUMSTAT" | awk '{s+=$2} END {print s+0}')
else
    FILES_CHANGED=0
    INSERTIONS=0
    DELETIONS=0
fi

# Get recent commits (since reference or last 10)
COMMIT_COUNT=0
COMMIT_MESSAGES=""

if [ "$DIFF_REF" != "HEAD" ]; then
    COMMITS=$(git log --oneline "$DIFF_REF"..HEAD 2>/dev/null || true)
    if [ -n "$COMMITS" ]; then
        COMMIT_COUNT=$(echo "$COMMITS" | wc -l | tr -d ' ')
        while IFS= read -r line; do
            msg=$(echo "$line" | cut -d' ' -f2-)
            COMMIT_MESSAGES="$COMMIT_MESSAGES- \"$msg\"\n"
        done <<< "$COMMITS"
    fi
fi

# Get list of changed files with status
CHANGED_FILES=""
MODIFIED_FILES=""
ADDED_FILES=""
DELETED_FILES=""

# Staged files
while IFS= read -r line; do
    [ -z "$line" ] && continue
    status="${line:0:1}"
    file="${line:3}"
    case "$status" in
        M) MODIFIED_FILES="$MODIFIED_FILES$file\n" ;;
        A) ADDED_FILES="$ADDED_FILES$file\n" ;;
        D) DELETED_FILES="$DELETED_FILES$file\n" ;;
        R) MODIFIED_FILES="$MODIFIED_FILES$file (renamed)\n" ;;
    esac
done < <(git diff --cached --name-status 2>/dev/null || true)

# Unstaged files
while IFS= read -r line; do
    [ -z "$line" ] && continue
    status="${line:0:1}"
    file="${line:3}"
    case "$status" in
        M)
            if [[ ! "$MODIFIED_FILES" =~ "$file" ]]; then
                MODIFIED_FILES="$MODIFIED_FILES$file\n"
            fi
            ;;
        D)
            if [[ ! "$DELETED_FILES" =~ "$file" ]]; then
                DELETED_FILES="$DELETED_FILES$file\n"
            fi
            ;;
    esac
done < <(git diff --name-status 2>/dev/null || true)

# Untracked files
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null || true)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    ADDED_FILES="$ADDED_FILES$file (untracked)\n"
done <<< "$UNTRACKED"

# Analyze file types for auto-summary
declare -A FILE_TYPES
while IFS= read -r file; do
    [ -z "$file" ] && continue
    ext="${file##*.}"
    if [ "$ext" != "$file" ]; then
        FILE_TYPES["$ext"]=$((${FILE_TYPES["$ext"]:-0} + 1))
    fi
done < <(git diff HEAD --name-only 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)

# Generate auto-summary based on file types and commit messages
AUTO_SUMMARY=""

# Categorize work based on file patterns
TEST_FILES=$(git diff HEAD --name-only 2>/dev/null | grep -E '(test|spec)\.' | wc -l || echo 0)
DOC_FILES=$(git diff HEAD --name-only 2>/dev/null | grep -E '\.(md|txt|rst)$' | wc -l || echo 0)
CONFIG_FILES=$(git diff HEAD --name-only 2>/dev/null | grep -E '\.(json|yaml|yml|toml|ini|conf)$' | wc -l || echo 0)
SRC_FILES=$((FILES_CHANGED - TEST_FILES - DOC_FILES - CONFIG_FILES))

if [ "$TEST_FILES" -gt 0 ] && [ "$SRC_FILES" -gt 0 ]; then
    AUTO_SUMMARY="Implementation work with corresponding tests."
elif [ "$TEST_FILES" -gt "$SRC_FILES" ]; then
    AUTO_SUMMARY="Testing and test coverage improvements."
elif [ "$DOC_FILES" -gt "$SRC_FILES" ]; then
    AUTO_SUMMARY="Documentation updates."
elif [ "$CONFIG_FILES" -gt "$SRC_FILES" ]; then
    AUTO_SUMMARY="Configuration and setup changes."
elif [ "$SRC_FILES" -gt 0 ]; then
    AUTO_SUMMARY="Source code implementation."
fi

# Add context from commit messages
if [ -n "$COMMIT_MESSAGES" ]; then
    AUTO_SUMMARY="$AUTO_SUMMARY Based on commits: work includes changes to the codebase."
fi

# Build the markdown output
build_changed_files_list() {
    local result=""

    if [ -n "$MODIFIED_FILES" ]; then
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            result="$result- \`$f\` (modified)\n"
        done < <(echo -e "$MODIFIED_FILES")
    fi

    if [ -n "$ADDED_FILES" ]; then
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            if [[ "$f" == *"(untracked)"* ]]; then
                result="$result- \`${f% (untracked)}\` (new, untracked)\n"
            else
                result="$result- \`$f\` (added)\n"
            fi
        done < <(echo -e "$ADDED_FILES")
    fi

    if [ -n "$DELETED_FILES" ]; then
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            result="$result- \`$f\` (deleted)\n"
        done < <(echo -e "$DELETED_FILES")
    fi

    if [ -z "$result" ]; then
        result="- No changes detected\n"
    fi

    echo -e "$result"
}

CHANGED_FILES_LIST=$(build_changed_files_list)

# Build commit messages section
COMMIT_SECTION=""
if [ -n "$COMMIT_MESSAGES" ]; then
    COMMIT_SECTION=$(echo -e "$COMMIT_MESSAGES")
else
    COMMIT_SECTION="- No commits in this session yet"
fi

# Generate the summary
SUMMARY="# Session Summary: $CURRENT_DATETIME

## Git Activity
- Files changed: $FILES_CHANGED
- Insertions: +$INSERTIONS
- Deletions: -$DELETIONS
- Commits: $COMMIT_COUNT

### Changed Files
$CHANGED_FILES_LIST
### Commit Messages
$COMMIT_SECTION

## Draft Summary
$AUTO_SUMMARY

## Work Completed (fill in)
- [ ] Item 1
- [ ] Item 2

## Decisions Made
- [ ] None / Add decisions here

## Next Steps
- [ ] Continue with...

---
*Generated by auto-summary.sh at $CURRENT_DATETIME*
"

# Output the summary
if [ -n "$OUTPUT_FILE" ]; then
    # Ensure sessions directory exists
    SESSIONS_DIR="$PROJECT_DIR/.claude/memory/sessions"
    if [ ! -d "$SESSIONS_DIR" ]; then
        mkdir -p "$SESSIONS_DIR"
    fi

    # If output file is just a filename, put it in sessions directory
    if [[ "$OUTPUT_FILE" != /* ]] && [[ "$OUTPUT_FILE" != ./* ]]; then
        OUTPUT_FILE="$SESSIONS_DIR/$OUTPUT_FILE"
    fi

    echo "$SUMMARY" > "$OUTPUT_FILE"
    echo "Session summary written to: $OUTPUT_FILE"
else
    echo "$SUMMARY"
fi

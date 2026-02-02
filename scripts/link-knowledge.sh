#!/bin/bash
# link-knowledge.sh
# Scans knowledge files and suggests/creates cross-references
#
# Usage: ./link-knowledge.sh [project-dir] [--auto-insert] [--dry-run]
#   project-dir: Optional path to project root (default: current directory)
#   --auto-insert: Automatically insert suggested links
#   --dry-run: Show what would be changed without making changes
#
# Behavior:
#   - Scans all files in .claude/memory/knowledge/
#   - Extracts topic names and key terms from each file
#   - Finds references to other topics within file content
#   - Suggests links like [[topic-name]] or [Topic](./topic-name.md)
#   - Optionally auto-inserts links
#
# Exit codes: 0 on success, 1 on error

set -e

# Parse arguments
PROJECT_DIR=""
AUTO_INSERT=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-insert)
            AUTO_INSERT=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./link-knowledge.sh [project-dir] [--auto-insert] [--dry-run]"
            echo ""
            echo "Options:"
            echo "  project-dir     Path to project root (default: current directory)"
            echo "  --auto-insert   Automatically insert suggested links"
            echo "  --dry-run       Show what would be changed without making changes"
            echo ""
            echo "Examples:"
            echo "  ./link-knowledge.sh"
            echo "  ./link-knowledge.sh --dry-run"
            echo "  ./link-knowledge.sh /path/to/project --auto-insert"
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

KNOWLEDGE_DIR="$PROJECT_DIR/.claude/memory/knowledge"

echo "=== Knowledge Base Linker ==="
echo "Knowledge directory: $KNOWLEDGE_DIR"
echo ""

# Check if knowledge directory exists
if [ ! -d "$KNOWLEDGE_DIR" ]; then
    echo "Error: Knowledge directory does not exist: $KNOWLEDGE_DIR" >&2
    exit 1
fi

# Build a list of all topics and their filenames
declare -A TOPICS
declare -A TOPIC_FILES
declare -A TOPIC_TERMS

# First pass: collect all topic names and key terms
for file in "$KNOWLEDGE_DIR"/*.md; do
    [ -e "$file" ] || continue
    filename=$(basename "$file")

    # Skip INDEX.md and other special files
    if [[ "$filename" == "INDEX.md" ]] || [[ "$filename" == "index.md" ]] || [[ "$filename" == ".gitkeep" ]]; then
        continue
    fi

    # Get the topic name from first line
    topic=$(head -n 1 "$file" | sed 's/^#* *//')
    if [ -z "$topic" ]; then
        topic="${filename%.md}"
    fi

    # Slugify the topic for matching
    slug=$(echo "$topic" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

    TOPICS["$slug"]="$topic"
    TOPIC_FILES["$slug"]="$filename"

    # Extract potential key terms (headers, bold text, first occurrence of capitalized terms)
    terms=$(grep -oE '(\*\*[^*]+\*\*|^## .+|^### .+)' "$file" 2>/dev/null | \
            sed 's/\*\*//g' | sed 's/^##* //' | tr '\n' '|' || true)
    TOPIC_TERMS["$slug"]="$terms"
done

echo "Found ${#TOPICS[@]} knowledge topics:"
for slug in "${!TOPICS[@]}"; do
    echo "  - ${TOPICS[$slug]} (${TOPIC_FILES[$slug]})"
done
echo ""

# Track suggestions
declare -A SUGGESTIONS
total_suggestions=0

# Second pass: scan each file for references to other topics
echo "Scanning for cross-references..."
echo ""

for file in "$KNOWLEDGE_DIR"/*.md; do
    [ -e "$file" ] || continue
    filename=$(basename "$file")

    # Skip INDEX.md and other special files
    if [[ "$filename" == "INDEX.md" ]] || [[ "$filename" == "index.md" ]] || [[ "$filename" == ".gitkeep" ]]; then
        continue
    fi

    current_topic_slug=$(echo "${filename%.md}" | tr '[:upper:]' '[:lower:]')
    file_content=$(cat "$file")
    file_suggestions=()

    for slug in "${!TOPICS[@]}"; do
        # Skip self-references
        if [[ "$slug" == "$current_topic_slug" ]]; then
            continue
        fi

        topic="${TOPICS[$slug]}"
        target_file="${TOPIC_FILES[$slug]}"

        # Check if topic is mentioned but not already linked
        # Look for the topic name (case-insensitive)
        topic_pattern=$(echo "$topic" | sed 's/[^a-zA-Z0-9]/./g')

        # Check if already linked to this topic
        if echo "$file_content" | grep -qiE "\[.*\]\(\.?/?$target_file\)|\[\[$slug\]\]"; then
            continue
        fi

        # Check if topic is mentioned
        if echo "$file_content" | grep -qiE "\b$topic_pattern\b"; then
            # Found a mention that's not linked
            ((total_suggestions++)) || true
            file_suggestions+=("  - Link '$topic' -> [${topic}](./${target_file})")

            # Prepare for auto-insert
            if $AUTO_INSERT && ! $DRY_RUN; then
                # Replace first occurrence of topic with link
                # Use perl for more reliable replacement
                if command -v perl &> /dev/null; then
                    perl -i -pe "s/(?<![(\[\w])(\b${topic}\b)(?![)\]\w])/[\$1](.\/${target_file})/i" "$file" 2>/dev/null || true
                fi
            fi
        fi

        # Also check for slug-based mentions (e.g., "auth-patterns" -> "Auth Patterns")
        if [[ "$slug" != "$topic_pattern" ]]; then
            slug_readable=$(echo "$slug" | sed 's/-/ /g')
            if echo "$file_content" | grep -qiE "\b$slug_readable\b"; then
                if ! echo "$file_content" | grep -qiE "\[.*\]\(\.?/?$target_file\)"; then
                    ((total_suggestions++)) || true
                    file_suggestions+=("  - Link '$slug_readable' -> [${topic}](./${target_file})")
                fi
            fi
        fi
    done

    if [ ${#file_suggestions[@]} -gt 0 ]; then
        echo "### $filename"
        printf '%s\n' "${file_suggestions[@]}"
        echo ""
    fi
done

# Generate link suggestions report
echo "=== Summary ==="
echo "Total cross-reference suggestions: $total_suggestions"
echo ""

if [ $total_suggestions -eq 0 ]; then
    echo "No cross-references needed - knowledge base is well-linked!"
else
    if $DRY_RUN; then
        echo "[DRY RUN] No changes were made."
    elif $AUTO_INSERT; then
        echo "Links have been auto-inserted where possible."
        echo "Review the changes with 'git diff'"
    else
        echo "To auto-insert links, run with --auto-insert"
        echo "To preview changes, run with --dry-run"
    fi
fi

echo ""
echo "Link format used: [Topic Name](./topic-name.md)"
echo ""

# Output related topics for each file as JSON-like structure (useful for MCP integration)
if [ -n "$SHOW_JSON" ]; then
    echo "=== Related Topics JSON ==="
    for file in "$KNOWLEDGE_DIR"/*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")

        if [[ "$filename" == "INDEX.md" ]] || [[ "$filename" == "index.md" ]]; then
            continue
        fi

        current_slug="${filename%.md}"
        related=()

        for slug in "${!TOPICS[@]}"; do
            if [[ "$slug" != "$current_slug" ]]; then
                related+=("\"${TOPICS[$slug]}\"")
            fi
        done

        echo "{ \"file\": \"$filename\", \"related\": [${related[*]}] }"
    done
fi

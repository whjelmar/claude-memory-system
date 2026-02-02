#!/bin/bash
# memory-analytics.sh
# Generates analytics about memory system usage
#
# Usage: ./memory-analytics.sh [project-dir] [--json]
#   project-dir: Optional path to project root (default: current directory)
#   --json: Output in JSON format instead of human-readable
#
# Behavior:
#   - Counts total sessions, decisions, knowledge files
#   - Calculates sessions per week/month trend
#   - Identifies most active days/times
#   - Breaks down decision categories
#   - Assesses knowledge base coverage
#
# Exit codes: 0 on success, 1 on error

set -e

# Parse arguments
PROJECT_DIR=""
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./memory-analytics.sh [project-dir] [--json]"
            echo ""
            echo "Options:"
            echo "  project-dir  Path to project root (default: current directory)"
            echo "  --json       Output in JSON format"
            echo ""
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

MEMORY_DIR="$PROJECT_DIR/.claude/memory"
SESSIONS_DIR="$MEMORY_DIR/sessions"
DECISIONS_DIR="$MEMORY_DIR/decisions"
KNOWLEDGE_DIR="$MEMORY_DIR/knowledge"
PLANS_DIR="$PROJECT_DIR/.claude/plans"

# Initialize counters
total_sessions=0
total_decisions=0
total_knowledge=0
active_plan=""
sessions_this_week=0
sessions_last_week=0
decisions_this_week=0
decisions_last_week=0

# Date calculations
current_date=$(date +%Y-%m-%d)
current_timestamp=$(date +%s)

# Calculate week boundaries
week_start=$((current_timestamp - ($(date +%u) - 1) * 86400))
week_start_date=$(date -d "@$week_start" +%Y-%m-%d 2>/dev/null || date -r "$week_start" +%Y-%m-%d)
last_week_start=$((week_start - 7 * 86400))
last_week_start_date=$(date -d "@$last_week_start" +%Y-%m-%d 2>/dev/null || date -r "$last_week_start" +%Y-%m-%d)

# Count sessions
declare -A session_by_date
declare -A session_by_hour

if [ -d "$SESSIONS_DIR" ]; then
    for file in "$SESSIONS_DIR"/*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")

        # Skip non-summary files
        [[ "$filename" == *.md ]] || continue

        ((total_sessions++)) || true

        # Extract date from filename (YYYY-MM-DD format)
        if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            file_date="${BASH_REMATCH[1]}"
            session_by_date["$file_date"]=$((${session_by_date["$file_date"]:-0} + 1))

            # Check if in current week
            if [[ "$file_date" > "$week_start_date" ]] || [[ "$file_date" == "$week_start_date" ]]; then
                ((sessions_this_week++)) || true
            elif [[ "$file_date" > "$last_week_start_date" ]] || [[ "$file_date" == "$last_week_start_date" ]]; then
                ((sessions_last_week++)) || true
            fi
        fi

        # Extract hour from filename (HH-MM format)
        if [[ "$filename" =~ _([0-9]{2})-[0-9]{2}_ ]]; then
            file_hour="${BASH_REMATCH[1]}"
            session_by_hour["$file_hour"]=$((${session_by_hour["$file_hour"]:-0} + 1))
        fi
    done
fi

# Count decisions
declare -A decision_categories

if [ -d "$DECISIONS_DIR" ]; then
    for file in "$DECISIONS_DIR"/*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")

        # Skip index files
        [[ "$filename" == "index.md" ]] || [[ "$filename" == "INDEX.md" ]] && continue

        ((total_decisions++)) || true

        # Extract date from file content or modification time
        if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            file_date="${BASH_REMATCH[1]}"

            if [[ "$file_date" > "$week_start_date" ]] || [[ "$file_date" == "$week_start_date" ]]; then
                ((decisions_this_week++)) || true
            elif [[ "$file_date" > "$last_week_start_date" ]] || [[ "$file_date" == "$last_week_start_date" ]]; then
                ((decisions_last_week++)) || true
            fi
        fi

        # Try to extract category from file
        category=$(grep -m1 -oP '(?<=\*\*Category\*\*:\s).+' "$file" 2>/dev/null || \
                   grep -m1 -oP '(?<=Category:\s).+' "$file" 2>/dev/null || \
                   echo "Uncategorized")
        category=$(echo "$category" | tr -d '\r' | xargs)
        decision_categories["$category"]=$((${decision_categories["$category"]:-0} + 1))
    done
fi

# Count and analyze knowledge files
declare -A knowledge_topics

if [ -d "$KNOWLEDGE_DIR" ]; then
    for file in "$KNOWLEDGE_DIR"/*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")

        # Skip index files
        [[ "$filename" == "index.md" ]] || [[ "$filename" == "INDEX.md" ]] && continue

        ((total_knowledge++)) || true

        # Get topic name from first line
        topic=$(head -n 1 "$file" | sed 's/^#* *//')
        if [ -z "$topic" ]; then
            topic="${filename%.md}"
        fi

        # Get last modified date
        if [[ "$OSTYPE" == "darwin"* ]]; then
            modified=$(stat -f "%Sm" -t "%Y-%m-%d" "$file")
        else
            modified=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
        fi

        # Calculate age
        if [ "$modified" != "unknown" ]; then
            mod_ts=$(date -d "$modified" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$modified" +%s 2>/dev/null || echo 0)
            age_days=$(( (current_timestamp - mod_ts) / 86400 ))
            if [ $age_days -lt 7 ]; then
                age_status="Fresh"
            elif [ $age_days -lt 30 ]; then
                age_status="Recent"
            else
                age_status="Stale"
            fi
        else
            age_status="Unknown"
            age_days=0
        fi

        knowledge_topics["$topic"]="$modified|$age_status|$age_days"
    done
fi

# Check for active plan
if [ -f "$PLANS_DIR/active_plan.md" ]; then
    active_plan=$(head -n 1 "$PLANS_DIR/active_plan.md" | sed 's/^#* *//')
fi

# Find most active times
most_active_hour=""
max_hour_sessions=0
for hour in "${!session_by_hour[@]}"; do
    if [ "${session_by_hour[$hour]}" -gt "$max_hour_sessions" ]; then
        max_hour_sessions="${session_by_hour[$hour]}"
        most_active_hour="$hour"
    fi
done

# Find most active day
most_active_day=""
max_day_sessions=0
for day in "${!session_by_date[@]}"; do
    if [ "${session_by_date[$day]}" -gt "$max_day_sessions" ]; then
        max_day_sessions="${session_by_date[$day]}"
        most_active_day="$day"
    fi
done

# Calculate stale knowledge count
stale_knowledge=0
for topic in "${!knowledge_topics[@]}"; do
    IFS='|' read -r _ status _ <<< "${knowledge_topics[$topic]}"
    if [ "$status" == "Stale" ]; then
        ((stale_knowledge++)) || true
    fi
done

# Output results
if $JSON_OUTPUT; then
    # JSON output
    categories_json="{"
    first=true
    for cat in "${!decision_categories[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            categories_json+=","
        fi
        categories_json+="\"$cat\":${decision_categories[$cat]}"
    done
    categories_json+="}"

    knowledge_json="["
    first=true
    for topic in "${!knowledge_topics[@]}"; do
        IFS='|' read -r modified status age <<< "${knowledge_topics[$topic]}"
        if [ "$first" = true ]; then
            first=false
        else
            knowledge_json+=","
        fi
        knowledge_json+="{\"topic\":\"$topic\",\"lastUpdated\":\"$modified\",\"status\":\"$status\",\"ageDays\":$age}"
    done
    knowledge_json+="]"

    cat <<EOF
{
  "generatedAt": "$current_date",
  "totals": {
    "sessions": $total_sessions,
    "decisions": $total_decisions,
    "knowledgeTopics": $total_knowledge
  },
  "activity": {
    "sessionsThisWeek": $sessions_this_week,
    "sessionsLastWeek": $sessions_last_week,
    "decisionsThisWeek": $decisions_this_week,
    "decisionsLastWeek": $decisions_last_week
  },
  "patterns": {
    "mostActiveHour": "${most_active_hour:-none}",
    "mostActiveDay": "${most_active_day:-none}"
  },
  "activePlan": "${active_plan:-none}",
  "decisionCategories": $categories_json,
  "knowledgeTopics": $knowledge_json,
  "recommendations": {
    "staleKnowledge": $stale_knowledge
  }
}
EOF
else
    # Human-readable output
    echo "=== Memory System Analytics ==="
    echo "Generated: $current_date"
    echo ""
    echo "## Overview"
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "| Total Sessions | $total_sessions |"
    echo "| Total Decisions | $total_decisions |"
    echo "| Knowledge Topics | $total_knowledge |"
    echo "| Active Plan | ${active_plan:-None} |"
    echo ""
    echo "## Activity Trends"
    echo "| Period | Sessions | Decisions |"
    echo "|--------|----------|-----------|"
    echo "| This week | $sessions_this_week | $decisions_this_week |"
    echo "| Last week | $sessions_last_week | $decisions_last_week |"
    echo ""

    if [ -n "$most_active_hour" ]; then
        echo "## Usage Patterns"
        echo "- Most active hour: ${most_active_hour}:00 ($max_hour_sessions sessions)"
        if [ -n "$most_active_day" ]; then
            echo "- Most active day: $most_active_day ($max_day_sessions sessions)"
        fi
        echo ""
    fi

    if [ ${#decision_categories[@]} -gt 0 ]; then
        echo "## Decision Categories"
        for cat in "${!decision_categories[@]}"; do
            echo "- $cat: ${decision_categories[$cat]}"
        done
        echo ""
    fi

    if [ ${#knowledge_topics[@]} -gt 0 ]; then
        echo "## Knowledge Base"
        echo "| Topic | Last Updated | Status |"
        echo "|-------|--------------|--------|"
        for topic in "${!knowledge_topics[@]}"; do
            IFS='|' read -r modified status _ <<< "${knowledge_topics[$topic]}"
            echo "| $topic | $modified | $status |"
        done
        echo ""
    fi

    echo "## Recommendations"
    if [ $stale_knowledge -gt 0 ]; then
        echo "- $stale_knowledge knowledge file(s) are stale (>30 days old) - consider updating"
    fi

    sessions_without_decisions=$((sessions_this_week + sessions_last_week))
    decisions_total=$((decisions_this_week + decisions_last_week))
    if [ $sessions_without_decisions -gt 3 ] && [ $decisions_total -eq 0 ]; then
        echo "- $sessions_without_decisions recent sessions without decisions - review if any decisions were made"
    fi

    if [ $total_knowledge -eq 0 ]; then
        echo "- No knowledge files yet - consider documenting key learnings"
    fi

    echo ""
fi

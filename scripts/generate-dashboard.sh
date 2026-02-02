#!/bin/bash
# generate-dashboard.sh
# Generates a markdown dashboard file with memory system analytics
#
# Usage: ./generate-dashboard.sh [project-dir] [--output FILE]
#   project-dir: Optional path to project root (default: current directory)
#   --output: Output file path (default: .claude/memory/DASHBOARD.md)
#
# Behavior:
#   - Gathers all memory system analytics
#   - Generates a comprehensive markdown dashboard
#   - Includes ASCII charts for trends
#   - Provides actionable recommendations
#
# Exit codes: 0 on success, 1 on error

set -e

# Parse arguments
PROJECT_DIR=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./generate-dashboard.sh [project-dir] [--output FILE]"
            echo ""
            echo "Options:"
            echo "  project-dir    Path to project root (default: current directory)"
            echo "  --output FILE  Output file path (default: .claude/memory/DASHBOARD.md)"
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

# Default output file
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="$MEMORY_DIR/DASHBOARD.md"
fi

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Current date
current_date=$(date +"%Y-%m-%d")
current_datetime=$(date +"%Y-%m-%d %H:%M")

# Initialize counters
total_sessions=0
total_decisions=0
total_knowledge=0
active_plan=""
sessions_this_week=0
sessions_last_week=0
sessions_this_month=0
decisions_this_week=0
decisions_last_week=0

# Date calculations
current_timestamp=$(date +%s)
day_of_week=$(date +%u)
week_start=$((current_timestamp - (day_of_week - 1) * 86400))
last_week_start=$((week_start - 7 * 86400))
month_start=$(date +%Y-%m-01)

# Arrays for weekly data (for chart)
declare -a weekly_sessions
for i in {0..7}; do
    weekly_sessions[$i]=0
done

# Count sessions
declare -A session_by_weekday
if [ -d "$SESSIONS_DIR" ]; then
    for file in "$SESSIONS_DIR"/*.md; do
        [ -e "$file" ] || continue
        ((total_sessions++)) || true

        filename=$(basename "$file")
        if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            file_date="${BASH_REMATCH[1]}"

            # This week
            if [[ "$file_date" > "$(date -d "@$week_start" +%Y-%m-%d 2>/dev/null || date -r $week_start +%Y-%m-%d)" ]]; then
                ((sessions_this_week++)) || true

                # Track by weekday
                file_dow=$(date -d "$file_date" +%u 2>/dev/null || date -j -f "%Y-%m-%d" "$file_date" +%u 2>/dev/null || echo 1)
                weekly_sessions[$file_dow]=$((${weekly_sessions[$file_dow]:-0} + 1))
            fi

            # Last week
            week_start_date=$(date -d "@$week_start" +%Y-%m-%d 2>/dev/null || date -r $week_start +%Y-%m-%d)
            last_week_start_date=$(date -d "@$last_week_start" +%Y-%m-%d 2>/dev/null || date -r $last_week_start +%Y-%m-%d)
            if [[ "$file_date" < "$week_start_date" ]] && [[ "$file_date" > "$last_week_start_date" ]]; then
                ((sessions_last_week++)) || true
            fi

            # This month
            if [[ "$file_date" > "$month_start" ]] || [[ "$file_date" == "$month_start" ]]; then
                ((sessions_this_month++)) || true
            fi
        fi
    done
fi

# Count decisions
if [ -d "$DECISIONS_DIR" ]; then
    for file in "$DECISIONS_DIR"/*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")
        [[ "$filename" == "index.md" ]] || [[ "$filename" == "INDEX.md" ]] && continue
        ((total_decisions++)) || true

        if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
            file_date="${BASH_REMATCH[1]}"
            week_start_date=$(date -d "@$week_start" +%Y-%m-%d 2>/dev/null || date -r $week_start +%Y-%m-%d)
            last_week_start_date=$(date -d "@$last_week_start" +%Y-%m-%d 2>/dev/null || date -r $last_week_start +%Y-%m-%d)

            if [[ "$file_date" > "$week_start_date" ]]; then
                ((decisions_this_week++)) || true
            elif [[ "$file_date" > "$last_week_start_date" ]]; then
                ((decisions_last_week++)) || true
            fi
        fi
    done
fi

# Knowledge analysis
declare -A knowledge_info
stale_count=0
fresh_count=0
recent_count=0

if [ -d "$KNOWLEDGE_DIR" ]; then
    for file in "$KNOWLEDGE_DIR"/*.md; do
        [ -e "$file" ] || continue
        filename=$(basename "$file")
        [[ "$filename" == "index.md" ]] || [[ "$filename" == "INDEX.md" ]] && continue
        ((total_knowledge++)) || true

        # Get topic name
        topic=$(head -n 1 "$file" | sed 's/^#* *//')
        [ -z "$topic" ] && topic="${filename%.md}"

        # Get modification date and age
        if [[ "$OSTYPE" == "darwin"* ]]; then
            modified=$(stat -f "%Sm" -t "%Y-%m-%d" "$file")
            mod_ts=$(stat -f "%m" "$file")
        else
            modified=$(stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1)
            mod_ts=$(stat -c "%Y" "$file" 2>/dev/null || echo 0)
        fi

        age_days=$(( (current_timestamp - mod_ts) / 86400 ))

        if [ $age_days -lt 7 ]; then
            status="Fresh"
            ((fresh_count++)) || true
        elif [ $age_days -lt 30 ]; then
            status="Recent"
            ((recent_count++)) || true
        else
            status="Stale"
            ((stale_count++)) || true
        fi

        # Calculate relative time
        if [ $age_days -eq 0 ]; then
            relative="today"
        elif [ $age_days -eq 1 ]; then
            relative="yesterday"
        elif [ $age_days -lt 7 ]; then
            relative="$age_days days ago"
        elif [ $age_days -lt 30 ]; then
            weeks=$((age_days / 7))
            relative="$weeks week(s) ago"
        else
            months=$((age_days / 30))
            relative="$months month(s) ago"
        fi

        knowledge_info["$topic"]="$modified|$status|$relative"
    done
fi

# Check for active plan
if [ -f "$PLANS_DIR/active_plan.md" ]; then
    active_plan=$(head -n 1 "$PLANS_DIR/active_plan.md" | sed 's/^#* *//')
fi

# Generate ASCII chart for weekly activity
generate_bar() {
    local count=$1
    local max=$2
    local width=20

    if [ "$max" -eq 0 ]; then
        printf "%${width}s" " "
        return
    fi

    local filled=$((count * width / max))
    local empty=$((width - filled))

    printf "%s%s" "$(printf '█%.0s' $(seq 1 $filled 2>/dev/null || echo ""))" "$(printf '░%.0s' $(seq 1 $empty 2>/dev/null || echo ""))"
}

# Find max for scaling
max_sessions=1
for i in {1..7}; do
    if [ "${weekly_sessions[$i]:-0}" -gt "$max_sessions" ]; then
        max_sessions="${weekly_sessions[$i]}"
    fi
done

# Day names
day_names=("" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")

# Build the dashboard markdown
dashboard="# Memory System Dashboard

**Generated:** $current_datetime

---

## Overview

| Metric | Value |
|--------|-------|
| Total Sessions | $total_sessions |
| Total Decisions | $total_decisions |
| Knowledge Topics | $total_knowledge |
| Active Plan | ${active_plan:-None} |

---

## Activity Trends

### Weekly Summary

| Period | Sessions | Decisions | Trend |
|--------|----------|-----------|-------|
| This week | $sessions_this_week | $decisions_this_week | $([ $sessions_this_week -gt $sessions_last_week ] && echo '↑' || ([ $sessions_this_week -lt $sessions_last_week ] && echo '↓' || echo '→')) |
| Last week | $sessions_last_week | $decisions_last_week | |
| This month | $sessions_this_month | - | |

### This Week's Activity

\`\`\`
"

# Add ASCII chart
for i in {1..7}; do
    count="${weekly_sessions[$i]:-0}"
    bar=""
    for ((j=0; j<count && j<20; j++)); do
        bar+="█"
    done
    for ((j=count; j<20; j++)); do
        bar+="░"
    done
    dashboard+="${day_names[$i]}: $bar $count
"
done

dashboard+="\`\`\`

---

## Knowledge Base Health

| Topic | Last Updated | Age | Status |
|-------|--------------|-----|--------|
"

# Add knowledge entries sorted by status (Stale first)
for topic in "${!knowledge_info[@]}"; do
    IFS='|' read -r modified status relative <<< "${knowledge_info[$topic]}"
    status_emoji=""
    case "$status" in
        "Fresh") status_emoji="✅" ;;
        "Recent") status_emoji="🟡" ;;
        "Stale") status_emoji="🔴" ;;
    esac
    dashboard+="| $topic | $modified | $relative | $status_emoji $status |
"
done

if [ ${#knowledge_info[@]} -eq 0 ]; then
    dashboard+="| *No knowledge files* | - | - | - |
"
fi

dashboard+="
### Health Summary
- Fresh (< 7 days): $fresh_count
- Recent (7-30 days): $recent_count
- Stale (> 30 days): $stale_count

---

## Recent Sessions

"

# List 5 most recent sessions
session_count=0
if [ -d "$SESSIONS_DIR" ]; then
    for file in $(ls -t "$SESSIONS_DIR"/*.md 2>/dev/null | head -5); do
        [ -e "$file" ] || continue
        filename=$(basename "$file")
        title=$(head -n 1 "$file" | sed 's/^#* *//')
        dashboard+="- \`$filename\`: $title
"
        ((session_count++)) || true
    done
fi

if [ $session_count -eq 0 ]; then
    dashboard+="*No sessions recorded yet*
"
fi

dashboard+="
---

## Recommendations

"

# Generate recommendations
recommendations=()

if [ $stale_count -gt 0 ]; then
    recommendations+=("📚 **Update stale knowledge**: $stale_count knowledge file(s) haven't been updated in over 30 days. Review and update them to keep information current.")
fi

if [ $total_sessions -gt 5 ] && [ $total_decisions -eq 0 ]; then
    recommendations+=("📝 **Document decisions**: You've had $total_sessions sessions but no decisions recorded. Consider documenting key decisions for future reference.")
fi

if [ $total_knowledge -eq 0 ]; then
    recommendations+=("💡 **Start knowledge base**: No knowledge files exist yet. Document key learnings, patterns, and project-specific information.")
fi

if [ $sessions_this_week -eq 0 ] && [ $sessions_last_week -gt 0 ]; then
    recommendations+=("⏰ **Resume sessions**: No sessions this week but $sessions_last_week last week. Don't forget to document your work!")
fi

if [ -z "$active_plan" ]; then
    recommendations+=("🎯 **Create a plan**: No active plan found. Consider creating one to track project goals and progress.")
fi

if [ ${#recommendations[@]} -eq 0 ]; then
    recommendations+=("✨ **Looking good!** Your memory system is well-maintained. Keep up the great documentation habits!")
fi

for rec in "${recommendations[@]}"; do
    dashboard+="- $rec
"
done

dashboard+="
---

## Quick Actions

- Run \`./scripts/auto-summary.sh\` to generate a session summary
- Run \`./scripts/link-knowledge.sh\` to find cross-reference opportunities
- Run \`./scripts/memory-analytics.sh --json\` for programmatic access to metrics
- Run \`./scripts/prune-sessions.sh\` to clean up old session files

---

*Dashboard generated by \`generate-dashboard.sh\`*
"

# Write to file
echo "$dashboard" > "$OUTPUT_FILE"

echo "Dashboard generated: $OUTPUT_FILE"
echo ""
echo "Overview:"
echo "  Sessions: $total_sessions (This week: $sessions_this_week)"
echo "  Decisions: $total_decisions"
echo "  Knowledge: $total_knowledge (Stale: $stale_count)"

# generate-dashboard.ps1
# Generates a markdown dashboard file with memory system analytics
#
# Usage: .\generate-dashboard.ps1 [-ProjectDir <path>] [-Output <file>]
#   -ProjectDir: Optional path to project root (default: current directory)
#   -Output: Output file path (default: .claude/memory/DASHBOARD.md)
#
# Behavior:
#   - Gathers all memory system analytics
#   - Generates a comprehensive markdown dashboard
#   - Includes ASCII charts for trends
#   - Provides actionable recommendations
#
# Exit codes: 0 on success, 1 on error

param(
    [string]$ProjectDir = ".",
    [string]$Output = ""
)

# Resolve to absolute path
try {
    $ProjectDir = Resolve-Path $ProjectDir -ErrorAction Stop
} catch {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

$MemoryDir = Join-Path $ProjectDir ".claude\memory"
$SessionsDir = Join-Path $MemoryDir "sessions"
$DecisionsDir = Join-Path $MemoryDir "decisions"
$KnowledgeDir = Join-Path $MemoryDir "knowledge"
$PlansDir = Join-Path $ProjectDir ".claude\plans"

# Default output file
if (-not $Output) {
    $Output = Join-Path $MemoryDir "DASHBOARD.md"
}

# Ensure memory directory exists
if (-not (Test-Path $MemoryDir)) {
    New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null
}

# Current date
$currentDate = Get-Date
$currentDateTime = $currentDate.ToString("yyyy-MM-dd HH:mm")

# Initialize counters
$totalSessions = 0
$totalDecisions = 0
$totalKnowledge = 0
$activePlan = ""
$sessionsThisWeek = 0
$sessionsLastWeek = 0
$sessionsThisMonth = 0
$decisionsThisWeek = 0
$decisionsLastWeek = 0

# Date calculations
$weekStart = $currentDate.AddDays(-($currentDate.DayOfWeek.value__ - 1))
if ($currentDate.DayOfWeek -eq "Sunday") {
    $weekStart = $currentDate.AddDays(-6)
}
$lastWeekStart = $weekStart.AddDays(-7)
$monthStart = Get-Date -Day 1

# Arrays for weekly data (for chart)
$weeklySessions = @{
    1 = 0  # Monday
    2 = 0  # Tuesday
    3 = 0  # Wednesday
    4 = 0  # Thursday
    5 = 0  # Friday
    6 = 0  # Saturday
    7 = 0  # Sunday
}

# Count sessions
if (Test-Path $SessionsDir) {
    $sessionFiles = Get-ChildItem -Path $SessionsDir -Filter "*.md" -File -ErrorAction SilentlyContinue

    foreach ($file in $sessionFiles) {
        $totalSessions++

        if ($file.Name -match '^(\d{4}-\d{2}-\d{2})') {
            $fileDate = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd", $null)

            # This week
            if ($fileDate -ge $weekStart.Date) {
                $sessionsThisWeek++

                # Track by weekday
                $dow = [int]$fileDate.DayOfWeek
                if ($dow -eq 0) { $dow = 7 }  # Sunday = 7
                $weeklySessions[$dow]++
            }

            # Last week
            if ($fileDate -ge $lastWeekStart.Date -and $fileDate -lt $weekStart.Date) {
                $sessionsLastWeek++
            }

            # This month
            if ($fileDate -ge $monthStart.Date) {
                $sessionsThisMonth++
            }
        }
    }
}

# Count decisions
if (Test-Path $DecisionsDir) {
    $decisionFiles = Get-ChildItem -Path $DecisionsDir -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("index.md", "INDEX.md") }

    foreach ($file in $decisionFiles) {
        $totalDecisions++

        if ($file.Name -match '^(\d{4}-\d{2}-\d{2})') {
            $fileDate = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd", $null)

            if ($fileDate -ge $weekStart.Date) {
                $decisionsThisWeek++
            } elseif ($fileDate -ge $lastWeekStart.Date -and $fileDate -lt $weekStart.Date) {
                $decisionsLastWeek++
            }
        }
    }
}

# Knowledge analysis
$knowledgeInfo = @{}
$staleCount = 0
$freshCount = 0
$recentCount = 0

if (Test-Path $KnowledgeDir) {
    $knowledgeFiles = Get-ChildItem -Path $KnowledgeDir -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("index.md", "INDEX.md") }

    foreach ($file in $knowledgeFiles) {
        $totalKnowledge++

        # Get topic name
        $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
        $topic = $file.BaseName
        if ($content -and $content.Count -gt 0) {
            $firstLine = $content[0] -replace '^#+\s*', ''
            if (-not [string]::IsNullOrWhiteSpace($firstLine)) {
                $topic = $firstLine
            }
        }

        # Get modification date and age
        $modified = $file.LastWriteTime.ToString("yyyy-MM-dd")
        $ageDays = ($currentDate - $file.LastWriteTime).Days

        if ($ageDays -lt 7) {
            $status = "Fresh"
            $freshCount++
        } elseif ($ageDays -lt 30) {
            $status = "Recent"
            $recentCount++
        } else {
            $status = "Stale"
            $staleCount++
        }

        # Calculate relative time
        if ($ageDays -eq 0) {
            $relative = "today"
        } elseif ($ageDays -eq 1) {
            $relative = "yesterday"
        } elseif ($ageDays -lt 7) {
            $relative = "$ageDays days ago"
        } elseif ($ageDays -lt 30) {
            $weeks = [Math]::Floor($ageDays / 7)
            $relative = "$weeks week(s) ago"
        } else {
            $months = [Math]::Floor($ageDays / 30)
            $relative = "$months month(s) ago"
        }

        $knowledgeInfo[$topic] = @{
            Modified = $modified
            Status = $status
            Relative = $relative
        }
    }
}

# Check for active plan
$activePlanPath = Join-Path $PlansDir "active_plan.md"
if (Test-Path $activePlanPath) {
    $planContent = Get-Content -Path $activePlanPath -ErrorAction SilentlyContinue
    if ($planContent -and $planContent.Count -gt 0) {
        $activePlan = $planContent[0] -replace '^#+\s*', ''
    }
}

# Day names
$dayNames = @{
    1 = "Mon"
    2 = "Tue"
    3 = "Wed"
    4 = "Thu"
    5 = "Fri"
    6 = "Sat"
    7 = "Sun"
}

# Trend indicator
$trend = "→"
if ($sessionsThisWeek -gt $sessionsLastWeek) { $trend = "↑" }
elseif ($sessionsThisWeek -lt $sessionsLastWeek) { $trend = "↓" }

# Build the dashboard markdown
$dashboard = @"
# Memory System Dashboard

**Generated:** $currentDateTime

---

## Overview

| Metric | Value |
|--------|-------|
| Total Sessions | $totalSessions |
| Total Decisions | $totalDecisions |
| Knowledge Topics | $totalKnowledge |
| Active Plan | $(if ($activePlan) { $activePlan } else { "None" }) |

---

## Activity Trends

### Weekly Summary

| Period | Sessions | Decisions | Trend |
|--------|----------|-----------|-------|
| This week | $sessionsThisWeek | $decisionsThisWeek | $trend |
| Last week | $sessionsLastWeek | $decisionsLastWeek | |
| This month | $sessionsThisMonth | - | |

### This Week's Activity

``````
"@

# Add ASCII chart
foreach ($i in 1..7) {
    $count = $weeklySessions[$i]
    $bar = ""
    for ($j = 0; $j -lt $count -and $j -lt 20; $j++) {
        $bar += "█"
    }
    for ($j = $count; $j -lt 20; $j++) {
        $bar += "░"
    }
    $dashboard += "$($dayNames[$i]): $bar $count`n"
}

$dashboard += @"
``````

---

## Knowledge Base Health

| Topic | Last Updated | Age | Status |
|-------|--------------|-----|--------|
"@

# Add knowledge entries
foreach ($topic in $knowledgeInfo.Keys) {
    $info = $knowledgeInfo[$topic]
    $statusEmoji = switch ($info.Status) {
        "Fresh" { "✅" }
        "Recent" { "🟡" }
        "Stale" { "🔴" }
    }
    $dashboard += "| $topic | $($info.Modified) | $($info.Relative) | $statusEmoji $($info.Status) |`n"
}

if ($knowledgeInfo.Count -eq 0) {
    $dashboard += "| *No knowledge files* | - | - | - |`n"
}

$dashboard += @"

### Health Summary
- Fresh (< 7 days): $freshCount
- Recent (7-30 days): $recentCount
- Stale (> 30 days): $staleCount

---

## Recent Sessions

"@

# List 5 most recent sessions
$sessionCount = 0
if (Test-Path $SessionsDir) {
    $recentSessions = Get-ChildItem -Path $SessionsDir -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 5

    foreach ($file in $recentSessions) {
        $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
        $title = $file.BaseName
        if ($content -and $content.Count -gt 0) {
            $title = $content[0] -replace '^#+\s*', ''
        }
        $dashboard += "- ``$($file.Name)``: $title`n"
        $sessionCount++
    }
}

if ($sessionCount -eq 0) {
    $dashboard += "*No sessions recorded yet*`n"
}

$dashboard += @"

---

## Recommendations

"@

# Generate recommendations
$recommendations = @()

if ($staleCount -gt 0) {
    $recommendations += "📚 **Update stale knowledge**: $staleCount knowledge file(s) haven't been updated in over 30 days. Review and update them to keep information current."
}

if ($totalSessions -gt 5 -and $totalDecisions -eq 0) {
    $recommendations += "📝 **Document decisions**: You've had $totalSessions sessions but no decisions recorded. Consider documenting key decisions for future reference."
}

if ($totalKnowledge -eq 0) {
    $recommendations += "💡 **Start knowledge base**: No knowledge files exist yet. Document key learnings, patterns, and project-specific information."
}

if ($sessionsThisWeek -eq 0 -and $sessionsLastWeek -gt 0) {
    $recommendations += "⏰ **Resume sessions**: No sessions this week but $sessionsLastWeek last week. Don't forget to document your work!"
}

if (-not $activePlan) {
    $recommendations += "🎯 **Create a plan**: No active plan found. Consider creating one to track project goals and progress."
}

if ($recommendations.Count -eq 0) {
    $recommendations += "✨ **Looking good!** Your memory system is well-maintained. Keep up the great documentation habits!"
}

foreach ($rec in $recommendations) {
    $dashboard += "- $rec`n"
}

$dashboard += @"

---

## Quick Actions

- Run ``.\scripts\auto-summary.ps1`` to generate a session summary
- Run ``.\scripts\link-knowledge.ps1`` to find cross-reference opportunities
- Run ``.\scripts\memory-analytics.ps1 -Json`` for programmatic access to metrics
- Run ``.\scripts\prune-sessions.ps1`` to clean up old session files

---

*Dashboard generated by ``generate-dashboard.ps1``*
"@

# Write to file
$dashboard | Out-File -FilePath $Output -Encoding utf8 -Force

Write-Host "Dashboard generated: $Output" -ForegroundColor Green
Write-Host ""
Write-Host "Overview:" -ForegroundColor Cyan
Write-Host "  Sessions: $totalSessions (This week: $sessionsThisWeek)"
Write-Host "  Decisions: $totalDecisions"
Write-Host "  Knowledge: $totalKnowledge (Stale: $staleCount)"

# memory-analytics.ps1
# Generates analytics about memory system usage
#
# Usage: .\memory-analytics.ps1 [-ProjectDir <path>] [-Json]
#   -ProjectDir: Optional path to project root (default: current directory)
#   -Json: Output in JSON format instead of human-readable
#
# Behavior:
#   - Counts total sessions, decisions, knowledge files
#   - Calculates sessions per week/month trend
#   - Identifies most active days/times
#   - Breaks down decision categories
#   - Assesses knowledge base coverage
#
# Exit codes: 0 on success, 1 on error

param(
    [string]$ProjectDir = ".",
    [switch]$Json
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

# Initialize counters and data structures
$totalSessions = 0
$totalDecisions = 0
$totalKnowledge = 0
$activePlan = ""
$sessionsThisWeek = 0
$sessionsLastWeek = 0
$decisionsThisWeek = 0
$decisionsLastWeek = 0

$sessionByDate = @{}
$sessionByHour = @{}
$decisionCategories = @{}
$knowledgeTopics = @{}

# Date calculations
$currentDate = Get-Date
$weekStart = $currentDate.AddDays(-($currentDate.DayOfWeek.value__ - 1))
if ($currentDate.DayOfWeek -eq "Sunday") {
    $weekStart = $currentDate.AddDays(-6)
}
$lastWeekStart = $weekStart.AddDays(-7)

# Count and analyze sessions
if (Test-Path $SessionsDir) {
    $sessionFiles = Get-ChildItem -Path $SessionsDir -Filter "*.md" -File -ErrorAction SilentlyContinue

    foreach ($file in $sessionFiles) {
        $totalSessions++

        # Extract date from filename (YYYY-MM-DD format)
        if ($file.Name -match '^(\d{4}-\d{2}-\d{2})') {
            $fileDate = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd", $null)
            $dateKey = $fileDate.ToString("yyyy-MM-dd")

            if (-not $sessionByDate.ContainsKey($dateKey)) {
                $sessionByDate[$dateKey] = 0
            }
            $sessionByDate[$dateKey]++

            # Check week boundaries
            if ($fileDate -ge $weekStart.Date) {
                $sessionsThisWeek++
            } elseif ($fileDate -ge $lastWeekStart.Date -and $fileDate -lt $weekStart.Date) {
                $sessionsLastWeek++
            }
        }

        # Extract hour from filename (HH-MM format)
        if ($file.Name -match '_(\d{2})-\d{2}_') {
            $fileHour = $Matches[1]
            if (-not $sessionByHour.ContainsKey($fileHour)) {
                $sessionByHour[$fileHour] = 0
            }
            $sessionByHour[$fileHour]++
        }
    }
}

# Count and analyze decisions
if (Test-Path $DecisionsDir) {
    $decisionFiles = Get-ChildItem -Path $DecisionsDir -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("index.md", "INDEX.md") }

    foreach ($file in $decisionFiles) {
        $totalDecisions++

        # Extract date from filename
        if ($file.Name -match '^(\d{4}-\d{2}-\d{2})') {
            $fileDate = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd", $null)

            if ($fileDate -ge $weekStart.Date) {
                $decisionsThisWeek++
            } elseif ($fileDate -ge $lastWeekStart.Date -and $fileDate -lt $weekStart.Date) {
                $decisionsLastWeek++
            }
        }

        # Try to extract category from file
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
        $category = "Uncategorized"
        if ($content -match '\*\*Category\*\*:\s*(.+)') {
            $category = $Matches[1].Trim()
        } elseif ($content -match 'Category:\s*(.+)') {
            $category = $Matches[1].Trim()
        }

        if (-not $decisionCategories.ContainsKey($category)) {
            $decisionCategories[$category] = 0
        }
        $decisionCategories[$category]++
    }
}

# Count and analyze knowledge files
if (Test-Path $KnowledgeDir) {
    $knowledgeFiles = Get-ChildItem -Path $KnowledgeDir -Filter "*.md" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("index.md", "INDEX.md") }

    foreach ($file in $knowledgeFiles) {
        $totalKnowledge++

        # Get topic name from first line
        $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
        $topic = $file.BaseName
        if ($content -and $content.Count -gt 0) {
            $firstLine = $content[0] -replace '^#+\s*', ''
            if (-not [string]::IsNullOrWhiteSpace($firstLine)) {
                $topic = $firstLine
            }
        }

        # Get last modified date and calculate age
        $modified = $file.LastWriteTime.ToString("yyyy-MM-dd")
        $ageDays = ($currentDate - $file.LastWriteTime).Days

        $ageStatus = "Fresh"
        if ($ageDays -ge 30) {
            $ageStatus = "Stale"
        } elseif ($ageDays -ge 7) {
            $ageStatus = "Recent"
        }

        $knowledgeTopics[$topic] = @{
            LastUpdated = $modified
            Status = $ageStatus
            AgeDays = $ageDays
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

# Find most active times
$mostActiveHour = ""
$maxHourSessions = 0
foreach ($hour in $sessionByHour.Keys) {
    if ($sessionByHour[$hour] -gt $maxHourSessions) {
        $maxHourSessions = $sessionByHour[$hour]
        $mostActiveHour = $hour
    }
}

# Find most active day
$mostActiveDay = ""
$maxDaySessions = 0
foreach ($day in $sessionByDate.Keys) {
    if ($sessionByDate[$day] -gt $maxDaySessions) {
        $maxDaySessions = $sessionByDate[$day]
        $mostActiveDay = $day
    }
}

# Calculate stale knowledge count
$staleKnowledge = ($knowledgeTopics.Values | Where-Object { $_.Status -eq "Stale" }).Count

# Output results
if ($Json) {
    # JSON output
    $knowledgeArray = @()
    foreach ($topic in $knowledgeTopics.Keys) {
        $info = $knowledgeTopics[$topic]
        $knowledgeArray += @{
            topic = $topic
            lastUpdated = $info.LastUpdated
            status = $info.Status
            ageDays = $info.AgeDays
        }
    }

    $output = @{
        generatedAt = $currentDate.ToString("yyyy-MM-dd")
        totals = @{
            sessions = $totalSessions
            decisions = $totalDecisions
            knowledgeTopics = $totalKnowledge
        }
        activity = @{
            sessionsThisWeek = $sessionsThisWeek
            sessionsLastWeek = $sessionsLastWeek
            decisionsThisWeek = $decisionsThisWeek
            decisionsLastWeek = $decisionsLastWeek
        }
        patterns = @{
            mostActiveHour = if ($mostActiveHour) { $mostActiveHour } else { "none" }
            mostActiveDay = if ($mostActiveDay) { $mostActiveDay } else { "none" }
        }
        activePlan = if ($activePlan) { $activePlan } else { "none" }
        decisionCategories = $decisionCategories
        knowledgeTopics = $knowledgeArray
        recommendations = @{
            staleKnowledge = $staleKnowledge
        }
    }

    $output | ConvertTo-Json -Depth 10
} else {
    # Human-readable output
    Write-Host "=== Memory System Analytics ===" -ForegroundColor Cyan
    Write-Host "Generated: $($currentDate.ToString('yyyy-MM-dd'))"
    Write-Host ""

    Write-Host "## Overview" -ForegroundColor Yellow
    Write-Host "| Metric | Value |"
    Write-Host "|--------|-------|"
    Write-Host "| Total Sessions | $totalSessions |"
    Write-Host "| Total Decisions | $totalDecisions |"
    Write-Host "| Knowledge Topics | $totalKnowledge |"
    Write-Host "| Active Plan | $(if ($activePlan) { $activePlan } else { 'None' }) |"
    Write-Host ""

    Write-Host "## Activity Trends" -ForegroundColor Yellow
    Write-Host "| Period | Sessions | Decisions |"
    Write-Host "|--------|----------|-----------|"
    Write-Host "| This week | $sessionsThisWeek | $decisionsThisWeek |"
    Write-Host "| Last week | $sessionsLastWeek | $decisionsLastWeek |"
    Write-Host ""

    if ($mostActiveHour) {
        Write-Host "## Usage Patterns" -ForegroundColor Yellow
        Write-Host "- Most active hour: ${mostActiveHour}:00 ($maxHourSessions sessions)"
        if ($mostActiveDay) {
            Write-Host "- Most active day: $mostActiveDay ($maxDaySessions sessions)"
        }
        Write-Host ""
    }

    if ($decisionCategories.Count -gt 0) {
        Write-Host "## Decision Categories" -ForegroundColor Yellow
        foreach ($cat in $decisionCategories.Keys) {
            Write-Host "- ${cat}: $($decisionCategories[$cat])"
        }
        Write-Host ""
    }

    if ($knowledgeTopics.Count -gt 0) {
        Write-Host "## Knowledge Base" -ForegroundColor Yellow
        Write-Host "| Topic | Last Updated | Status |"
        Write-Host "|-------|--------------|--------|"
        foreach ($topic in $knowledgeTopics.Keys) {
            $info = $knowledgeTopics[$topic]
            Write-Host "| $topic | $($info.LastUpdated) | $($info.Status) |"
        }
        Write-Host ""
    }

    Write-Host "## Recommendations" -ForegroundColor Yellow
    if ($staleKnowledge -gt 0) {
        Write-Host "- $staleKnowledge knowledge file(s) are stale (>30 days old) - consider updating" -ForegroundColor Yellow
    }

    $sessionsWithoutDecisions = $sessionsThisWeek + $sessionsLastWeek
    $decisionsTotal = $decisionsThisWeek + $decisionsLastWeek
    if ($sessionsWithoutDecisions -gt 3 -and $decisionsTotal -eq 0) {
        Write-Host "- $sessionsWithoutDecisions recent sessions without decisions - review if any decisions were made" -ForegroundColor Yellow
    }

    if ($totalKnowledge -eq 0) {
        Write-Host "- No knowledge files yet - consider documenting key learnings" -ForegroundColor Yellow
    }

    Write-Host ""
}

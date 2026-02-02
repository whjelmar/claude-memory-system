# auto-summary.ps1
# Analyzes git diff and generates a draft session summary
#
# Usage: .\auto-summary.ps1 [-ProjectDir <path>] [-Output <file>] [-Since <timestamp>]
#   -ProjectDir: Optional path to project root (default: current directory)
#   -Output: Write summary to file instead of stdout
#   -Since: Generate diff since specific timestamp (ISO format or git ref)
#
# Behavior:
#   - Gets git diff since last commit or since session start
#   - Analyzes changed files (count, types, additions/deletions)
#   - Extracts commit messages
#   - Generates a draft session summary in markdown format
#
# Exit codes: 0 on success, 1 on error

param(
    [string]$ProjectDir = ".",
    [string]$Output = "",
    [string]$Since = ""
)

# Resolve to absolute path
try {
    $ProjectDir = Resolve-Path $ProjectDir -ErrorAction Stop
} catch {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

# Change to project directory
Push-Location $ProjectDir
try {
    # Check if git repository
    $gitCheck = git rev-parse --git-dir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not a git repository: $ProjectDir"
        exit 1
    }

    # Get session start timestamp from current_context.md if exists
    $contextFile = Join-Path $ProjectDir ".claude\memory\current_context.md"
    $sessionStart = ""

    if (Test-Path $contextFile) {
        $contextContent = Get-Content $contextFile -Raw -ErrorAction SilentlyContinue
        if ($contextContent -match '\*\*Last Updated\*\*:\s*(.+)') {
            $sessionStart = $Matches[1].Trim()
        }
    }

    # Determine the reference point for diff
    $diffRef = ""
    if ($Since) {
        $diffRef = $Since
    } elseif ($sessionStart) {
        # Try to find commits since session start
        $diffRef = git rev-list -n1 --before="$sessionStart" HEAD 2>$null
        if (-not $diffRef) { $diffRef = "HEAD~10" }
    } else {
        # Default: show uncommitted changes or last 10 commits
        $stagedEmpty = git diff --cached --quiet 2>$null; $stagedExitCode = $LASTEXITCODE
        $unstagedEmpty = git diff --quiet 2>$null; $unstagedExitCode = $LASTEXITCODE

        if ($stagedExitCode -eq 0 -and $unstagedExitCode -eq 0) {
            $diffRef = "HEAD~10"
        } else {
            $diffRef = "HEAD"
        }
    }

    # Current date/time
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm"
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    $currentTime = Get-Date -Format "HH-mm"

    # Get combined diff statistics
    $combinedNumstat = git diff HEAD --numstat 2>$null

    # Count files, insertions, deletions
    $filesChanged = 0
    $insertions = 0
    $deletions = 0

    if ($combinedNumstat) {
        $lines = $combinedNumstat -split "`n" | Where-Object { $_ -match '\S' }
        $filesChanged = $lines.Count
        foreach ($line in $lines) {
            $parts = $line -split '\s+'
            if ($parts[0] -match '^\d+$') { $insertions += [int]$parts[0] }
            if ($parts[1] -match '^\d+$') { $deletions += [int]$parts[1] }
        }
    }

    # Get recent commits (since reference or last 10)
    $commitCount = 0
    $commitMessages = @()

    if ($diffRef -ne "HEAD") {
        $commits = git log --oneline "$diffRef..HEAD" 2>$null
        if ($commits) {
            $commitLines = $commits -split "`n" | Where-Object { $_ -match '\S' }
            $commitCount = $commitLines.Count
            foreach ($line in $commitLines) {
                $msg = ($line -split ' ', 2)[1]
                $commitMessages += "- `"$msg`""
            }
        }
    }

    # Get list of changed files with status
    $modifiedFiles = @()
    $addedFiles = @()
    $deletedFiles = @()

    # Staged files
    $stagedStatus = git diff --cached --name-status 2>$null
    if ($stagedStatus) {
        foreach ($line in ($stagedStatus -split "`n" | Where-Object { $_ -match '\S' })) {
            $parts = $line -split '\s+', 2
            $status = $parts[0]
            $file = $parts[1]
            switch ($status[0]) {
                'M' { if ($file -notin $modifiedFiles) { $modifiedFiles += $file } }
                'A' { if ($file -notin $addedFiles) { $addedFiles += $file } }
                'D' { if ($file -notin $deletedFiles) { $deletedFiles += $file } }
                'R' { if ($file -notin $modifiedFiles) { $modifiedFiles += "$file (renamed)" } }
            }
        }
    }

    # Unstaged files
    $unstagedStatus = git diff --name-status 2>$null
    if ($unstagedStatus) {
        foreach ($line in ($unstagedStatus -split "`n" | Where-Object { $_ -match '\S' })) {
            $parts = $line -split '\s+', 2
            $status = $parts[0]
            $file = $parts[1]
            switch ($status[0]) {
                'M' { if ($file -notin $modifiedFiles) { $modifiedFiles += $file } }
                'D' { if ($file -notin $deletedFiles) { $deletedFiles += $file } }
            }
        }
    }

    # Untracked files
    $untracked = git ls-files --others --exclude-standard 2>$null
    if ($untracked) {
        foreach ($file in ($untracked -split "`n" | Where-Object { $_ -match '\S' })) {
            $addedFiles += "$file (untracked)"
        }
    }

    # Analyze file types for auto-summary
    $allChangedFiles = git diff HEAD --name-only 2>$null
    $untrackedFiles = git ls-files --others --exclude-standard 2>$null
    $allFiles = @()
    if ($allChangedFiles) { $allFiles += $allChangedFiles -split "`n" | Where-Object { $_ -match '\S' } }
    if ($untrackedFiles) { $allFiles += $untrackedFiles -split "`n" | Where-Object { $_ -match '\S' } }

    # Categorize work based on file patterns
    $testFiles = ($allFiles | Where-Object { $_ -match '(test|spec)\.' }).Count
    $docFiles = ($allFiles | Where-Object { $_ -match '\.(md|txt|rst)$' }).Count
    $configFiles = ($allFiles | Where-Object { $_ -match '\.(json|yaml|yml|toml|ini|conf)$' }).Count
    $srcFiles = $filesChanged - $testFiles - $docFiles - $configFiles

    # Generate auto-summary based on file types
    $autoSummary = ""
    if ($testFiles -gt 0 -and $srcFiles -gt 0) {
        $autoSummary = "Implementation work with corresponding tests."
    } elseif ($testFiles -gt $srcFiles) {
        $autoSummary = "Testing and test coverage improvements."
    } elseif ($docFiles -gt $srcFiles) {
        $autoSummary = "Documentation updates."
    } elseif ($configFiles -gt $srcFiles) {
        $autoSummary = "Configuration and setup changes."
    } elseif ($srcFiles -gt 0) {
        $autoSummary = "Source code implementation."
    }

    if ($commitMessages.Count -gt 0) {
        $autoSummary += " Based on commits: work includes changes to the codebase."
    }

    # Build changed files list
    $changedFilesList = @()
    foreach ($f in $modifiedFiles) {
        $changedFilesList += "- ``$f`` (modified)"
    }
    foreach ($f in $addedFiles) {
        if ($f -match '\(untracked\)$') {
            $cleanFile = $f -replace ' \(untracked\)$', ''
            $changedFilesList += "- ``$cleanFile`` (new, untracked)"
        } else {
            $changedFilesList += "- ``$f`` (added)"
        }
    }
    foreach ($f in $deletedFiles) {
        $changedFilesList += "- ``$f`` (deleted)"
    }

    if ($changedFilesList.Count -eq 0) {
        $changedFilesList = @("- No changes detected")
    }

    # Build commit messages section
    $commitSection = ""
    if ($commitMessages.Count -gt 0) {
        $commitSection = $commitMessages -join "`n"
    } else {
        $commitSection = "- No commits in this session yet"
    }

    # Generate the summary
    $summary = @"
# Session Summary: $currentDateTime

## Git Activity
- Files changed: $filesChanged
- Insertions: +$insertions
- Deletions: -$deletions
- Commits: $commitCount

### Changed Files
$($changedFilesList -join "`n")

### Commit Messages
$commitSection

## Draft Summary
$autoSummary

## Work Completed (fill in)
- [ ] Item 1
- [ ] Item 2

## Decisions Made
- [ ] None / Add decisions here

## Next Steps
- [ ] Continue with...

---
*Generated by auto-summary.ps1 at $currentDateTime*
"@

    # Output the summary
    if ($Output) {
        # Ensure sessions directory exists
        $sessionsDir = Join-Path $ProjectDir ".claude\memory\sessions"
        if (-not (Test-Path $sessionsDir)) {
            New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
        }

        # If output file is just a filename, put it in sessions directory
        if (-not [System.IO.Path]::IsPathRooted($Output) -and -not $Output.StartsWith(".")) {
            $Output = Join-Path $sessionsDir $Output
        }

        $summary | Out-File -FilePath $Output -Encoding utf8 -Force
        Write-Host "Session summary written to: $Output" -ForegroundColor Green
    } else {
        Write-Output $summary
    }

} finally {
    Pop-Location
}

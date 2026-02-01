# Claude Memory System - Session End Hook (PowerShell)
# Runs on Stop to remind about saving context
#
# Exit codes:
#   0 - Success
#   1 - Warning (context may need update)

param(
    [string]$ProjectRoot = $null
)

$ErrorActionPreference = "SilentlyContinue"

# Configuration
$MEMORY_DIR = ".claude\memory"
$CONTEXT_FILE = "$MEMORY_DIR\current_context.md"
$DECISIONS_FILE = "$MEMORY_DIR\decisions.md"

# Find project root
function Find-ProjectRoot {
    $dir = Get-Location
    while ($dir -ne $null -and $dir.Path -ne [System.IO.Path]::GetPathRoot($dir.Path)) {
        if ((Test-Path "$($dir.Path)\.claude") -or (Test-Path "$($dir.Path)\.git")) {
            return $dir.Path
        }
        $dir = Split-Path $dir.Path -Parent
        if ($dir) {
            $dir = Get-Item $dir -ErrorAction SilentlyContinue
        }
    }
    return (Get-Location).Path
}

# Set project root
if ($ProjectRoot) {
    Set-Location $ProjectRoot
} else {
    $ProjectRoot = Find-ProjectRoot
    Set-Location $ProjectRoot
}

# Check if memory system exists
if (-not (Test-Path $MEMORY_DIR)) {
    # Silently exit if memory system not set up
    exit 0
}

$today = (Get-Date).ToString("yyyy-MM-dd")
$needsUpdate = $false

# Check if current_context.md was modified today
if (Test-Path $CONTEXT_FILE) {
    $modDate = (Get-Item $CONTEXT_FILE).LastWriteTime.ToString("yyyy-MM-dd")
    if ($modDate -ne $today) {
        $needsUpdate = $true
    }
} else {
    $needsUpdate = $true
}

# Check git status for modified files
$gitStatus = $null
if (Get-Command git -ErrorAction SilentlyContinue) {
    if (Test-Path ".git") {
        $gitStatus = git status --porcelain 2>$null
    }
}

# Output reminders if needed
if ($needsUpdate -or $gitStatus) {
    Write-Host ""
    Write-Host "=== Session End: Memory System Check ===" -ForegroundColor Cyan

    if ($needsUpdate) {
        Write-Host ""
        Write-Host "! Context not updated today." -ForegroundColor Yellow
        Write-Host "  Consider saving a session summary to: $CONTEXT_FILE"
        Write-Host "  Run: /memory-bank:save"
    }

    if ($gitStatus) {
        Write-Host ""
        Write-Host "Modified files in workspace:" -ForegroundColor White
        $lines = $gitStatus -split "`n"
        $lines | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
        if ($lines.Count -gt 20) {
            Write-Host "... and $($lines.Count - 20) more files"
        }
    }

    Write-Host ""
    Write-Host "=== End of Session Check ===" -ForegroundColor Cyan
}

exit 0

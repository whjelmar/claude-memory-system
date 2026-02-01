# Claude Memory System - Session Start Hook (PowerShell)
# Runs on SessionStart to initialize memory context
#
# Exit codes:
#   0 - Success (memory system ready)
#   1 - Setup needed or error

param(
    [string]$ProjectRoot = $null
)

$ErrorActionPreference = "Stop"

# Configuration
$MEMORY_DIR = ".claude\memory"
$ARCHITECTURE_FILE = "$MEMORY_DIR\ARCHITECTURE.md"
$CONTEXT_FILE = "$MEMORY_DIR\current_context.md"
$SETUP_SCRIPT = "scripts\setup.ps1"

# Find project root (look for .claude directory or git root)
function Find-ProjectRoot {
    $dir = Get-Location
    while ($dir -ne $null -and $dir.Path -ne [System.IO.Path]::GetPathRoot($dir.Path)) {
        if ((Test-Path "$($dir.Path)\.claude") -or (Test-Path "$($dir.Path)\.git")) {
            return $dir.Path
        }
        $dir = Split-Path $dir.Path -Parent
        if ($dir) {
            $dir = Get-Item $dir
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

# Check if memory system is set up
if (-not (Test-Path $ARCHITECTURE_FILE)) {
    Write-Host "Memory system not initialized."

    # Attempt auto-setup if setup script exists
    if (Test-Path $SETUP_SCRIPT) {
        Write-Host "Running setup..."
        try {
            & powershell -ExecutionPolicy Bypass -File $SETUP_SCRIPT
            Write-Host "Memory system initialized successfully."
        } catch {
            Write-Error "Setup failed. Please run setup manually."
            Write-Host "Run: powershell -File scripts\setup.ps1" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Error "Please initialize the memory system first."
        Write-Host "Run: powershell -File scripts\setup.ps1" -ForegroundColor Yellow
        exit 1
    }
}

# Memory system is ready - provide context hint
if (Test-Path $CONTEXT_FILE) {
    # Get modification date
    $modDate = (Get-Item $CONTEXT_FILE).LastWriteTime.ToString("yyyy-MM-dd")

    Write-Host "--- Memory Context (last updated: $modDate) ---"
    Get-Content $CONTEXT_FILE -TotalCount 5 | ForEach-Object { Write-Host $_ }
    Write-Host "..."
    Write-Host "---"
    Write-Host ""
    Write-Host "Tip: Read .claude\memory\ for full project context"
} else {
    Write-Host "Memory system ready but no current context found."
    Write-Host "Consider running: /memory-bank:read"
}

exit 0

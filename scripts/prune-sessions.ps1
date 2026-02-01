# prune-sessions.ps1
# Archives session summaries older than N days
#
# Usage: .\prune-sessions.ps1 [-Days <number>] [-ProjectDir <path>]
#   -Days:       Number of days to keep (default: 30)
#   -ProjectDir: Optional path to project root (default: current directory)
#
# Behavior:
#   - Finds session files older than N days
#   - Moves them to .claude/memory/sessions/archive/
#   - Creates archive directory if needed
#   - Outputs summary of archived files
#
# Exit codes: 0 on success, 1 on error

param(
    [int]$Days = 30,
    [string]$ProjectDir = "."
)

# Validate days
if ($Days -lt 0) {
    Write-Error "Days must be a non-negative integer"
    exit 1
}

# Resolve to absolute path
try {
    $ProjectDir = Resolve-Path $ProjectDir -ErrorAction Stop
} catch {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

$SessionsDir = Join-Path $ProjectDir ".claude\memory\sessions"
$ArchiveDir = Join-Path $SessionsDir "archive"

Write-Host "Pruning sessions older than $Days days..." -ForegroundColor Cyan
Write-Host "Sessions directory: $SessionsDir"
Write-Host ""

# Check if sessions directory exists
if (-not (Test-Path $SessionsDir)) {
    Write-Host "Sessions directory does not exist. Nothing to prune." -ForegroundColor Yellow
    exit 0
}

# Create archive directory if needed
if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    Write-Host "Created archive directory: $ArchiveDir" -ForegroundColor Green
}

# Calculate cutoff date
$cutoffDate = (Get-Date).AddDays(-$Days)

# Find and archive old session files
$archivedCount = 0
$archivedFiles = @()

# Get markdown files in sessions directory (not in archive subdirectory)
$sessionFiles = Get-ChildItem -Path $SessionsDir -Filter "*.md" -File -ErrorAction SilentlyContinue

foreach ($file in $sessionFiles) {
    # Skip if file is in archive directory
    if ($file.DirectoryName -eq $ArchiveDir) {
        continue
    }

    # Check if file is older than cutoff
    if ($file.LastWriteTime -lt $cutoffDate) {
        # Move to archive
        $destination = Join-Path $ArchiveDir $file.Name
        Move-Item -Path $file.FullName -Destination $destination -Force
        $archivedFiles += $file.Name
        $archivedCount++
    }
}

Write-Host ""
Write-Host "=== Prune Summary ===" -ForegroundColor Cyan
Write-Host "Days threshold: $Days"
Write-Host "Files archived: $archivedCount"

if ($archivedCount -gt 0) {
    Write-Host ""
    Write-Host "Archived files:" -ForegroundColor White
    foreach ($fileName in $archivedFiles) {
        Write-Host "  - $fileName" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Archive location: $ArchiveDir" -ForegroundColor Gray
} else {
    Write-Host "No sessions found older than $Days days." -ForegroundColor Yellow
}

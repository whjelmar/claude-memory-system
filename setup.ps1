# Memory System Setup Script (PowerShell)
# Run this in any project to set up the persistent memory system
#
# Usage: & "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1"
#    or: & "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1" -ProjectDir "C:\path\to\project"

param(
    [string]$ProjectDir = "."
)

$TemplateDir = Join-Path $env:USERPROFILE ".claude\templates\claude-memory-system\templates"
$ProjectDir = Resolve-Path $ProjectDir -ErrorAction SilentlyContinue
if (-not $ProjectDir) { $ProjectDir = "." }

Write-Host "Setting up Claude Code memory system in: $ProjectDir" -ForegroundColor Cyan

# Create directory structure
$directories = @(
    ".claude\memory\sessions",
    ".claude\memory\decisions",
    ".claude\memory\knowledge",
    ".claude\plans"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $ProjectDir $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    }
}

# Copy template files
$fileMappings = @{
    "ARCHITECTURE.md" = ".claude\memory\ARCHITECTURE.md"
    "USAGE.md" = ".claude\memory\USAGE.md"
    "current_context.md" = ".claude\memory\current_context.md"
    "active_plan.md" = ".claude\plans\active_plan.md"
    "findings.md" = ".claude\plans\findings.md"
    "progress.md" = ".claude\plans\progress.md"
}

foreach ($source in $fileMappings.Keys) {
    $sourcePath = Join-Path $TemplateDir $source
    $destPath = Join-Path $ProjectDir $fileMappings[$source]

    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination $destPath -Force
        Write-Host "  Copied: $($fileMappings[$source])" -ForegroundColor Green
    }
}

# Create .gitkeep files
$gitkeepDirs = @(
    ".claude\memory\sessions",
    ".claude\memory\decisions",
    ".claude\memory\knowledge"
)

foreach ($dir in $gitkeepDirs) {
    $gitkeepPath = Join-Path $ProjectDir "$dir\.gitkeep"
    if (-not (Test-Path $gitkeepPath)) {
        "# Placeholder for git" | Out-File -FilePath $gitkeepPath -Encoding utf8
    }
}

# Update CLAUDE.md
$claudeMdPath = Join-Path $ProjectDir "CLAUDE.md"
$sectionPath = Join-Path $TemplateDir "CLAUDE_SECTION.md"

if (Test-Path $sectionPath) {
    $memorySection = Get-Content $sectionPath -Raw

    if (Test-Path $claudeMdPath) {
        $existingContent = Get-Content $claudeMdPath -Raw
        if ($existingContent -notmatch "Session Continuity System") {
            Add-Content -Path $claudeMdPath -Value "`n$memorySection"
            Write-Host "  Updated: CLAUDE.md (added memory system section)" -ForegroundColor Green
        } else {
            Write-Host "  Skipped: CLAUDE.md (memory section already exists)" -ForegroundColor Yellow
        }
    } else {
        @"
# CLAUDE.md

Project instructions for Claude Code.

$memorySection
"@ | Out-File -FilePath $claudeMdPath -Encoding utf8
        Write-Host "  Created: CLAUDE.md" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Memory system setup complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files created:" -ForegroundColor White
Write-Host "  .claude/memory/ARCHITECTURE.md"
Write-Host "  .claude/memory/USAGE.md"
Write-Host "  .claude/memory/current_context.md"
Write-Host "  .claude/plans/active_plan.md"
Write-Host "  .claude/plans/findings.md"
Write-Host "  .claude/plans/progress.md"
Write-Host ""
Write-Host "Usage:" -ForegroundColor White
Write-Host "  - Read current_context.md at session start"
Write-Host "  - Update progress.md during work"
Write-Host "  - Create session summaries at session end"
Write-Host ""

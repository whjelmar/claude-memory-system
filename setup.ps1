# Memory System Setup Script (PowerShell)
# Run this in any project to set up the persistent memory system
#
# Usage: & "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1"
#    or: & "$env:USERPROFILE\.claude\templates\claude-memory-system\setup.ps1" -ProjectDir "C:\path\to\project"
#
# Options:
#   -InstallSkills    Also install slash commands to ~/.claude/skills/
#   -BuildMcp         Also build the MCP server (requires Node.js)
#   -Full             Install everything (skills + MCP)

param(
    [string]$ProjectDir = ".",
    [switch]$InstallSkills,
    [switch]$BuildMcp,
    [switch]$Full
)

# Handle -Full flag
if ($Full) {
    $InstallSkills = $true
    $BuildMcp = $true
}

# Determine script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateDir = Join-Path $ScriptDir "templates"
$SkillsDir = Join-Path $ScriptDir "skills"
$McpDir = Join-Path $ScriptDir "mcp-server"

# Resolve project directory
$ProjectDir = Resolve-Path $ProjectDir -ErrorAction SilentlyContinue
if (-not $ProjectDir) { $ProjectDir = Get-Location }

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           Claude Memory System Setup                         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project directory: $ProjectDir"
Write-Host ""

# =============================================================================
# PHASE 1: Project Setup (memory directories and templates)
# =============================================================================

Write-Host "Phase 1: Setting up project memory structure..." -ForegroundColor White
Write-Host ""

# Create directory structure
Write-Host "  Creating directories..."
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
    }
}

# Function to copy template only if destination doesn't exist or is still a template
function Copy-IfTemplate {
    param(
        [string]$Source,
        [string]$Dest,
        [string]$Name
    )

    if (-not (Test-Path $Dest)) {
        Copy-Item -Path $Source -Destination $Dest -Force
        Write-Host "    Created: $Name" -ForegroundColor Green
    } elseif ((Get-Content $Dest -Raw) -match '\[DATE\]|\[NAME\]|\[Brief description\]') {
        # File exists but is still a template, overwrite
        Copy-Item -Path $Source -Destination $Dest -Force
        Write-Host "    Updated: $Name (was still a template)" -ForegroundColor Yellow
    } else {
        Write-Host "    Skipped: $Name (already has content)" -ForegroundColor DarkGray
    }
}

# Copy template files
Write-Host "  Copying templates..."

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
        Copy-IfTemplate -Source $sourcePath -Dest $destPath -Name $fileMappings[$source]
    }
}

# Create .gitkeep files
Write-Host "  Creating .gitkeep files..."
$gitkeepDirs = @(
    @{ Path = ".claude\memory\sessions"; Content = "# Session summaries stored here" }
    @{ Path = ".claude\memory\decisions"; Content = "# Decision records stored here" }
    @{ Path = ".claude\memory\knowledge"; Content = "# Domain knowledge files stored here" }
)

foreach ($item in $gitkeepDirs) {
    $gitkeepPath = Join-Path $ProjectDir "$($item.Path)\.gitkeep"
    $item.Content | Out-File -FilePath $gitkeepPath -Encoding utf8 -Force
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
            Write-Host "  Skipped: CLAUDE.md (memory section already exists)" -ForegroundColor DarkGray
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
Write-Host "  ✓ Phase 1 complete: Project memory structure ready" -ForegroundColor Green
Write-Host ""

# =============================================================================
# PHASE 2: Install Skills (slash commands)
# =============================================================================

$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"

if ($InstallSkills) {
    Write-Host "Phase 2: Installing slash commands..." -ForegroundColor White
    Write-Host ""

    if (-not (Test-Path $ClaudeSkillsDir)) {
        New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
    }

    $skillFiles = Get-ChildItem -Path $SkillsDir -Filter "*.md" -ErrorAction SilentlyContinue
    foreach ($skill in $skillFiles) {
        Copy-Item -Path $skill.FullName -Destination $ClaudeSkillsDir -Force
        Write-Host "  Installed: $($skill.Name)" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  ✓ Phase 2 complete: Slash commands installed" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Phase 2: Skipped (use -InstallSkills to install slash commands)" -ForegroundColor DarkGray
    Write-Host ""
}

# =============================================================================
# PHASE 3: Build MCP Server
# =============================================================================

if ($BuildMcp) {
    Write-Host "Phase 3: Building MCP server..." -ForegroundColor White
    Write-Host ""

    $nodeExists = Get-Command node -ErrorAction SilentlyContinue
    $npmExists = Get-Command npm -ErrorAction SilentlyContinue

    if ($nodeExists -and $npmExists) {
        Push-Location $McpDir

        if (-not (Test-Path "node_modules")) {
            Write-Host "  Installing dependencies..."
            npm install --silent 2>$null
        }

        Write-Host "  Building TypeScript..."
        npm run build --silent 2>$null

        Pop-Location

        Write-Host ""
        Write-Host "  ✓ Phase 3 complete: MCP server built" -ForegroundColor Green
        Write-Host ""
        Write-Host "  To use the MCP server, add to your Claude settings:" -ForegroundColor White
        Write-Host "  {" -ForegroundColor Gray
        Write-Host "    `"mcpServers`": {" -ForegroundColor Gray
        Write-Host "      `"claude-memory`": {" -ForegroundColor Gray
        Write-Host "        `"command`": `"node`"," -ForegroundColor Gray
        Write-Host "        `"args`": [`"$McpDir\dist\index.js`"]," -ForegroundColor Gray
        Write-Host "        `"env`": { `"MEMORY_PROJECT_ROOT`": `"`${workspaceFolder}`" }" -ForegroundColor Gray
        Write-Host "      }" -ForegroundColor Gray
        Write-Host "    }" -ForegroundColor Gray
        Write-Host "  }" -ForegroundColor Gray
        Write-Host ""
    } else {
        Write-Host "  ⚠ Node.js not found. Skipping MCP server build." -ForegroundColor Yellow
        Write-Host "  Install Node.js and run: cd $McpDir; npm install; npm run build" -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "Phase 3: Skipped (use -BuildMcp to build MCP server)" -ForegroundColor DarkGray
    Write-Host ""
}

# =============================================================================
# Summary
# =============================================================================

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    Setup Complete!                           ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Project files created:" -ForegroundColor White
Write-Host "  .claude/memory/ARCHITECTURE.md    - System documentation"
Write-Host "  .claude/memory/USAGE.md           - Usage guide"
Write-Host "  .claude/memory/current_context.md - Session handoff"
Write-Host "  .claude/plans/active_plan.md      - Task planning"
Write-Host "  .claude/plans/findings.md         - Research notes"
Write-Host "  .claude/plans/progress.md         - Progress tracking"
Write-Host ""

if ($InstallSkills) {
    Write-Host "Slash commands installed:" -ForegroundColor White
    Write-Host "  /memory-start   - Load context at session start"
    Write-Host "  /memory-save    - Save session summary"
    Write-Host "  /memory-status  - Show memory system state"
    Write-Host "  /memory-decide  - Record a decision (ADR)"
    Write-Host ""
}

Write-Host "Quick start:" -ForegroundColor White
Write-Host "  1. Start a session with: /memory-start"
Write-Host "  2. Work on your project"
Write-Host "  3. End session with: /memory-save"
Write-Host ""

if (-not $InstallSkills) {
    Write-Host "To install slash commands, run:" -ForegroundColor Yellow
    Write-Host "  & `"$($MyInvocation.MyCommand.Path)`" -InstallSkills" -ForegroundColor Yellow
    Write-Host ""
}

if (-not $BuildMcp) {
    Write-Host "To build MCP server (for programmatic access), run:" -ForegroundColor Yellow
    Write-Host "  & `"$($MyInvocation.MyCommand.Path)`" -BuildMcp" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Full documentation: $ScriptDir\docs\" -ForegroundColor Cyan
Write-Host ""

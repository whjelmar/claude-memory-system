# validate-memory.ps1
# Validates the integrity of the memory system structure
#
# Usage: .\validate-memory.ps1 [-ProjectDir <path>]
#   -ProjectDir: Optional path to project root (default: current directory)
#
# Checks performed:
#   - Required directories exist
#   - Required files exist (ARCHITECTURE.md, USAGE.md, current_context.md)
#   - Decision numbers are sequential (warns if gaps)
#   - No empty template files (files still containing [DATE] or [NAME] placeholders)
#
# Exit codes: 0 if valid, 1 if issues found

param(
    [string]$ProjectDir = "."
)

# Resolve to absolute path
try {
    $ProjectDir = Resolve-Path $ProjectDir -ErrorAction Stop
} catch {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

$MemoryDir = Join-Path $ProjectDir ".claude\memory"
$PlansDir = Join-Path $ProjectDir ".claude\plans"

Write-Host "Validating memory system..." -ForegroundColor Cyan
Write-Host "Project directory: $ProjectDir"
Write-Host ""

# Track issues
$script:errors = 0
$script:warnings = 0

# Helper functions
function Write-ValidationError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    $script:errors++
}

function Write-ValidationWarning {
    param([string]$Message)
    Write-Host "[WARN]  $Message" -ForegroundColor Yellow
    $script:warnings++
}

function Write-ValidationOK {
    param([string]$Message)
    Write-Host "[OK]    $Message" -ForegroundColor Green
}

Write-Host "=== Directory Structure ===" -ForegroundColor White

# Check required directories
$requiredDirs = @(
    ".claude\memory",
    ".claude\memory\sessions",
    ".claude\memory\decisions",
    ".claude\memory\knowledge",
    ".claude\plans"
)

foreach ($dir in $requiredDirs) {
    $fullPath = Join-Path $ProjectDir $dir
    if (Test-Path $fullPath -PathType Container) {
        Write-ValidationOK "$dir exists"
    } else {
        Write-ValidationError "$dir does not exist"
    }
}

Write-Host ""
Write-Host "=== Required Files ===" -ForegroundColor White

# Check required files
$requiredFiles = @(
    ".claude\memory\ARCHITECTURE.md",
    ".claude\memory\USAGE.md",
    ".claude\memory\current_context.md"
)

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $ProjectDir $file
    if (Test-Path $fullPath -PathType Leaf) {
        Write-ValidationOK "$file exists"
    } else {
        Write-ValidationError "$file does not exist"
    }
}

Write-Host ""
Write-Host "=== Template Placeholders ===" -ForegroundColor White

# Check for unfilled template placeholders
$placeholderPattern = '\[DATE\]|\[NAME\]|\[Brief description\]|\[Current focus area\]|\[Immediate goals\]|\[Key variables\]|\[What issue\]'

$filesToCheck = @(
    ".claude\memory\current_context.md",
    ".claude\plans\active_plan.md",
    ".claude\plans\findings.md",
    ".claude\plans\progress.md"
)

foreach ($file in $filesToCheck) {
    $fullPath = Join-Path $ProjectDir $file
    if (Test-Path $fullPath -PathType Leaf) {
        $content = Get-Content -Path $fullPath -Raw -ErrorAction SilentlyContinue
        if ($content -match $placeholderPattern) {
            Write-ValidationWarning "$file contains unfilled template placeholders"
        } else {
            Write-ValidationOK "$file has no template placeholders"
        }
    }
}

Write-Host ""
Write-Host "=== Decision Sequence ===" -ForegroundColor White

# Check decision numbers for gaps
$DecisionsDir = Join-Path $ProjectDir ".claude\memory\decisions"

if (Test-Path $DecisionsDir -PathType Container) {
    # Collect decision numbers
    $decisionFiles = Get-ChildItem -Path $DecisionsDir -Filter "????_*.md" -File -ErrorAction SilentlyContinue

    $decisionNumbers = @()
    foreach ($file in $decisionFiles) {
        if ($file.Name -match '^(\d{4})_.*\.md$') {
            $decisionNumbers += [int]$Matches[1]
        }
    }

    # Sort numbers
    $sortedNumbers = $decisionNumbers | Sort-Object

    if ($sortedNumbers.Count -eq 0) {
        Write-ValidationOK "No decisions found (this is fine for new projects)"
    } else {
        # Check for gaps
        $expected = 1
        $gapsFound = $false

        foreach ($num in $sortedNumbers) {
            if ($num -ne $expected) {
                Write-ValidationWarning "Gap in decision sequence: expected $expected, found $num"
                $gapsFound = $true
            }
            $expected = $num + 1
        }

        if (-not $gapsFound) {
            Write-ValidationOK "Decision numbers are sequential (1-$($sortedNumbers[-1]))"
        }

        Write-Host "    Total decisions: $($sortedNumbers.Count)" -ForegroundColor Gray
    }
} else {
    Write-ValidationError "Decisions directory does not exist"
}

Write-Host ""
Write-Host "=== Empty Files Check ===" -ForegroundColor White

# Check for completely empty files (0 bytes)
$emptyFilesFound = $false

$dirsToCheck = @($MemoryDir, $PlansDir)
foreach ($dir in $dirsToCheck) {
    if (Test-Path $dir -PathType Container) {
        $mdFiles = Get-ChildItem -Path $dir -Filter "*.md" -File -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $mdFiles) {
            if ($file.Length -eq 0) {
                Write-ValidationWarning "Empty file: $($file.FullName.Replace($ProjectDir, '').TrimStart('\'))"
                $emptyFilesFound = $true
            }
        }
    }
}

if (-not $emptyFilesFound) {
    Write-ValidationOK "No empty markdown files found"
}

Write-Host ""
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "Errors:   $script:errors"
Write-Host "Warnings: $script:warnings"

if ($script:errors -gt 0) {
    Write-Host ""
    Write-Host "Status: INVALID - Fix errors before using memory system" -ForegroundColor Red
    exit 1
} elseif ($script:warnings -gt 0) {
    Write-Host ""
    Write-Host "Status: VALID with warnings - Consider addressing warnings" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host ""
    Write-Host "Status: VALID - Memory system is properly configured" -ForegroundColor Green
    exit 0
}

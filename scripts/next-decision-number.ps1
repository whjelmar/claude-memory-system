# next-decision-number.ps1
# Scans the decisions directory and outputs the next available decision number
#
# Usage: .\next-decision-number.ps1 [-ProjectDir <path>]
#   -ProjectDir: Optional path to project root (default: current directory)
#
# Output: Next decision number, zero-padded to 4 digits (e.g., "0001", "0042")
# Exit codes: 0 on success, 1 on error

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

$DecisionsDir = Join-Path $ProjectDir ".claude\memory\decisions"

# Check if decisions directory exists
if (-not (Test-Path $DecisionsDir)) {
    # No decisions directory yet, start at 0001
    Write-Output "0001"
    exit 0
}

# Find the highest existing decision number
# Decision files are named NNNN_*.md (e.g., 0001_choose_framework.md)
$highest = 0

$decisionFiles = Get-ChildItem -Path $DecisionsDir -Filter "????_*.md" -File -ErrorAction SilentlyContinue

foreach ($file in $decisionFiles) {
    # Extract the number from filename (first 4 characters before underscore)
    $filename = $file.Name
    if ($filename -match '^(\d{4})_.*\.md$') {
        $number = [int]$Matches[1]
        if ($number -gt $highest) {
            $highest = $number
        }
    }
}

# Calculate next number and zero-pad to 4 digits
$next = $highest + 1
Write-Output ("{0:D4}" -f $next)

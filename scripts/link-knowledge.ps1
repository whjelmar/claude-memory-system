# link-knowledge.ps1
# Scans knowledge files and suggests/creates cross-references
#
# Usage: .\link-knowledge.ps1 [-ProjectDir <path>] [-AutoInsert] [-DryRun]
#   -ProjectDir: Optional path to project root (default: current directory)
#   -AutoInsert: Automatically insert suggested links
#   -DryRun: Show what would be changed without making changes
#
# Behavior:
#   - Scans all files in .claude/memory/knowledge/
#   - Extracts topic names and key terms from each file
#   - Finds references to other topics within file content
#   - Suggests links like [[topic-name]] or [Topic](./topic-name.md)
#   - Optionally auto-inserts links
#
# Exit codes: 0 on success, 1 on error

param(
    [string]$ProjectDir = ".",
    [switch]$AutoInsert,
    [switch]$DryRun
)

# Resolve to absolute path
try {
    $ProjectDir = Resolve-Path $ProjectDir -ErrorAction Stop
} catch {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

$KnowledgeDir = Join-Path $ProjectDir ".claude\memory\knowledge"

Write-Host "=== Knowledge Base Linker ===" -ForegroundColor Cyan
Write-Host "Knowledge directory: $KnowledgeDir"
Write-Host ""

# Check if knowledge directory exists
if (-not (Test-Path $KnowledgeDir)) {
    Write-Error "Knowledge directory does not exist: $KnowledgeDir"
    exit 1
}

# Build a list of all topics and their filenames
$topics = @{}
$topicFiles = @{}
$topicTerms = @{}

# First pass: collect all topic names and key terms
$knowledgeFiles = Get-ChildItem -Path $KnowledgeDir -Filter "*.md" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notin @("INDEX.md", "index.md", ".gitkeep") }

foreach ($file in $knowledgeFiles) {
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $lines = $content -split "`n"

    # Get the topic name from first line
    $topic = ($lines[0] -replace '^#+\s*', '').Trim()
    if ([string]::IsNullOrWhiteSpace($topic)) {
        $topic = $file.BaseName
    }

    # Slugify the topic for matching
    $slug = $topic.ToLower() -replace '[^a-z0-9]', '-' -replace '--+', '-' -replace '^-|-$', ''

    $topics[$slug] = $topic
    $topicFiles[$slug] = $file.Name

    # Extract potential key terms (headers, bold text)
    $terms = [regex]::Matches($content, '(\*\*[^*]+\*\*|^## .+|^### .+)', 'Multiline') |
        ForEach-Object { $_.Value -replace '\*\*', '' -replace '^##+ ', '' }
    $topicTerms[$slug] = $terms -join '|'
}

Write-Host "Found $($topics.Count) knowledge topics:" -ForegroundColor Yellow
foreach ($slug in $topics.Keys) {
    Write-Host "  - $($topics[$slug]) ($($topicFiles[$slug]))"
}
Write-Host ""

# Track suggestions
$totalSuggestions = 0
$fileSuggestions = @{}

# Second pass: scan each file for references to other topics
Write-Host "Scanning for cross-references..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $knowledgeFiles) {
    $filename = $file.Name
    $currentTopicSlug = $file.BaseName.ToLower()
    $fileContent = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $fileContent) { continue }

    $suggestions = @()

    foreach ($slug in $topics.Keys) {
        # Skip self-references
        if ($slug -eq $currentTopicSlug) { continue }

        $topic = $topics[$slug]
        $targetFile = $topicFiles[$slug]

        # Create pattern for topic name
        $topicPattern = [regex]::Escape($topic)

        # Check if already linked to this topic
        $linkPattern = "\[.*\]\(\.?/?$([regex]::Escape($targetFile))\)|\[\[$slug\]\]"
        if ($fileContent -match $linkPattern) { continue }

        # Check if topic is mentioned
        if ($fileContent -match "\b$topicPattern\b") {
            # Found a mention that's not linked
            $totalSuggestions++
            $suggestions += "  - Link '$topic' -> [$topic](./$targetFile)"

            # Prepare for auto-insert
            if ($AutoInsert -and -not $DryRun) {
                # Replace first occurrence of topic with link
                $replacement = "[$topic](./$targetFile)"
                $pattern = "(?<![(\[\w])(\b$topicPattern\b)(?![)\]\w])"
                $newContent = $fileContent -replace $pattern, $replacement
                if ($newContent -ne $fileContent) {
                    $newContent | Out-File -FilePath $file.FullName -Encoding utf8 -Force
                    $fileContent = $newContent
                }
            }
        }

        # Also check for slug-based mentions (e.g., "auth-patterns" -> "Auth Patterns")
        $slugReadable = $slug -replace '-', ' '
        if ($slugReadable -ne $topic.ToLower()) {
            if ($fileContent -match "\b$([regex]::Escape($slugReadable))\b") {
                $linkPattern = "\[.*\]\(\.?/?$([regex]::Escape($targetFile))\)"
                if ($fileContent -notmatch $linkPattern) {
                    $totalSuggestions++
                    $suggestions += "  - Link '$slugReadable' -> [$topic](./$targetFile)"
                }
            }
        }
    }

    if ($suggestions.Count -gt 0) {
        $fileSuggestions[$filename] = $suggestions
        Write-Host "### $filename" -ForegroundColor Yellow
        $suggestions | ForEach-Object { Write-Host $_ }
        Write-Host ""
    }
}

# Generate link suggestions report
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total cross-reference suggestions: $totalSuggestions"
Write-Host ""

if ($totalSuggestions -eq 0) {
    Write-Host "No cross-references needed - knowledge base is well-linked!" -ForegroundColor Green
} else {
    if ($DryRun) {
        Write-Host "[DRY RUN] No changes were made." -ForegroundColor Yellow
    } elseif ($AutoInsert) {
        Write-Host "Links have been auto-inserted where possible." -ForegroundColor Green
        Write-Host "Review the changes with 'git diff'"
    } else {
        Write-Host "To auto-insert links, run with -AutoInsert" -ForegroundColor Yellow
        Write-Host "To preview changes, run with -DryRun"
    }
}

Write-Host ""
Write-Host "Link format used: [Topic Name](./topic-name.md)"
Write-Host ""

# Return object with related topics (useful for programmatic access)
$result = @{
    TotalSuggestions = $totalSuggestions
    FileSuggestions = $fileSuggestions
    Topics = $topics
    TopicFiles = $topicFiles
}

# Output related topics for each file
Write-Host "=== Related Topics by File ===" -ForegroundColor Cyan
foreach ($file in $knowledgeFiles) {
    $currentSlug = $file.BaseName.ToLower() -replace '[^a-z0-9]', '-'
    $related = @()

    foreach ($slug in $topics.Keys) {
        if ($slug -ne $currentSlug) {
            $related += $topics[$slug]
        }
    }

    Write-Host "$($file.Name): $($related -join ', ')"
}

return $result

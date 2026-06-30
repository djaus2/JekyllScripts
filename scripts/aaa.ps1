# Prompts
$repository = Read-Host "Repository (e.g. https://github.com/owner/repo or owner/repo)"
$project    = Read-Host "Project within repository (e.g. AthStitcher)"
$fileRel    = Read-Host "Relative file path under the project (e.g. MainWindow.xaml.cs or Data/ToPdf.cs)"
$tagInput   = Read-Host "Tag or method to find (e.g. ExportHeatToPdf or // TAG: ExportHeatToPdf)"

function Parse-Repo {
    param([string]$repoInput)
    if ($repoInput -match '^https?://github\.com/([^/]+)/([^/]+)') {
        return @{ Owner = $matches[1]; Repo = ($matches[2] -replace '\.git$','') }
    } elseif ($repoInput -match '^([^/]+)/([^/]+)$') {
        return @{ Owner = $matches[1]; Repo = $matches[2] }
    }
    throw "Unrecognized repository format. Use 'owner/repo' or full GitHub URL."
}

function Normalize-Path([string]$p) {
    if ([string]::IsNullOrWhiteSpace($p)) { return "" }
    $p = $p -replace '\\','/'
    $p = $p -replace '^[\/]+',''
    $p = $p -replace '[\/]+$',''
    return $p
}

function Test-UrlOk([string]$url) {
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Get -MaximumRedirection 5 -ErrorAction Stop
        return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    } catch { return $false }
}

function Resolve-Branch([string]$owner, [string]$repo, [string]$path) {
    $blobBase = "https://github.com/$owner/$repo/blob"
    foreach ($b in @('main','master')) {
        if (Test-UrlOk "$blobBase/$b/$path") { return $b }
    }
    return $null
}

# Parse and normalize inputs
$parsed   = Parse-Repo $repository
$owner    = $parsed.Owner
$repo     = $parsed.Repo
$proj     = Normalize-Path $project
$file     = Normalize-Path $fileRel
$fullPath = if ([string]::IsNullOrEmpty($proj)) { $file } else { "$proj/$file" }
if ([string]::IsNullOrEmpty($fullPath)) { throw "Combined path is empty." }

# Normalize tag input -> bare tag/method name
$tagCore = $tagInput
$tagCore = $tagCore -replace '^\s*\/{2,}\s*', ''                    # strip leading // if present
$tagCore = $tagCore -ireplace '^\s*(?:tag|anchor)\s*:\s*', ''       # strip 'tag:' or 'anchor:'
$tagCore = $tagCore -ireplace '^\s*ANCHOR\[\s*(.*?)\s*\]\s*$', '$1' # extract from ANCHOR[Name]
$tagCore = $tagCore.Trim()
if ([string]::IsNullOrWhiteSpace($tagCore)) {
    Write-Host "ERROR: Tag value is empty after normalization." -ForegroundColor Red
    exit 1
}

# Resolve branch and verify file via blob
$branch = Resolve-Branch -owner $owner -repo $repo -path $fullPath
if (-not $branch) {
    Write-Host "ERROR: Could not find file at 'main' or 'master'." -ForegroundColor Red
    Write-Host "Checked: https://github.com/$owner/$repo/blob/(main|master)/$fullPath"
    exit 1
}

$repoBase = "https://github.com/$owner/$repo"
$blobUrl  = "$repoBase/blob/$branch/$fullPath"
if (-not (Test-UrlOk $blobUrl)) {
    Write-Host "ERROR: File not found: $blobUrl" -ForegroundColor Red
    exit 1
}

# Download RAW and search for tag/method
$rawUrl = "https://raw.githubusercontent.com/$owner/$repo/$branch/$fullPath"
try {
    $content = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop |
               Select-Object -ExpandProperty Content
} catch {
    Write-Host "ERROR: Failed to download raw content: $rawUrl" -ForegroundColor Red
    exit 1
}

$escaped = [Regex]::Escape($tagCore)
$regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$lines = $content -split "`r?`n"

# 1) Flexible tag patterns: any slashes, optional spaces, case-insensitive
$patterns = @(
    '^\s*/+\s*tag\s*:\s*' + $escaped,             # // TAG: <name> (spaces optional)
    '^\s*/+\s*anchor\[\s*' + $escaped + '\s*\]',  # // ANCHOR[<name>]
    '^\s*///\s*tag\s*:\s*' + $escaped             # /// TAG: <name> (XML doc style)
)

$matchLine = -1
for ($i = 0; $i -lt $lines.Length; $i++) {
    foreach ($pat in $patterns) {
        if ([Regex]::IsMatch($lines[$i], $pat, $regexOptions)) {
            $matchLine = $i; break
        }
    }
    if ($matchLine -ge 0) { break }
}

# 2) Method signature: allow whitespace/newlines before '(' (Singleline)
if ($matchLine -lt 0) {
    $methodBlock = [Regex]::Match(
        $content,
        '\b' + [Regex]::Escape($tagCore) + '\s*\(',
        $regexOptions -bor [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if ($methodBlock.Success) {
        $prefix = $content.Substring(0, $methodBlock.Index)
        $lineNumberFromBlock = ($prefix -split "`r?`n").Count
        $matchLine = $lineNumberFromBlock - 1
    }
}

# 3) Loose fallback: line contains (case-insensitive)
if ($matchLine -lt 0) {
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i].IndexOf($tagCore, [System.StringComparison]::InvariantCultureIgnoreCase) -ge 0) {
            $matchLine = $i; break
        }
    }
}

# 4) Fuzzy fallback: ignore underscores/spaces
if ($matchLine -lt 0) {
    $needle = ($tagCore -replace '[_\s]', '').ToLowerInvariant()
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $compact = ($lines[$i] -replace '[_\s]', '').ToLowerInvariant()
        if ($compact -like "*$needle*(") { $matchLine = $i; break }
    }
}

# If still not found, provide constrained GitHub search link
if ($matchLine -lt 0) {
    $qRaw     = "$tagCore path:$fullPath"
    $qEncoded = [uri]::EscapeDataString($qRaw)
    $searchUrl = "$repoBase/search?q=$qEncoded&type=code"
    try { Set-Clipboard -Value $searchUrl } catch {}
    Write-Host "NOT FOUND in file. Copied GitHub search URL instead:" -ForegroundColor Yellow
    Write-Host $searchUrl
    exit 1
}

$lineNumber     = $matchLine + 1
$blobWithAnchor = "$blobUrl#L$lineNumber"

Write-Host "SUCCESS: Found at line $lineNumber" -ForegroundColor Green
Write-Host $blobWithAnchor

try {
    Set-Clipboard -Value $blobWithAnchor
    Write-Host "Copied to clipboard." -ForegroundColor Cyan
} catch {
    Write-Host "Note: Could not copy to clipboard. URL: $blobWithAnchor"
}
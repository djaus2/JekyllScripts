# Prompts
$repository = Read-Host "Repository (e.g. https://github.com/djaus2/PhotoTimingDjaus or owner/repo)"
$project    = Read-Host "Project within repository (e.g. AthStitcher)"
$fileRel    = Read-Host "Relative file path under the project (e.g. Data/ToPdf.cs)"
$methodName = Read-Host "Method name to find (e.g. ExportHeatToPdf)"

function Parse-Repo {
    param([string]$repoInput)
    if ($repoInput -match '^https?://github\.com/([^/]+)/([^/]+)') {
        $owner = $matches[1]
        $repo  = ($matches[2] -replace '\.git$','')
        return @{ Owner = $owner; Repo = $repo }
    }
    elseif ($repoInput -match '^([^/]+)/([^/]+)$') {
        return @{ Owner = $matches[1]; Repo = $matches[2] }
    }
    throw "Unrecognized repository format. Use 'owner/repo' or full GitHub URL."
}

function Normalize-Path([string]$p) {
    if ([string]::IsNullOrWhiteSpace($p)) { return "" }
    $p = $p -replace '\\','/'          # backslashes -> forward slashes
    $p = $p -replace '^[\/]+',''       # trim leading slashes
    $p = $p -replace '[\/]+$',''       # trim trailing slashes
    return $p
}

function Test-UrlOk([string]$url) {
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Get -MaximumRedirection 5 -ErrorAction Stop
        return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    } catch {
        return $false
    }
}

function Resolve-Branch([string]$owner, [string]$repo, [string]$path) {
    $blobBase = "https://github.com/$owner/$repo/blob"
    foreach ($b in @('main','master')) {
        if (Test-UrlOk "$blobBase/$b/$path") { return $b }
    }
    return $null
}

# Parse and normalize
$parsed = Parse-Repo $repository
$owner  = $parsed.Owner
$repo   = $parsed.Repo

$proj   = Normalize-Path $project
$file   = Normalize-Path $fileRel
$fullPath = if ([string]::IsNullOrEmpty($proj)) { $file } else { "$proj/$file" }

if ([string]::IsNullOrEmpty($fullPath)) { throw "Combined path is empty." }

# Resolve branch by probing blob URL
$branch = Resolve-Branch -owner $owner -repo $repo -path $fullPath
if (-not $branch) {
    Write-Host "ERROR: Could not find file at 'main' or 'master'." -ForegroundColor Red
    Write-Host "Checked: https://github.com/$owner/$repo/blob/(main|master)/$fullPath"
    exit 1
}

$blobUrl = "https://github.com/$owner/$repo/blob/$branch/$fullPath"
if (-not (Test-UrlOk $blobUrl)) {
    Write-Host "ERROR: File not found: $blobUrl" -ForegroundColor Red
    exit 1
}

# Download raw content and search for method
$rawUrl = "https://raw.githubusercontent.com/$owner/$repo/$branch/$fullPath"
try {
    $content = Invoke-WebRequest -Uri $rawUrl -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop |
               Select-Object -ExpandProperty Content
} catch {
    Write-Host "ERROR: Failed to download raw content: $rawUrl" -ForegroundColor Red
    exit 1
}

# Find method by a simple pattern 'MethodName(' and compute first matching line number
$pattern = [Regex]::Escape($methodName) + '\s*\('
$lines = $content -split "`r?`n"
$lineIndex = -1
for ($i = 0; $i -lt $lines.Length; $i++) {
    if ([Regex]::IsMatch($lines[$i], $pattern)) { $lineIndex = $i; break }
}

if ($lineIndex -lt 0) {
    Write-Host "ERROR: Method '$methodName' not found in file." -ForegroundColor Yellow
    Write-Host "File: $blobUrl"
    exit 1
}

$lineNumber = $lineIndex + 1
$blobWithAnchor = "$blobUrl#L$lineNumber"

# Optional permalink (pin to commit)
# Tip: You can press 'y' on the GitHub blob page to get a permalink. Here we stick to branch URL.

# Output results
Write-Host "SUCCESS: File found and method located." -ForegroundColor Green
Write-Host "Blob URL: $blobUrl"
Write-Host "Method anchor: $blobWithAnchor"

# Put the anchored URL on the clipboard
try {
    Set-Clipboard -Value $blobWithAnchor
    Write-Host "Copied to clipboard." -ForegroundColor Cyan
} catch {
    Write-Host "Note: Could not copy to clipboard. URL: $blobWithAnchor"
}
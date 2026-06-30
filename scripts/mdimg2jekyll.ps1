# PowerShell script to convert Markdown image syntax to Jekyll include format
# Usage: scripts\transform-image.ps1 -FileName "yourfile.md"


param(
    [Parameter(Mandatory=$true)]
    [string]$FileName
)


# Prepend _posts/ to filename and get full path from repo root
$RepoRoot = Resolve-Path "$PSScriptRoot\.." | Select-Object -ExpandProperty Path
$FullPath = Join-Path $RepoRoot "_posts\$FileName"
if (!(Test-Path $FullPath)) {
    Write-Error "File not found: $FullPath"
    exit 1
}


# Backup original file as file.md.bak
$backupPath = "$FullPath.bak"
if ($FullPath -match "\.md$") {
    $backupPath = $FullPath + ".bak"
}

# Exit if backup already exists
if (Test-Path $backupPath) {
    Write-Host "Backup file $backupPath already exists. No transformation performed."
    Write-Host "To reverse a previous transformation, delete the .md file and rename the .md.bak file to .md."
    exit 0
}

$content = Get-Content $FullPath -Raw

# Regex pattern for Markdown image
$pattern = '!\[([^\]]*)\]\(([^)]+)\)'
$replacement = '{% include image.html imagefile = "$2" tag = "$1" alt = "$1"  %}'

# Replace all Markdown images
$newContent = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, $replacement)


Copy-Item $FullPath $backupPath -Force

# Write the new content back to the file
Set-Content $FullPath $newContent

Write-Host "Conversion complete. Backup saved as $backupPath"

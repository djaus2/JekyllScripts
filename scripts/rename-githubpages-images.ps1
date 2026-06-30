# Rename image-*.png files to githubpages-image-*.png in a folder.
# Usage:
#   scripts\rename-githubpages-images.ps1 -FolderPath "media"

param(
    [Parameter(Mandatory = $false)]
    [string]$FolderPath = '_posts',

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..') -ErrorAction Stop | Select-Object -ExpandProperty Path

if ([string]::IsNullOrWhiteSpace($FolderPath)) {
    $resolvedFolder = $RepoRoot
}
elseif ([System.IO.Path]::IsPathRooted($FolderPath)) {
    $resolvedFolder = Resolve-Path $FolderPath -ErrorAction Stop | Select-Object -ExpandProperty Path
}
else {
    $resolvedFolder = Resolve-Path (Join-Path $RepoRoot $FolderPath) -ErrorAction Stop | Select-Object -ExpandProperty Path
}

$files = Get-ChildItem -Path $resolvedFolder -File -Filter 'image-*.png' |
    Sort-Object Name

if (-not $files) {
    Write-Host "No files matching image-*.png were found in $resolvedFolder"
    exit 0
}

foreach ($file in $files) {
    $newName = 'githubpages-' + $file.Name
    $targetPath = Join-Path $file.DirectoryName $newName

    if (Test-Path $targetPath) {
        Write-Warning "Skipping $($file.Name): $newName already exists"
        continue
    }

    if ($WhatIf) {
        Write-Host "Would rename $($file.Name) -> $newName"
        continue
    }

    Rename-Item -Path $file.FullName -NewName $newName
    Write-Host "Renamed $($file.Name) -> $newName"
}
# SaveClipboardImage.ps1
#
# Copy image on clipboard to /media folder 
# Output Markdown syntax to reference the image
# Markdown is copied to clipboard for easy pasting
# Provides 2 formats for image reference
# - Standard Markdown
# - Resizing image macro for Jekyll site
#      - Ref [Jekyll: Rendering on a Mobile Part 1](https://davidjones.sportronics.com.au/web/Jekyll-Rendering_on_a_Mobile-rel-web.html)
# Usage:
#   .\SaveClipboardImage.ps1 [-MediaFolder <path>]

param(
    [string]$MediaFolder = "media"
)

# Ensure media folder exists
if (-not (Test-Path $MediaFolder)) {
    New-Item -ItemType Directory -Path $MediaFolder | Out-Null
}

# Get image from clipboard
Add-Type -AssemblyName System.Windows.Forms
$image = [System.Windows.Forms.Clipboard]::GetImage()

if ($null -eq $image) {
    Write-Host "❌ No image found in clipboard."
    exit
}

# Generate default filename
$defaultFileName = "image-$((Get-Date).ToString('yyyyMMdd-HHmmss')).png"

# Prompt user for filename (default shown in brackets)
$inputFileName = Read-Host "Enter filename (default: $defaultFileName)"
if ([string]::IsNullOrWhiteSpace($inputFileName)) {
    $fileName = $defaultFileName
} else {    
    # Ensure .png extension if missing
    if (-not $inputFileName.EndsWith(".png")) {
        $inputFileName += ".png"
    }
    $fileName = $inputFileName
}

$filePath = Join-Path $MediaFolder $fileName
$filePath = ".\" + $filePath 

# Save image
$image.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)

# Output Markdown syntax
$markdown = "![${fileName}](/${MediaFolder}/${fileName})"
$markdownAlt = "{% include image.html imagefile = ""/${MediaFolder}/${fileName}"" tag = ""${fileName}"" alt = ""${fileName}""  %}"
$merged = "$markdown`n$markdownAlt"
write-host ""
Write-Host  -ForegroundColor DarkMagenta  "Image saved to $filePath"
write-host ""
Write-Host -ForegroundColor Blue  "Markdown:"
Write-Host -ForegroundColor Green  $merged
Write-Host -ForegroundColor Blue "Copied to clipboard."
# $merged | Set-Clipboard
write-host ""
Write-Host -ForegroundColor Red "Paste Markdown from clipboard."
Write-Host -ForegroundColor Red "Make sure that the tag is unique for the page."
write-host ""

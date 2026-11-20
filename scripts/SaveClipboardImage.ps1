# SaveClipboardImage.ps1
#
# Copy image on clipboard to /media folder 
# Prompt for the saved image width, preserving its aspect ratio
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

# Prompt for a positive width, defaulting to the original width
do {
    $inputWidth = Read-Host "Enter image width in pixels (default: $($image.Width))"
    if ([string]::IsNullOrWhiteSpace($inputWidth)) {
        $width = $image.Width
        $validWidth = $true
    } else {
        $width = 0
        $validWidth = [int]::TryParse($inputWidth, [ref]$width) -and $width -gt 0
        if (-not $validWidth) {
            Write-Host "Please enter a positive whole number for the width."
        }
    }
} while (-not $validWidth)

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

# Resize only when needed, preserving the original aspect ratio
$resizedImage = $null
try {
    $imageToSave = $image
    if ($width -ne $image.Width) {
        $height = [Math]::Max(1, [Math]::Round([double]$image.Height * $width / $image.Width))
        if ($height -gt [int]::MaxValue) {
            throw "The requested width produces an image height that is too large."
        }
        $resizedImage = [System.Drawing.Bitmap]::new($width, [int]$height)
        $graphics = [System.Drawing.Graphics]::FromImage($resizedImage)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($image, 0, 0, $width, [int]$height)
        } finally {
            $graphics.Dispose()
        }
        $imageToSave = $resizedImage
    }

    $baseFileName = $fileName.Substring(0, $fileName.Length - 4)
    $suffixes = $null
    $suffixIndex = 0
    while ($true) {
        $filePath = Join-Path $MediaFolder $fileName
        $savePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($filePath)
        try {
            $stream = [System.IO.File]::Open($savePath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
            break
        } catch [System.IO.IOException] {
            if (-not (Test-Path -LiteralPath $filePath)) {
                throw
            }
            if ($null -eq $suffixes) {
                $suffixes = @(0..9999 | Get-Random -Count 10000)
            }
            if ($suffixIndex -ge $suffixes.Count) {
                throw "No available four-digit suffix for '$baseFileName.png'."
            }
            $fileName = "{0}-{1:D4}.png" -f $baseFileName, $suffixes[$suffixIndex++]
        }
    }
    try {
        $imageToSave.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $stream.Dispose()
    }
} finally {
    if ($null -ne $resizedImage) {
        $resizedImage.Dispose()
    }
    $image.Dispose()
}

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

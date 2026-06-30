Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check clipboard for image
if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
    Write-Host "Clipboard does not contain an image."
    exit
}

# Prompt user
$name = Read-Host "Enter image name (no extension)"
$widthInput = Read-Host "Enter width in pixels (e.g. 800)"
$width = 0

if (-not [int]::TryParse($widthInput, [ref]$width) -or $width -le 0) {
    $width = 800
}

# Get image from clipboard
$image = [System.Windows.Forms.Clipboard]::GetImage()

# Calculate new size
$ratio = $width / $image.Width
$newHeight = [Math]::Max(1, [int][Math]::Round($image.Height * $ratio))

write-Host $image.Width
write-host $image.Height
Write-Host "Resizing image to ${width}x${newHeight} pixels..."



# Resize image
$bitmap = New-Object System.Drawing.Bitmap($width, $newHeight)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.DrawImage($image, 0, 0, $width, $newHeight)

# Ensure /media exists
$mediaPath = Join-Path (Get-Location) "media"
if (-not (Test-Path $mediaPath)) {
    New-Item -ItemType Directory -Path $mediaPath | Out-Null
}

# Save image
$timestamp = Get-Date -Format "HHmmssddMMyy"
$fileName = "${name}_${timestamp}.png"
$filePath = Join-Path $mediaPath $fileName
$bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()

# Create markdown
$altText = $name
$markdown = "![${altText}](/media/${fileName})"

# Put markdown into clipboard
[System.Windows.Forms.Clipboard]::SetText($markdown)

Write-Host "Saved to $filePath"
Write-Host "Markdown copied to clipboard:"
Write-Host $markdown
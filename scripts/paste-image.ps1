param(
    [string]$imageFolder = "media"
)

$imageFolder = $imageFolder.Trim([char]'/', [char]'\')
if ([string]::IsNullOrWhiteSpace($imageFolder)) {
    $imageFolder = "media"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check clipboard for image
if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
    $esc = [char]27
    $alertStyle = "${esc}[33;41m"
    $resetStyle = "${esc}[0m"

    Write-Host ("{0}Clipboard is empty or does not contain an image.{1}" -f $alertStyle, $resetStyle)
    Write-Host "Usage: scripts/paste-image.ps1 [-imageFolder media]" -ForegroundColor Cyan
    Write-Host "Example: scripts/paste-image.ps1 -imageFolder pics" -ForegroundColor Cyan
    Write-Host "Hint: Copy an image first (Snipping Tool or Print Screen), then run the script." -ForegroundColor DarkCyan
    Write-Host "Note: Uses image.html in /_includes to generate responsive image markup." -ForegroundColor DarkCyan
    
    Write-Host ("{0}About:{1}" -f $alertStyle, $resetStyle)
    Write-Host "  - Places Jekyll/Liquid image markup onto the clipboard."
    Write-Host "  - Prompts for image name and width."
    Write-Host (("  - Saves the image to /{0} with a timestamped filename." -f $imageFolder))
    Write-Host "  - Generated Liquid supports responsive display on smaller screens."

    Write-Host ("{0}Sample Output:{1}" -f $alertStyle, $resetStyle)
    $sampleStyle = "${esc}[1;34m"
    $sampleOutput = @"
scripts/paste-image.ps1
Enter image name (no extension): deleteme
Enter width in pixels (e.g. 800): 400
790
720
Resizing image to 400x365 pixels...
Markdown: ![deleteme](/media/deleteme_143618010726.png)
HTML: <image src="/media/deleteme_143618010726.png" alt="deleteme" width="400" />
Saved to \media\deleteme_143618010726.png
Liquid Markdown copied to clipboard:
{% include image.html imagefile = "/media/deleteme_143618010726.png" tag = "deleteme_143618010726" alt = "deleteme" %}
"@
    Write-Host ("{0}{1}{2}" -f $sampleStyle, $sampleOutput, $resetStyle)
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
$targetFolderPath = Join-Path (Get-Location) $imageFolder
if (-not (Test-Path $targetFolderPath)) {
    New-Item -ItemType Directory -Path $targetFolderPath | Out-Null
}

# Save image
$timestamp = Get-Date -Format "HHmmssddMMyy"
$fileName = "${name}_${timestamp}.png"
$filePath = Join-Path $targetFolderPath $fileName
$bitmap.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()

# Create markdown
$imageFile = "/$imageFolder/$fileName"
$altText = $name
$tag = "${name}_${timestamp}"
$alt = $altText
$markdown = "![${altText}]($imageFile)"
Write-Host $markdown

$markdown = '<image src="{0}" alt="{1}" width="{2}" />' -f $imageFile, $altText, $width
Write-Host $markdown

$markdown = '{{% include image.html imagefile = "{0}" tag = "{1}" alt = "{2}" %}}' -f $imageFile, $tag, $alt

# Put markdown into clipboard
[System.Windows.Forms.Clipboard]::SetText($markdown)

Write-Host "Saved to $filePath"
Write-Host "Markdown copied to clipboard:"
Write-Host $markdown
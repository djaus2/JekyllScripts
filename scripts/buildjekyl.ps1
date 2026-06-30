param(
    [switch]$B,    # Build Jekyll
    [switch]$I,    # Copy index.html
    [switch]$II,   # Not Copy index.html if $C is set
    [string]$C,    # Built blog post's category Copy all
    [switch]$N,    # NoOverwrite of existing files
    [switch]$K,    # Don't do cat folder
    [switch]$T,     # Don't do tags folder
    [switch]$L,     # Get latest Calendar
    [string]$FF,    # Single file to copy File Foldername only Copy from built _site
    [string]$FL,    # Single file to copy File Foldername only Copy from source
    [string]$FN,     # Single file to copy File Filename only
    [switch]$U,       # Back latest post as .bak
    [switch]$CU      # Clear all .bak

)

Write-Host "Build B: $B, Backup latest post U: $U, Category Folder C: $C, N: $N , Copy cats folder K: $K, Copy tags folder TT: $T, II: $II, File: $FN, Folder: $FF"
#y Note need to escape the $ in the $web variable with a tick!
$target =  "`$web/$C"
write-host "C Target: $target"

# Examples of usage:
# NB: root index.html is copied to the $web container for each
# Just build
# .\scripts\buildjekyl.ps1 -B 
# Just Backup last post
# .\scripts\buildjekyl.ps1 -U
#  Delete all backup files, with confirmation prompt
# .\scripts\buildjekyl.ps1 -CU
# Just build and upload blob(category) folder as well an index.html, cats and tags folder
# .\scripts\buildjekyl.ps1 -B -C "blog" 
# Just build and upload blob(category) folder. Use if just updating a blob in the category folder
# .\scripts\buildjekyl.ps1 -B -C "appdev"  -K -T -II
# Just uploadindex.html
# .\scripts\buildjekyl.ps1 -I
# Just build and upload cats and tags folders: -C param folder doesn't exist
# .\scripts\buildjekyl.ps1 -B -C "none" 
# Update the images folder after adding or updating an image, after building the site
# .\scripts\buildjekyl.ps1 -B -C "images"  -K -T -II
# Upload calendar ONLY
# scripts/buildjekyl -L 
# Build and Upload docs.html in root 
# An index to docs folder with links to all docs pages. 
# .\scripts\buildjekyl -B -D
##############################################################################
# Just copy one specific file to the $web container into a sub folder
# .\scripts\buildjekyl  -FF 'pix' -FN 'cdndone.png'
# Uploading _site\pix\cdndone.png file to Azure Blob Storage at $web/pix
# Copy image file from its folder to the site image folder then upload from there.
# .\scripts\buildjekyl  -FF 'media' -Fl 'cdndone.png'
#\#




$accountname =  "<Insert here>"
$accountkey = "<Insert here>"
$source = "_site"

$OVERWRITEFILES = "--overwrite"

if ($N) {
    $OVERWRITEFILES = ""
}


az storage blob upload-batch --overwrite  --account-name $accountname   --account-key $accountkey  --destination '$web'   --source _site

exit

if ($U) {
    
    Write-Host "Backing up latest post as .bak"
    # Find the most recently created .md file in _posts
    $postsFolder = Join-Path $PSScriptRoot "..\_posts"
    $latestFile = Get-ChildItem -Path $postsFolder -Filter *.md | Sort-Object CreationTime -Descending | Select-Object -First 1
    if ($latestFile) {
        Write-Host "Transforming images in latest post: $($latestFile.Name)"
        $transformScript = Join-Path $PSScriptRoot "transform-image.ps1"
        & $transformScript -FileName $latestFile.Name
    } else {
        Write-Host "No .md files found in _posts folder."
    }
    Write-Host "Building Jekyll"
}

if($CU)
{
    Write-Host "Clearing all .bak files in _posts folder"
    $postsFolder = Join-Path $PSScriptRoot "..\_posts"
    write-host $postsFolder
    Get-ChildItem -Path $postsFolder -Filter *.bak 
    # Count the files found
    $fileCount = (Get-ChildItem -Path $postsFolder -Filter *.bak).Count
    Write-Host "Found $fileCount .bak files to delete."
    if($fileCount -eq 0)
    {
        Write-Host "No .bak files found. Exiting."
        return
    }
    write-Host "Please confirm you wish to delete these files Y/N"
    $confirmation = Read-Host "Type Y to confirm deletion"
    if ($confirmation -eq 'Y') {
        Get-ChildItem -Path $postsFolder -Filter *.bak | Remove-Item
        Write-Host "All .bak files have been deleted."
    } else {
        Write-Host "Deletion cancelled."
    }

}

if($B)
{
    Write-Host "Building Jekyll Site"
    # Navigate to the script's directory
    # Set-Location $PSScriptRoot

    # Run Jekyll build
    bundle exec jekyll build
} 

if($L)
{
    az storage blob upload-batch --source $source\blogcalendar --destination '$web/blogcalendar' --account-name $accountname --account-key $accountkey   $OVERWRITEFILES --output table
}

if($D)
{
    az storage blob upload --file $source\docs.html --container-name '$web' --account-name $accountname  --account-key $accountkey $OVERWRITEFILES --output table
}

if($FF)
{
    if($FL)
    {
        $gsource = "$FF\$FL"
        $fsource = "$source\$FF\$FL"
        Copy-Item -Path $gsource -Destination $fsource -Force
        $target = "`$web/$FF"
        # Just do one file
        Write-Host "Uploading $fsource file to Azure Blob Storage at $target"
        az storage blob upload --file $fsource --container-name $target --account-name $accountname  --account-key $accountkey $OVERWRITEFILES --output table
    }
    elseif($FN) 
    {
        $fsource = "$source\$FF\$FN"
        $target = "`$web/$FF"
        # Just do one file
        Write-Host "Uploading $fsource file to Azure Blob Storage at $target"
        az storage blob upload --file $fsource --container-name $target --account-name $accountname  --account-key $accountkey $OVERWRITEFILES --output table
    }
}
else
{
    if($I)
    {
        # Just do index.html
        Write-Host "Uploading blog post root file index.html (ONLY) to Azure Blob Storage"
        az storage blob upload --file $source\index.html --container-name '$web' --account-name $accountname  --account-key $accountkey $OVERWRITEFILES --output table
    }
    else
    {
        if($C)
        {

            if(-not $K)
            {
                write-host "Uploading cat folder to Azure Blob Storage"
                az storage blob upload-batch --source $source\cats --destination '$web/cats' --account-name $accountname --account-key $accountkey   $OVERWRITEFILES --output table
            }
            if(-not $T)
            {   
                write-host "Uploading tags folder to Azure Blob Storage"
                write-host $source\tags
                write-host $web/tags
                az storage blob upload-batch --source $source\tags --destination '$web/tags' --account-name $accountname --account-key $accountkey   $OVERWRITEFILES --output table
            }
            if(-not $II)
            {
                Write-Host "Uploading blog post root index.html to Azure Blob Storage"
                az storage blob upload --file $source\index.html --container-name '$web' --account-name $accountname  --account-key $accountkey $OVERWRITEFILES --output table
            }
            if (Test-Path -Path $source\$C ) {
                write-Host "Uploading posts $C folder to Azure Blob Storage"
                az storage blob upload-batch --source $source\$C --destination $target --account-name $accountname --account-key $accountkey   $OVERWRITEFILES --output table
            } else {
                Write-Host "The folder (possibly a dummy)   $C does not exist."
            }
        }
    }
}

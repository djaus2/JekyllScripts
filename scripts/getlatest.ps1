param(
    [int]$N,   # Number of files
    [int]$D    # Days to look back
)

$accountname =  "<Insert here>"
$accountkey = "<Insert here>"
$source = "_site"
$web = '$web'
$OVERWRITEFILES = "--overwrite"

$currentFolderPath = Get-Location

$posts = Join-Path -Path $currentFolderPath.Path -ChildPath "_posts"
$site = Join-Path -Path $currentFolderPath.Path -ChildPath "_site"

$daysAgo = (Get-Date).AddDays(-$D)

cls
write-host "Posts folder: " $posts
write-host "Site folder: " $site
write-host "Max Number of files to get: " $N
write-host "Days to look back: " $D

write-host "Files from: " $daysAgo
write-host "===================================================="
write-host ""

if (-not (Test-Path -Path $posts)) {
    Write-Host "The folder does not exist:" $posts
    return
}

if (-not (Test-Path -Path $site)) {
    Write-Host "The folder does not exist:" $site
    return
}


$latestFiles = Get-ChildItem -Path $posts -Recurse |
               Sort-Object -Property LastWriteTime -Descending |
               Select-Object -First $N

if ($latestFiles) 
{
    $count = 0
    foreach ($post in $latestFiles) 
	{
 
        write-host ""
        # write-host "File:" $post.FullName
        if ($post.LastWriteTime -gt $daysAgo)
        {
            $count++
            write-host $count". " -NoNewLine
            Write-Host "Date of file:"  $post.LastWriteTime

            $postBase = $post.BaseName
            $postBase = $postBase.Substring(11) # Remove the date at start of name)
            $postTrunc = $postBase.Split(" ")[0]
            # write-host "Post base: " $postTrunc

            # Find the corresponding file in the _site directory
            $file = Get-ChildItem -Path $site -Recurse |
              Where-Object { $_.Name -like "*$postTrunc*" } |
              Select-Object -First 1

            if ($file -eq $null) {
                Write-Host "File not found in _site directory." $post
                continue
            }
            $relativePath = $file.FullName.Substring($site.Length + 1)
            $splitString = $relativePath  -split '\\'
            write-host "Rel path:" $relativePath
            $cat= $splitString[0]
            $filename = $splitString[1]
            # Example operation: display the file's last modification time
            Write-Host "cat: " $cat -NoNewLine
            Write-Host "  file:" $filename

            $FF = $cat
            $FN = $filename
            if($FF)
            {
                if($FN)
                {
                    $fsource = "$source\$FF\$FN"
                    $target = "`$web/$FF"
                    # Just do one file
                    Write-Host "Uploading $fsource file to Azure Blob Storage at $target"
                    az storage blob upload --file $fsource --container-name $target --account-name $accountname  --account-key $accountkey $OVERWRITEFILES --output table
                }
            }
        }
    }
}
else 
{
    Write-Host "No files found in the specified directory."
}
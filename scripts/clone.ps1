$filenameIn = Get-ChildItem .\_posts | Out-GridView -Title 'Choose a file'  -OutputMode Single | ForEach-Object { $_.FullName }
$infrontmatter = $false
foreach($line in Get-Content $filenameIn) 
{
	if($line -match '---')
    {
		
		if($infrontmatter)
        {
			break
        }
		else
        {
		  $infrontmatter=$true	
        }
    }
	else
	{
		if($infrontmatter)
        {
            $parts = $line -split ':'
            switch ($parts[0])
            {
             "title" {$title = $parts[1].Trim()}
             "subtitle" {$subtitle = $parts[1].Trim()}
             "category" {$category = $parts[1].Trim()}
             "tags" {$tags = $parts[1].Trim()}
             "author" {$author = $parts[1].Trim()}
            }
        }
	}
}
Write-Host "Title: $title"
$prompt = "Enter SubTitle ($subtitle)"
$subtitle = Read-Host $prompt

$createDate=(Get-Date).ToString("yyyy-MM-dd")
$createTime=(Get-Date).ToString("HH:mm:ss")
$filename = $createDate + '-' +  $title +  '-' +  $subtitle +  '-' +  $category + ".md"
$filename = '.\_posts\' + $filename

Write-Output $filename
New-Item $filename

$infrontmatter = $false

foreach($line in Get-Content $filenameIn) 
{
	if($line -match '---')
    {
		
		if($infrontmatter)
        {
            Add-Content $filename $line
			break
        }
		else
        {
          Set-Content $filename $line
		  $infrontmatter=$true	
        }
    }
	else
	{
		if($infrontmatter)
        {
            if( $line -like "subtitle:*")
            {
                If (![string]::IsNullOrEmpty($subtitle))
                {
                  $line = 'subtitle: ' + $subtitle
                  Add-Content $filename  $line
                }
            }
            elseif( $line -like "date:*")
            {
                $line = 'date: ' + $createDate + ' ' + $createTime
                Add-Content $filename  $line
            }
            else
            {
                Add-Content $filename $line
            }
        }
	}
}
Add-Content $filename ''
Add-Content $filename '_Insert summary here_'
Add-Content $filename '<!--more-->'
Add-Content $filename ''

Get-Content $filename

code $filename


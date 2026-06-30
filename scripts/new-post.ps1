param (
  [Parameter(Mandatory)]
    [string]$title, 
  [Parameter(Mandatory)]
    [string]$subtitle,
  [Parameter(Mandatory)]
    [string]$cat, 
  [Parameter(Mandatory)]
    [string]$tags,
    [string]$author = 'david_jones',
    [string]$disqus = '1'
)

$cat=$cat.ToLower()
$tags=$tags.ToLower()

# Assumes run from root of Jekyll project
$sections = $pwd.Path + '\_data\sections.yml'
if ( Test-Path $sections ) 
{ 

  $titlex = $title.Replace( ' ', '_')

  # Use a single character if no subtitle
  $subtitlex  = $subtitle.Replace( ' ', '_')
  If ($subtitle.Length -lt 2)
  {
    $subtitlex = '';
    $subtitle  = '';
  }



  $createDate=(Get-Date).ToString("yyyy-MM-dd")
  $createTime=(Get-Date).ToString("HH:mm:ss")

  If ([string]::IsNullOrEmpty($subtitle))
  {
    $filename = $createDate + '-' +  $titlex +  '-' +  $cat + ".md"
  }
  Else
  {
    
    $filename = $createDate + '-' +  $titlex +  '-' +  $subtitlex +  '-' +  $cat + ".md"
  }

  $filename = '.\_Posts\' + $filename

  Write-Output $filename
  New-Item $filename
  Set-Content $filename '---'
  Add-Content $filename 'layout: postpage'

  $line = 'title: ' + $title
  Add-Content $filename  $line

  If (![string]::IsNullOrEmpty($subtitle))
  {
    $line = 'subtitle: ' + $subtitle
    Add-Content $filename  $line
  }

  $line = 'category: ' + $cat
  Add-Content $filename  $line

  $line = 'tags: ' + $tags
  Add-Content $filename  $line

  $line = 'date: ' + $createDate + ' ' + $createTime
  Add-Content $filename  $line

  $line = 'author: ' + $author
  Add-Content $filename  $line

  $line = 'excerpt_separator: <!--more-->'
  Add-Content $filename $line

  $line = 'disqus: ' + $disqus
  Add-Content $filename  $line

  Add-Content $filename '---'
  Add-Content $filename ''
  Add-Content $filename '_Insert summary here_'
  Add-Content $filename '<!--more-->'
  Add-Content $filename ''

  Get-Content $filename
}
else 
{
    write-Output Run from root of Jekyll Project
}


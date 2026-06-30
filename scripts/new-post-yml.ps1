# Need: Install-Module powershell-yaml
param ( 
  [Parameter(Mandatory)]
    [string]$title, 
  [Parameter(Mandatory)]
    [string]$subtitle, 
  [Parameter(Mandatory)]
    [string]$tags,
    [string]$author = 'david_jones',
    [string]$disqus = '1'
)

$cat=''



# Assumes run from root of Jekyll project
$sections = $pwd.Path + '\_data\sections.yml'
if ( Test-Path $sections ) 
{  
  # Ref: https://stackoverflow.com/questions/28740320/how-do-i-check-if-a-powershell-module-is-installed
  if (Get-Module -ListAvailable -Name powershell-yaml) {
      Write-Host "Module powershell-yaml exists"
  } 
  else {
      write-Host Need to run: Install-Module powershell-yaml
      exit
  }

  # Ref: http://dbadailystuff.com/a-brief-introduction-to-yaml-in-powershell
  # And: https://github.com/cloudbase/powershell-yaml
  Import-Module powershell-yaml

  [string[]]$fileContent = Get-Content $sections
  $content = ''
  foreach ($line in $fileContent) { $content = $content + "`n" + $line }
  $yaml = ConvertFrom-YAML $content
 
  write-Output ' '
  write-Output '     Select the post Category     '
  write-Output '=================================================='

  $shortNames = Foreach ($i in $yaml)
  {
     $i[0]
  }
  $longNames = Foreach ($j in $yaml)
  {
     $j[1]
  }
  For ($i=0; $i -lt $longNames.Length; $i++)
  {
    # Ref: https://devblogs.microsoft.com/scripting/understanding-powershell-and-basic-string-formatting/
    # Ref: https://social.technet.microsoft.com/wiki/contents/articles/4250.powershell-string-formatting.aspx
    [string]::Format("{0,2}: Press {0,2} to select {1}",$i,$longNames[$i] )
  }
  
  $answer = read-host "Please Make a Selection"
  [int]$selection = [int]$answer
  $selection -=
  if ($selection -lt $shortNames.Count)
  {
    $cat = $shortNames[$selection]
    $response =  [string]::Format("Categrory {0} selected." , $longNames[$selection])
    write-Host $response
  }
  else
  {
    write-Host "Invalid Category Selection"
    exit
  }

 



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


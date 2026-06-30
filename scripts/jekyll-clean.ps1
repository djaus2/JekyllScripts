bundle exec jekyll clean

# Assumes run from root of Jekyll project
$sections = $pwd.Path + '\_data\sections.yml'
if ( Test-Path $sections ) 
{ 
    $pathTags = $pwd.Path + '\tags'
    if (Test-Path $pathTags ) 
    {
        # Clear it if it exists
        Get-ChildItem $pathTags  -Include *.* -Recurse | Remove-Item
    }
    else
    {
        # Create it if it doesn't exist
        New-Item -ItemType Directory -Force -Path $pathTags
    }

    # Get cats directory
    $pathCats = $pwd.Path + '\cats'
    if (Test-Path $pathCats ) 
    {
        # Clear it if it exists
        Get-ChildItem $pathCats  -Include *.* -Recurse | Remove-Item
    }
    else
    {
        # Create it if it doesn't exist
        New-Item -ItemType Directory -Force -Path $pathCats
    }
}
else 
{
    write-Output Run from root of Jekyll Project
}

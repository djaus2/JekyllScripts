# Ref: https://searchitoperations.techtarget.com/answer/Manage-the-Windows-PATH-environment-variable-with-PowerShell
$addPath =  $pwd.Path +'\scripts'
   if (Test-Path $addPath){
        $regexAddPath = [regex]::Escape($addPath)
        $arrPath = $env:Path -split ';' | Where-Object {$_ -notMatch "^$regexAddPath\\?"}
        $env:Path = ($arrPath + $addPath) -join ';'
	    $env:Path -split ';'
    } else {
        Throw "'$addPath' is not a valid path."
    }

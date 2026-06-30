$Secret = '<Insert here>'

$Extent = 'all'

$emojiHost = 'https://djssurveyfn.azurewebsites.net'

# Optional Azure Functions key (AuthorizationLevel.Function)
$Code = '<Insert here>'


$body = @{
  action = 'reset'
  secret = $Secret
}

if ($Extent -eq 'all') {
  $body.extent = 'all'
} else {
  if (-not $Ns -or -not $Key) {
    throw "When Extent='key', you must supply -Ns and -Key."
  }
  $body.ns  = $Ns
  $body.key = $Key
}

$uri = "$emojiHost/api/emoji"
if ($Code -and $Code.Trim().Length -gt 0) {
  $enc = [System.Uri]::EscapeDataString($Code)
  $uri = "$uri?code=$enc"
}

try {
  $json = $body | ConvertTo-Json -Depth 5
  $res = Invoke-RestMethod -Method Post -Uri $uri -Body $json -ContentType 'application/json'
  $res | ConvertTo-Json -Depth 5
} catch {
  Write-Error $_
  exit 1
}
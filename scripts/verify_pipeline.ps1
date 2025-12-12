param(
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$AnonKey = $env:SUPABASE_ANON_KEY
)

if (-not $SupabaseUrl -or -not $AnonKey) {
  Write-Error "Veuillez définir SUPABASE_URL et SUPABASE_ANON_KEY dans l'environnement ou passer les paramètres."
  Write-Host "Exemple:" -ForegroundColor Yellow
  Write-Host "Set-Item Env:SUPABASE_URL 'https://<ref>.supabase.co'; Set-Item Env:SUPABASE_ANON_KEY '<anon-key>'" -ForegroundColor Yellow
  exit 1
}

# Déduire le domaine des fonctions Edge à partir de l'URL Supabase
$FunctionsUrl = $SupabaseUrl -replace '\\.supabase\\.co$', '.functions.supabase.co'

function Invoke-EdgeFunction {
  param(
    [Parameter(Mandatory=$true)][string]$Name
  )
  $uri = "$FunctionsUrl/$Name"
  Write-Host "POST $uri" -ForegroundColor DarkGray
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = "Bearer $AnonKey"; "Content-Type" = "application/json" } -Body "{}"
    return $resp
  } catch {
    Write-Warning $_.Exception.Message
    if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
      $reader = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
      $body = $reader.ReadToEnd()
      Write-Host $body
    }
    return $null
  }
}

Write-Host "Invoking update-outings..." -ForegroundColor Cyan
$update = Invoke-EdgeFunction -Name "update-outings"
if ($update) {
  Write-Host ("update-outings response: " + (ConvertTo-Json $update -Depth 8))
}

Write-Host "Invoking daily-email..." -ForegroundColor Cyan
$email = Invoke-EdgeFunction -Name "daily-email"
if ($email) {
  Write-Host ("daily-email response: " + (ConvertTo-Json $email -Depth 8))
}

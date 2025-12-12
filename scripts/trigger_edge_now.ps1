# Déclenche immédiatement update-outings puis daily-email avec clés intégrées

$SupabaseUrl = "https://joupiybyhoytfuncqmyv.supabase.co"
$AnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyNDY1OTAsImV4cCI6MjA3OTgyMjU5MH0.25s25_36ydzf12qr95A6_NkwIylc1ZbcOnb98HtGiy8"
$FunctionsUrl = $SupabaseUrl -replace '\\.supabase\\.co$', '.functions.supabase.co'

function Invoke-Edge {
  param([string]$name)
  $uri = "$FunctionsUrl/$name"
  Write-Host "POST $uri"
  $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = "Bearer $AnonKey"; "Content-Type" = "application/json" } -Body "{}" -ErrorAction Stop
  $resp | ConvertTo-Json -Depth 6
}

Write-Host "update-outings" -ForegroundColor Cyan
Invoke-Edge -name "update-outings"

Write-Host "daily-email" -ForegroundColor Cyan
Invoke-Edge -name "daily-email"
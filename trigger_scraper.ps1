$FunctionUrl = "https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/update-outings"
Write-Host "Demarrage du scraper..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $FunctionUrl -Method POST -TimeoutSec 120 -UseBasicParsing
    $json = $response.Content | ConvertFrom-Json
    
    Write-Host "Succes! Statistiques:" -ForegroundColor Green
    Write-Host "  Total: $($json.total_events)" -ForegroundColor White
    Write-Host "  Inseres: $($json.inserted_count)" -ForegroundColor White
}
catch {
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test direct de l'endpoint update-outings
$ProjectUrl = "https://joupiybyhoytfuncqmyv.supabase.co"
$FunctionUrl = "$ProjectUrl/functions/v1/update-outings"
$AnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI1OTcyMDUsImV4cCI6MjA0ODE3MzIwNX0.5pTngKAFj1dQPR_8K5lqD2kLq5a_YvqE6d4JK3GbQyA"

Write-Host "Appel de l'endpoint:" $FunctionUrl -ForegroundColor Cyan
Write-Host "Avec Authorization Header..." -ForegroundColor Yellow

try {
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $AnonKey"
    }
    
    $response = Invoke-WebRequest -Uri $FunctionUrl `
        -Method POST `
        -Headers $headers `
        -TimeoutSec 180 `
        -UseBasicParsing 2>&1
    
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    
    if ($response.Content) {
        Write-Host "Response content type:" $response.Headers["Content-Type"]
        Write-Host ""
        Write-Host "Response (JSON):" -ForegroundColor Cyan
        $json = $response.Content | ConvertFrom-Json
        Write-Host ($json | ConvertTo-Json -Depth 2) -ForegroundColor White
    }
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Tentative avec authentification locale..." -ForegroundColor Yellow
    
    # Essayer sans headers
    try {
        $response2 = Invoke-WebRequest -Uri $FunctionUrl `
            -Method POST `
            -TimeoutSec 180 `
            -UseBasicParsing 2>&1
        
        Write-Host "Status (no auth): $($response2.StatusCode)"
        Write-Host "Response length: $($response2.Content.Length)"
    }
    catch {
        Write-Host "ERROR (no auth): $_" -ForegroundColor Red
    }
}

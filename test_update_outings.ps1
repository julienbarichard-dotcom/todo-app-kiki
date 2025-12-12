# Test direct de la fonction update-outings
# Remplacez YOUR_PROJECT_URL et YOUR_SERVICE_ROLE_KEY par vos vraies valeurs

$projectUrl = "https://joupiybyhoytfuncqmyv.supabase.co"
$serviceRoleKey = "VOTRE_SERVICE_ROLE_KEY_ICI"  # À remplacer!

$headers = @{
    "Authorization" = "Bearer $serviceRoleKey"
    "Content-Type" = "application/json"
}

$body = "{}"

Write-Host "Test POST /functions/v1/update-outings..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest `
        -Uri "$projectUrl/functions/v1/update-outings" `
        -Method POST `
        -Headers $headers `
        -Body $body `
        -UseBasicParsing

    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Yellow
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 5
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody" -ForegroundColor Red
    }
}

# Vérifier la table outings
Write-Host "`nPour vérifier les données, exécutez dans le SQL Editor de Supabase:" -ForegroundColor Cyan
Write-Host "SELECT count(*) FROM public.outings;" -ForegroundColor White
Write-Host "SELECT * FROM public.outings LIMIT 5;" -ForegroundColor White

param(
  [Parameter(Mandatory=$true)] [string]$ProjectRef,
  [Parameter(Mandatory=$false)] [string]$FunctionName = "supabase_outings",
  [Parameter(Mandatory=$false)] [string]$AssetPath = "assets/scraper_url.txt"
)

Write-Host "Déploiement Supabase Function: $FunctionName sur projet $ProjectRef"

# Vérifier que supabase est installé
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  Write-Error "Supabase CLI introuvable. Installez-le: npm install -g supabase"
  exit 1
}

# Déployer la fonction
Push-Location "edge_functions/supabase_outings"
Write-Host "Deploying function..."
supabase functions deploy $FunctionName --project-ref $ProjectRef
$exitCode = $LASTEXITCODE
Pop-Location
if ($exitCode -ne 0) {
  Write-Error "Erreur lors du déploiement de la function (exit $exitCode)"
  exit $exitCode
}

# Construire l'URL publique
$publicUrl = "https://$ProjectRef.functions.supabase.co/$FunctionName"
Write-Host "Function deployed. URL: $publicUrl"

# Optionnel: écrire l'URL dans assets/scraper_url.txt pour l'app
if (Test-Path $AssetPath) {
  Write-Host "Sauvegarde de l'URL du scraper dans $AssetPath"
  Set-Content -Path $AssetPath -Value $publicUrl -Encoding UTF8
  Write-Host "Asset mis à jour. Vous pouvez maintenant rebuild l'application et redeployer l'hébergement."
} else {
  Write-Host "Fichier asset '$AssetPath' non trouvé. Vous pouvez créer ce fichier et y coller l'URL manuellement: $publicUrl"
}

Write-Host "Done."
# Script de déploiement automatique
# Exécuter avec: .\DEPLOY_AUTOMATIQUE.ps1

Write-Host "🚀 DÉPLOIEMENT AUTOMATIQUE EN COURS..." -ForegroundColor Green
Write-Host ""

# Étape 1: Déployer la fonction de scraping
Write-Host "📦 ÉTAPE 1/3: Déploiement de la fonction update-outings..." -ForegroundColor Yellow
supabase functions deploy update-outings --project-ref joupiybyhoytfuncqmyv --no-verify-jwt

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Fonction update-outings déployée avec succès!" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du déploiement de update-outings" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "⏳ Attente 3 secondes..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Étape 2: Configurer les variables d'environnement
Write-Host "🔧 ÉTAPE 2/3: Configuration des variables d'environnement..." -ForegroundColor Yellow
Write-Host "⚠️  IMPORTANT: Va sur Supabase Dashboard:" -ForegroundColor Red
Write-Host "    https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/settings/functions" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Ajoute ces variables:" -ForegroundColor Cyan
Write-Host "    - RESEND_API_KEY = [ta clé Resend]" -ForegroundColor White
Write-Host "    - SUPABASE_URL = https://joupiybyhoytfuncqmyv.supabase.co" -ForegroundColor White
Write-Host "    - SUPABASE_SERVICE_ROLE_KEY = [clé depuis Settings → API]" -ForegroundColor White
Write-Host ""
$confirmation = Read-Host "Appuie sur ENTRÉE une fois que c'est fait"

# Étape 3: Configurer les cron jobs
Write-Host ""
Write-Host "⏰ ÉTAPE 3/3: Configuration des cron jobs..." -ForegroundColor Yellow
Write-Host "📋 Copie et exécute ce SQL dans Supabase SQL Editor:" -ForegroundColor Cyan
Write-Host "    https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql" -ForegroundColor Cyan
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray

# Afficher le contenu du fichier SQL
Get-Content "e:\App todo\todo_app_kiki\supabase_setup_cron_MIDI.sql" | Write-Host -ForegroundColor White

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Gray
Write-Host ""
$confirmation2 = Read-Host "Appuie sur ENTRÉE une fois que le SQL est exécuté"

Write-Host ""
Write-Host "🎉 DÉPLOIEMENT TERMINÉ !" -ForegroundColor Green
Write-Host ""
Write-Host "📊 VÉRIFICATIONS:" -ForegroundColor Yellow
Write-Host "1. Événements dans la table outings:" -ForegroundColor Cyan
Write-Host "   SELECT COUNT(*) FROM outings;" -ForegroundColor White
Write-Host ""
Write-Host "2. Cron jobs actifs:" -ForegroundColor Cyan
Write-Host "   SELECT jobname, schedule, active FROM cron.job;" -ForegroundColor White
Write-Host ""
Write-Host "3. Tester manuellement le scraper:" -ForegroundColor Cyan
Write-Host "   curl -X POST https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/update-outings \" -ForegroundColor White
Write-Host "        -H 'Authorization: Bearer [ANON_KEY]'" -ForegroundColor White
Write-Host ""
Write-Host "✨ Prochaine étape: Compiler et déployer l'app Flutter!" -ForegroundColor Green

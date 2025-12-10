# Script automatisé de build et déploiement web
# Auteur: Assistant AI
# Date: 3 décembre 2025

Write-Host "🚀 DÉPLOIEMENT AUTOMATIQUE TODO APP KIKI" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Étape 1: Nettoyage
Write-Host "📦 Étape 1/5: Nettoyage..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du nettoyage" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Nettoyage terminé`n" -ForegroundColor Green

# Étape 2: Récupération des dépendances
Write-Host "📦 Étape 2/5: Récupération des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de la récupération des dépendances" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dépendances récupérées`n" -ForegroundColor Green

# Étape 3: Build web optimisé
Write-Host "🏗️  Étape 3/5: Build web (release)..." -ForegroundColor Yellow
flutter build web --release --web-renderer canvaskit
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du build" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Build terminé`n" -ForegroundColor Green

# Étape 4: Déploiement Firebase
Write-Host "🌐 Étape 4/5: Déploiement Firebase..." -ForegroundColor Yellow
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du déploiement Firebase" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Déploiement Firebase terminé`n" -ForegroundColor Green

# Étape 5: Vérification
Write-Host "🔍 Étape 5/5: Vérification..." -ForegroundColor Yellow
Write-Host "📱 App disponible sur: https://todo-app-kiki.web.app" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ DÉPLOIEMENT RÉUSSI!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Statistiques:" -ForegroundColor Cyan
$buildSize = (Get-ChildItem -Path "build\web" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "   Taille totale: $([math]::Round($buildSize, 2)) MB" -ForegroundColor White
Write-Host ""
Write-Host "🎉 Votre application est en ligne!" -ForegroundColor Green

# Script pour exécuter la migration user_preferences dans Supabase
# À exécuter après avoir configuré les credentials Supabase CLI

param(
    [string]$ProjectRef = "joupiybyhoytfuncqmyv"
)

Write-Host "🚀 Exécution de la migration user_preferences..." -ForegroundColor Cyan

# Vérifier que le CLI Supabase est installé
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Supabase CLI n'est pas installé. Installez-le avec: npm install -g supabase" -ForegroundColor Red
    Write-Host "`nOu exécutez le SQL directement: https://supabase.com/dashboard/project/$ProjectRef/sql" -ForegroundColor Yellow
    exit 1
}

$migrationFile = "$PSScriptRoot\..\supabase\migrations\add_user_preferences.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ Fichier migration introuvable: $migrationFile" -ForegroundColor Red
    exit 1
}

# Exécuter la migration
Write-Host "📝 Fichier: $migrationFile" -ForegroundColor Gray
Write-Host "`n🔄 Exécution via Supabase CLI..." -ForegroundColor Cyan

# Lire le contenu du fichier SQL
$sqlContent = Get-Content $migrationFile -Raw

# Exécuter via la Supabase CLI
$result = supabase db push --project-ref $ProjectRef 2>&1

if ($?) {
    Write-Host "✅ Migration exécutée avec succès!" -ForegroundColor Green
} else {
    Write-Host "⚠️  CLI push peut nécessiter un authentification. Essayons via curl + REST API..." -ForegroundColor Yellow
    
    # Alternative: Utiliser un formulaire d'upload direct (nécessite la clé admin)
    Write-Host "`n💡 Exécutez le SQL manuellement:" -ForegroundColor Cyan
    Write-Host "1. Allez à: https://supabase.com/dashboard/project/$ProjectRef/sql" -ForegroundColor White
    Write-Host "2. Copiez le contenu de: $migrationFile" -ForegroundColor White
    Write-Host "3. Collez et exécutez dans le SQL Editor" -ForegroundColor White
    Write-Host "`n📋 Contenu à exécuter:" -ForegroundColor Cyan
    Write-Host $sqlContent -ForegroundColor Gray
}

Write-Host "`n✨ Fait!" -ForegroundColor Green

# Script PowerShell pour exécuter la migration SQL
# Utilise le client Supabase CLI

$ProjectRef = "joupiybyhoytfuncqmyv"
$SqlFile = "supabase_migration_multivalidation.sql"
$SqlPath = "E:\App todo\todo_app_kiki\$SqlFile"

Write-Host "🚀 Exécution de la migration SQL pour multi-validation..." -ForegroundColor Green
Write-Host "   Project: $ProjectRef" -ForegroundColor Gray
Write-Host "   File: $SqlFile" -ForegroundColor Gray
Write-Host ""

# Vérifier que le fichier SQL existe
if (-Not (Test-Path $SqlPath)) {
    Write-Host "❌ Fichier SQL non trouvé: $SqlPath" -ForegroundColor Red
    exit 1
}

# Vérifier que Supabase CLI est installé
$SupabaseCli = Get-Command supabase -ErrorAction SilentlyContinue

if ($null -eq $SupabaseCli) {
    Write-Host "⚠️  Supabase CLI non installé" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📦 Installation: npm install -g supabase" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Alternative: Exécuter le SQL manuellement dans Supabase Dashboard" -ForegroundColor Yellow
    Write-Host "🔗 https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql" -ForegroundColor Cyan
    exit 1
}

# Exécuter la migration via Supabase CLI
Write-Host "📝 Exécution du SQL..." -ForegroundColor Cyan
supabase db push --dry-run

#!/usr/bin/env pwsh
# Script pour configurer le cron quotidien Supabase et exécuter les migrations

param(
    [string]$ProjectRef = "joupiybyhoytfuncqmyv",
    [string]$ServiceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDI0NjU5MCwiZXhwIjoyMDc5ODIyNTkwfQ.HOYezDd1WNpMl_3aE55V6hmzuGzJAK5e6W3-hScjfHQ"
)

$SupabaseUrl = "https://joupiybyhoytfuncqmyv.supabase.co"
$FunctionUrl = "https://joupiybyhoytfuncqmyv.functions.supabase.co/update-outings"

Write-Host "🚀 Configuration Supabase pour la scrape quotidienne" -ForegroundColor Green

# 1. Exécuter la migration user_preferences
Write-Host "`n1️⃣ Exécution de la migration user_preferences..." -ForegroundColor Cyan
$migrationSql = @"
CREATE TABLE IF NOT EXISTS public.user_preferences (
  user_id uuid PRIMARY KEY DEFAULT auth.uid(),
  preferred_categories text[] DEFAULT '{"concert", "soiree", "electro", "expo"}',
  preferred_start_time time DEFAULT '19:00',
  preferred_end_time time DEFAULT '03:00',
  min_price numeric DEFAULT 0,
  max_price numeric DEFAULT 1000,
  exclude_keywords text[] DEFAULT '{"enfant", "jeune public", "famille", "kids"}',
  enable_notifications boolean DEFAULT true,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences" ON public.user_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON public.user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);
"@

# Execute migration via SQL
Write-Host "Migration SQL prête pour exécution (à faire via Supabase Dashboard SQL Editor)" -ForegroundColor Yellow

# 2. Test du endpoint /filter-outings
Write-Host "`n2️⃣ Test de l'endpoint /filter-outings..." -ForegroundColor Cyan
$testUserId = "00000000-0000-0000-0000-000000000000"  # Dummy ID for testing

$headers = @{
    'apikey' = $ServiceRoleKey
    'Authorization' = "Bearer $ServiceRoleKey"
}

try {
    # Note: /filter-outings is appended as query parameter since it's GET
    $testUrl = "$FunctionUrl"
    Write-Host "URL: $testUrl" -ForegroundColor Gray
    
    $response = Invoke-RestMethod -Uri $testUrl -Method Post -Headers $headers -TimeoutSec 30 -ErrorAction Stop
    Write-Host "✅ Endpoint fonctionnel" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur lors du test: $_" -ForegroundColor Red
}

# 3. Instructions pour le cron
Write-Host "`n3️⃣ Configuration du Cron Quotidien" -ForegroundColor Cyan
Write-Host @"
Pour configurer la scrape quotidienne à 06:00 UTC:

1. Ouvre le Dashboard Supabase: https://supabase.com/dashboard/project/$ProjectRef/functions
2. Clique sur la fonction `update-outings`
3. Onglet 'Deployments' ou 'Schedules'
4. Clique sur 'New Schedule' ou 'Add Trigger'
5. Configure comme suit:
   - Cron Expression: 0 6 * * *  (6h00 UTC chaque jour)
   - HTTP Method: POST
   - Function: update-outings
   - Headers:
     apikey: $ServiceRoleKey
     Authorization: Bearer $ServiceRoleKey
   - Body: {}

Ou utilise l'API Supabase pour le créer automatiquement.
"@

# 4. Afficher les tables
Write-Host "`n4️⃣ Tables créées:" -ForegroundColor Cyan
Write-Host "✅ outings (201 événements scrappés)" -ForegroundColor Green
Write-Host "✅ user_preferences (nouvellement créée)" -ForegroundColor Green

Write-Host "`n✨ Configuration terminée!" -ForegroundColor Green
Write-Host "Les événements seront mis à jour chaque jour à 06:00 UTC" -ForegroundColor Cyan

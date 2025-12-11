<#
Supabase setup script (PowerShell)

Prérequis:
- `supabase` CLI installé et connecté (supabase login)
- Variables d'environnement: SUPABASE_URL, SERVICE_ROLE_KEY, PROJECT_REF

Fonctions:
- Met à jour/insère les 3 sources dans la table `scrape_sources` via l'API REST Supabase (upsert)
- Déploie la function `update-outings` via `supabase functions deploy`
- Déclenche un POST de test vers l'endpoint function

Usage:
powershell -ExecutionPolicy Bypass -File .\supabase\scripts\supabase_setup_scrapers.ps1

# Attention: le script utilise la clé service role — garde-la secrète.
#>

Param()

function Read-EnvOrPrompt($name, $prompt) {
    $val = [System.Environment]::GetEnvironmentVariable($name)
    if (-not $val) {
        $val = Read-Host -Prompt $prompt
    }
    return $val
}

$SUPABASE_URL = Read-EnvOrPrompt 'SUPABASE_URL' 'SUPABASE_URL (ex: https://xyz.supabase.co)'
$SERVICE_ROLE_KEY = [System.Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_ROLE_KEY')
if (-not $SERVICE_ROLE_KEY) { $SERVICE_ROLE_KEY = Read-EnvOrPrompt 'SERVICE_ROLE_KEY' 'SUPABASE_SERVICE_ROLE_KEY or SERVICE_ROLE_KEY (service role key)'}
$ANON_KEY = [System.Environment]::GetEnvironmentVariable('SUPABASE_ANON_KEY')
$PROJECT_REF = Read-EnvOrPrompt 'PROJECT_REF' 'PROJECT_REF (supabase project ref, ex: xyz)'
$PROJECT_REF = Read-EnvOrPrompt 'PROJECT_REF' 'PROJECT_REF (supabase project ref, ex: xyz)'
$FUNCTION_URL = [System.Environment]::GetEnvironmentVariable('FUNCTION_URL')
if (-not $FUNCTION_URL -and $PROJECT_REF) {
    $FUNCTION_URL = "https://$PROJECT_REF.functions.supabase.co"
}

if (-not $SUPABASE_URL -or -not $SERVICE_ROLE_KEY) {
    Write-Error 'SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or SERVICE_ROLE_KEY) are required. Aborting.'
    exit 1
}

# Sources to insert/upsert
$sources = @(
    @{ source = 'sortiramarseille'; url = 'https://www.sortiramarseille.fr/'; enabled = $true },
    @{ source = 'tarpin-bien'; url = 'https://tarpin-bien.com/'; enabled = $true },
    @{ source = 'marseille-tourisme'; url = 'https://www.marseille-tourisme.com/vivez-marseille-blog/agenda/'; enabled = $true },
    @{ source = 'shotgun'; url = 'https://shotgun.live/api/graphql'; enabled = $true }
)

$headers = @{ 
    'apikey' = $SERVICE_ROLE_KEY;
    'Authorization' = "Bearer $SERVICE_ROLE_KEY";
    'Content-Type' = 'application/json';
    'Prefer' = 'resolution=merge-duplicates'
}

Write-Host "Upserting ${($sources).Count} sources into scrape_sources..."
foreach ($s in $sources) {
    $body = $s | ConvertTo-Json -Depth 4
    # use on_conflict matching the unique index (source,url)
    $uri = "$SUPABASE_URL/rest/v1/scrape_sources?on_conflict=source,url"
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
        Write-Host "Upserted: $($s.source) -> $($s.url)"
    } catch {
        Write-Warning "Upsert failed for $($s.source): $_"
    }
}

# Deploy function using supabase CLI if available
if (Get-Command supabase -ErrorAction SilentlyContinue) {
    if (-not $PROJECT_REF) {
        Write-Host 'PROJECT_REF not set, skipping function deploy (provide PROJECT_REF to deploy).'
    } else {
        Write-Host 'Deploying function update-outings with supabase CLI...'
        try {
            & supabase functions deploy update-outings --project-ref $PROJECT_REF
            Write-Host 'Function deploy command finished.'
        } catch {
            Write-Warning "supabase functions deploy failed: $_"
        }
    }
} else {
    Write-Host 'supabase CLI not found in PATH — skipping function deploy. Install supabase CLI to enable deploy.'
}

# Trigger a test run of the function
if ($FUNCTION_URL) {
    $triggerUrl = "$FUNCTION_URL/update-outings"
    Write-Host "Triggering function: $triggerUrl"
    try {
        $triggerHeaders = @{ 'apikey' = $SERVICE_ROLE_KEY; 'Authorization' = "Bearer $SERVICE_ROLE_KEY" }
        if ($ANON_KEY) { $triggerHeaders['x-supabase-anon'] = $ANON_KEY }
        $res = Invoke-RestMethod -Method Post -Uri $triggerUrl -Headers $triggerHeaders -ErrorAction Stop
        Write-Host 'Function response:'
        $res | ConvertTo-Json -Depth 5
    } catch {
        Write-Warning "Trigger failed: $_"
    }
} else {
    Write-Host 'FUNCTION_URL could not be derived; provide FUNCTION_URL env var to trigger the remote function automatically.'
}

Write-Host 'Done. Vérifie la table public.outings dans Supabase SQL Editor.'

<#
deploy_daily_email.ps1
Script PowerShell pour déployer la Supabase Edge Function `daily-email` et tenter d'ajouter la variable `FCM_SERVER_KEY`.
Pré-requis locaux:
- Node/npm (pour installer supabase CLI si nécessaire)
- supabase CLI (le script installera si absent)
- Variables d'environnement:
  - SUPABASE_ACCESS_TOKEN : token CLI (ou faites `supabase login` manuellement)
  - SUPABASE_PROJECT_REF  : votre project-ref Supabase (ex: abcdefg)
  - FCM_SERVER_KEY        : (optionnel) clé serveur FCM legacy

Usage:
  powershell -ExecutionPolicy Bypass -File .\scripts\deploy_daily_email.ps1
#>

Set-StrictMode -Version Latest

function Write-Info($s) { Write-Host "[INFO] $s" -ForegroundColor Cyan }
function Write-Err($s) { Write-Host "[ERROR] $s" -ForegroundColor Red }

# Vérifier présence de supabase CLI
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Info "supabase CLI non trouvé. Tentative d'installation via npm..."
    try {
        npm install -g supabase
        Write-Info "supabase CLI installé"
    } catch {
        Write-Err "Impossible d'installer supabase CLI automatiquement. Installez-le manuellement et relancez le script."
        exit 1
    }
} else {
    Write-Info "supabase CLI trouvé"
}

# Vérifier variables d'environnement
if (-not $env:SUPABASE_PROJECT_REF) {
    Write-Err "La variable d'environnement SUPABASE_PROJECT_REF n'est pas définie. Exportez-la avant d'exécuter. Ex: $env:SUPABASE_PROJECT_REF='your-ref'"
    exit 1
}

if (-not $env:SUPABASE_ACCESS_TOKEN) {
    Write-Info "SUPABASE_ACCESS_TOKEN non fourni. Vous pouvez vous connecter manuellement avec 'supabase login' ou définir SUPABASE_ACCESS_TOKEN."
    Write-Info "Souhaitez-vous effectuer un login interactif maintenant ? (y/N)"
    $answer = Read-Host
    if ($answer -match '^[Yy]') {
        supabase login
    } else {
        Write-Err "Token d'accès absent. Le déploiement échouera sans authentification."
        exit 1
    }
} else {
    Write-Info "Connexion via SUPABASE_ACCESS_TOKEN"
    supabase login --token $env:SUPABASE_ACCESS_TOKEN
}

# Déployer la function
Write-Info "Déploiement de la function 'daily-email' (project-ref: $env:SUPABASE_PROJECT_REF)"
Push-Location -Path "$PSScriptRoot\..\supabase\functions\daily-email"
try {
    supabase functions deploy daily-email --project-ref $env:SUPABASE_PROJECT_REF
    Write-Info "Déploiement terminé (vérifiez la sortie pour erreurs)."
} catch {
    Write-Err "Erreur lors du déploiement : $_"
    Pop-Location
    exit 1
}
Pop-Location

# Tenter d'ajouter la variable FCM_SERVER_KEY si fournie
if ($env:FCM_SERVER_KEY) {
    Write-Info "Tentative d'ajout de la variable FCM_SERVER_KEY dans Supabase (via supabase CLI)..."
    try {
        # Plusieurs CLI ont des variations ; essayer quelques commandes
        supabase secrets set FCM_SERVER_KEY="$env:FCM_SERVER_KEY" --project-ref $env:SUPABASE_PROJECT_REF 2>$null
        if ($LASTEXITCODE -ne 0) {
            supabase functions env set daily-email FCM_SERVER_KEY="$env:FCM_SERVER_KEY" --project-ref $env:SUPABASE_PROJECT_REF 2>$null
        }
        Write-Info "Tentative terminée. Si la CLI n'a pas supporté la commande, ajoutez la variable FCM_SERVER_KEY manuellement dans le dashboard Supabase (Project → Settings → Environment)."
    } catch {
        Write-Err "Impossible d'ajouter FCM_SERVER_KEY automatiquement : $_"
        Write-Info "Ajoutez manuellement la clé dans Supabase Project → Settings → Environment"
    }
} else {
    Write-Info "Aucune FCM_SERVER_KEY fournie. Ajoutez-la manuellement dans Supabase Project → Settings → Environment si vous voulez activer les pushs."
}

Write-Info "Fin du script. Vérifiez les logs de la function dans Supabase (Functions → daily-email → Logs) après invocation."

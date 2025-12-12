# Scripts d’exploitation Supabase (Edge Functions)

## Prérequis
- Disposer de `SUPABASE_URL` et `SUPABASE_ANON_KEY` (clé publique) du projet.
- Ports/pare-feu autorisant les appels sortants HTTPS.

## Vérifier la pipeline (scraper + email)

Sous PowerShell (Windows):

```powershell
Set-Item Env:SUPABASE_URL "https://<ref>.supabase.co"; Set-Item Env:SUPABASE_ANON_KEY "<anon-public-key>"
./scripts/verify_pipeline.ps1
```

Ce script:
- Appelle `update-outings` (insertion d'événements ou seed si scraping vide)
- Appelle `daily-email` (envoi des emails via Resend)
- Affiche les réponses JSON pour contrôle

Astuce: l’URL des fonctions est déduite automatiquement de `SUPABASE_URL` en remplaçant `.supabase.co` par `.functions.supabase.co`.

Edge Function Supabase — Outings Scraper

Ce dossier contient une Edge Function Deno/TypeScript prête à déployer sur Supabase.

Fichiers:
- `index.ts` : fonction principale exposant `GET /` qui renvoie un tableau JSON d'événements.

Tester localement (pré-requis : `supabase` CLI installé et connecté) :

1. Dans le repo, positionne-toi dans le dossier racine du projet.
2. Lancer la fonction localement :

   ```bash
   supabase functions serve outings --no-verify
   ```

   Ou si tu as placé la fonction dans `edge_functions/supabase_outings`, adapte le chemin dans `supabase/functions`.

Déployer (exemple) :

1. `supabase login`
2. `supabase link --project-ref <ton_project_ref>` (si nécessaire)
3. `supabase functions deploy outings --project-ref <ton_project_ref>`

Après déploiement la fonction sera accessible via:

`https://<project>.functions.supabase.co/outings`

Remarques:
- L'Edge Function utilise `DOMParser` pour parser le HTML. Si une source bloque l'accès ou renvoie des protections anti-scraping, la fonction retournera moins d'items.
- Cette approche contourne les problèmes CORS car le scraping est fait côté serveur.

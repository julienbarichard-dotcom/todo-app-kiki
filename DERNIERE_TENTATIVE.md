# DERNIÈRE TENTATIVE - Résolution problème scraping

## Problème
La table `public.outings` reste vide après déploiement et appel de la fonction.

## Ce qui a été fait
1. ✅ Fonction `update-outings` déployée avec succès
2. ✅ Code inclut scraping multi-sources + enrichissement + déduplication + upsert
3. ✅ Nettoyage des anciennes entrées (>7 jours)

## Points de vérification critiques

### 1. Variables d'environnement
La fonction a BESOIN de ces variables pour fonctionner:
- `SUPABASE_URL`: URL de votre projet (https://joupiybyhoytfuncqmyv.supabase.co)
- `SUPABASE_SERVICE_ROLE_KEY`: Clé service_role (Dashboard > Settings > API)

**Où les configurer:**
Dashboard Supabase > Project Settings > Edge Functions > Add secret
- Nom: `SUPABASE_URL`
  Valeur: `https://joupiybyhoytfuncqmyv.supabase.co`
- Nom: `SUPABASE_SERVICE_ROLE_KEY`
  Valeur: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOi...` (votre clé complète)

### 2. Index unique sur URL
La fonction utilise `onConflict: 'id'`. Vérifiez que la table a l'index:

```sql
-- Vérifier index existant
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'outings';

-- Si absent, créer:
CREATE UNIQUE INDEX IF NOT EXISTS outings_url_unique ON public.outings(url);
```

### 3. Structure table public.outings
Vérifier que la table a toutes les colonnes requises:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'outings'
ORDER BY ordinal_position;
```

Colonnes requises:
- `id` (text, PK)
- `title` (text)
- `date` (timestamptz)
- `location` (text)
- `url` (text)
- `source` (text)
- `categories` (text[])
- `description` (text, nullable)
- `image_url` (text, nullable)
- `updated_at` (timestamptz, default now())

### 4. Permissions RLS
Vérifier que service_role peut écrire (normalement bypass RLS):

```sql
-- Vérifier RLS
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'outings';

-- Si RLS actif, vérifier policies
SELECT * FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'outings';
```

## Test manuel

### Option A: Via Dashboard Supabase
1. Aller dans **Database** > **Functions** > `update-outings`
2. Cliquer **Invoke Function**
3. Body: `{}`
4. Method: `POST`
5. Vérifier la réponse JSON

### Option B: Via script PowerShell
1. Éditer `test_update_outings.ps1`
2. Remplacer `VOTRE_SERVICE_ROLE_KEY_ICI` par votre vraie clé
3. Exécuter: `.\test_update_outings.ps1`

### Option C: Via SQL Editor (pg_cron simulation)
```sql
SELECT net.http_post(
  url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/update-outings',
  headers := jsonb_build_object(
    'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
    'Content-Type', 'application/json'
  ),
  body := '{}'::jsonb
);
```

⚠️ Nécessite d'avoir configuré `app.settings.service_role_key` avant:
```sql
ALTER SYSTEM SET app.settings.service_role_key TO 'votre_service_role_key';
SELECT pg_reload_conf();
```

## Vérification après test

```sql
-- Compter les lignes
SELECT count(*) FROM public.outings;

-- Voir les 10 premières
SELECT id, title, date, source, categories, url 
FROM public.outings 
ORDER BY date 
LIMIT 10;

-- Vérifier les sources
SELECT source, count(*) 
FROM public.outings 
GROUP BY source;
```

## Diagnostic si toujours vide

### Vérifier les logs de la fonction
Dashboard > Functions > update-outings > Logs
- Chercher les erreurs d'authentification
- Vérifier que `SUPABASE_URL` et `SERVICE_ROLE_KEY` sont définis
- Voir le détail de `upsertError` si présent

### Forcer un test minimal
Créer une fonction test simplifiée:

```sql
-- Test insertion directe
INSERT INTO public.outings (
  id, title, date, location, url, source, categories
) VALUES (
  'test_manual_001',
  'Test Event Manual',
  now() + interval '1 day',
  'Marseille',
  'https://test.com/event1',
  'manual_test',
  ARRAY['test']
) ON CONFLICT (id) DO NOTHING;

-- Vérifier
SELECT * FROM public.outings WHERE source = 'manual_test';
```

Si cette insertion fonctionne → problème dans la fonction Edge.
Si elle échoue → problème de permissions/structure table.

## Planification cron (après succès du test)

Une fois que le test manuel fonctionne:

```sql
-- Créer le job quotidien à minuit
SELECT cron.schedule(
  'scrape_outings_midnight',
  '0 0 * * *',
  $$
  SELECT net.http_post(
    url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/update-outings',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  )
  $$
);

-- Vérifier les jobs existants
SELECT * FROM cron.job;
```

## Checklist finale

- [ ] Variables d'environnement `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` configurées
- [ ] Index unique sur `outings(url)` ou `outings(id)` créé
- [ ] Structure table `public.outings` complète avec toutes les colonnes
- [ ] Test manuel réussi (voir nombre d'events > 0 dans la réponse)
- [ ] Vérification SQL: `SELECT count(*) FROM public.outings;` retourne > 0
- [ ] Logs de la fonction ne montrent pas d'erreur
- [ ] Job cron créé pour exécution quotidienne
- [ ] Flutter app affiche les 3 événements du carrousel

## Si rien ne fonctionne

**Hypothèses à vérifier:**
1. Les sources web (shotgun.co, vortexfrommars, etc.) bloquent le scraping → voir logs
2. DOMParser ne fonctionne pas dans Deno Deploy → erreur visible dans logs
3. Timeout réseau sur enrichissement → augmenter timeout ou désactiver temporairement
4. Conflit de schéma (colonnes manquantes) → erreur "column does not exist"

**Solution de repli:**
Insérer des données de test manuellement pour débloquer le développement Flutter:

```sql
-- Seed data minimal
INSERT INTO public.outings (id, title, date, location, url, source, categories, description, image_url)
VALUES
  ('seed_001', 'Electro Night @ Vortex', '2025-12-05 21:00:00+00', 'Vortex - Marseille', 'https://vortexfrommars.net/event1', 'vortex_site', ARRAY['electro', 'concert'], 'Soirée électro avec DJ internationaux', 'https://picsum.photos/400/300?random=1'),
  ('seed_002', 'Exposition Street Art', '2025-12-06 18:00:00+00', 'Galerie Trajectory - Marseille', 'https://agenda-culturel.com/expo1', 'agenda_culturel', ARRAY['expo', 'art'], 'Exposition collective de street art urbain', 'https://picsum.photos/400/300?random=2'),
  ('seed_003', 'Techno Festival 2025', '2025-12-10 20:00:00+00', 'Dock des Suds - Marseille', 'https://shotgun.co/event123', 'shotgun', ARRAY['electro', 'festival'], 'Festival de musique techno 3 jours', 'https://picsum.photos/400/300?random=3')
ON CONFLICT (id) DO NOTHING;
```

Cela permet de tester le carrousel Flutter immédiatement pendant qu'on debug le scraping.

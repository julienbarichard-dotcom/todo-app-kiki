# 🚀 GUIDE D'INSTALLATION - SYSTÈME D'ENVOI EMAIL + SCRAPER ÉVÉNEMENTS

## ✅ CE QUI A ÉTÉ FAIT

### 1. **Email à l'inscription** ✅
- Modifié `user_provider.dart` : l'email est maintenant sauvegardé lors de la création d'un compte
- Quentin (et tous les nouveaux utilisateurs) aura son email enregistré automatiquement

### 2. **Envoi automatique à MIDI** ✅
- Créé `supabase_setup_cron_MIDI.sql` : cron job configuré pour 12h00 (midi) au lieu de 8h00
- Le script supprime l'ancien cron et crée le nouveau

### 3. **Mise à jour automatique événements Shotgun/Vortex** ✅
- Créé `supabase/functions/update-outings/index.ts` : scraper backend qui tourne toutes les heures
- Créé `supabase_create_outings_table.sql` : table PostgreSQL pour stocker les événements
- Modifié `outings_provider.dart` : charge maintenant depuis Supabase au lieu de scraper côté client

### 4. **Rafraîchissement préférences** ✅
- Modifié `preferences_screen.dart` : force le recalcul des événements quand tu changes tes préférences

---

## 📋 ÉTAPES D'INSTALLATION

### ÉTAPE 1 : Configurer la base de données

```sql
-- Dans Supabase SQL Editor (https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql)

-- 1. Créer la table outings
-- Copier-coller tout le contenu de: supabase_create_outings_table.sql

-- 2. Vérifier les utilisateurs et leurs emails
SELECT prenom, email FROM users;

-- 3. Ajouter les emails manquants (Julien, Lou, Quentin, etc.)
UPDATE users SET email = 'julien.barichard@gmail.com' WHERE prenom = 'Julien';
UPDATE users SET email = 'loubrossier@gmail.com' WHERE prenom = 'Lou';
-- Ajouter Quentin si nécessaire :
-- UPDATE users SET email = 'quentin@exemple.com' WHERE prenom = 'Quentin';
```

### ÉTAPE 2 : Déployer les Edge Functions

```powershell
# Dans le terminal PowerShell
cd "E:\App todo\todo_app_kiki"

# Déployer la fonction de scraping
supabase functions deploy update-outings

# Déployer la fonction d'email (si pas déjà fait)
supabase functions deploy daily-email
```

### ÉTAPE 3 : Configurer les variables d'environnement

1. Aller sur : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/settings/functions
2. Ajouter ces variables :
   - `RESEND_API_KEY` = `[ta clé API Resend]`
   - `SUPABASE_URL` = `https://joupiybyhoytfuncqmyv.supabase.co`
   - `SUPABASE_SERVICE_ROLE_KEY` = `[clé service role depuis Settings → API]`

### ÉTAPE 4 : Activer les cron jobs

```sql
-- Dans Supabase SQL Editor
-- Copier-coller tout le contenu de: supabase_setup_cron_MIDI.sql

-- Vérifier que les jobs sont créés
SELECT jobname, schedule, active FROM cron.job;

-- Tu devrais voir :
-- daily-email-recap | 0 11 * * * | true
-- update-outings-hourly | 0 * * * * | true
```

### ÉTAPE 5 : Tester manuellement

```sql
-- Tester l'envoi d'email
SELECT extensions.http_post(
  url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/daily-email',
  headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NTQwOTEsImV4cCI6MjA0ODAzMDA5MX0.qCq2Dc4SgMaNy2aBgV6Vj6FVuW1pPGq7YO0cT_Tc2eI"}'::jsonb,
  body := '{}'::jsonb
);

-- Tester le scraper
SELECT extensions.http_post(
  url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/update-outings',
  headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NTQwOTEsImV4cCI6MjA0ODAzMDA5MX0.qCq2Dc4SgMaNy2aBgV6Vj6FVuW1pPGq7YO0cT_Tc2eI"}'::jsonb,
  body := '{}'::jsonb
);

-- Vérifier les événements scrapés
SELECT id, title, date, source, categories FROM outings ORDER BY date DESC LIMIT 10;
```

### ÉTAPE 6 : Builder et déployer l'app Flutter

```powershell
cd "E:\App todo\todo_app_kiki"

# Builder
flutter build web --release

# Déployer
firebase deploy --only hosting
```

---

## 🔍 VÉRIFICATIONS

### Email reçu à midi ?
```sql
-- Vérifier l'historique du cron email
SELECT status, return_message, start_time, end_time 
FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'daily-email-recap')
ORDER BY start_time DESC LIMIT 5;
```

### Événements mis à jour ?
```sql
-- Vérifier les derniers événements
SELECT title, date, source, updated_at FROM outings ORDER BY updated_at DESC LIMIT 10;

-- Vérifier l'historique du scraper
SELECT status, return_message, start_time 
FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'update-outings-hourly')
ORDER BY start_time DESC LIMIT 5;
```

### Préférences rafraîchies ?
- Ouvre l'app → Va dans Préférences
- Change une préférence (ex: coche "Trance")
- Clique sur Sauvegarder
- Retourne au carousel → Les événements devraient être recalculés

---

## 📊 RÉSUMÉ DES FICHIERS MODIFIÉS/CRÉÉS

✅ **Modifiés** :
- `lib/providers/user_provider.dart` : Email sauvegardé lors inscription
- `lib/providers/outings_provider.dart` : Charge depuis Supabase au lieu de scraper client
- `lib/screens/preferences_screen.dart` : Force rafraîchissement après changement

✅ **Créés** :
- `supabase/functions/update-outings/index.ts` : Scraper Shotgun/Vortex backend
- `supabase_create_outings_table.sql` : Table PostgreSQL pour événements
- `supabase_setup_cron_MIDI.sql` : Cron jobs (email à midi + scraper toutes les heures)
- `INSTALLATION_GUIDE.md` : Ce guide

---

## ⏰ PLANNING AUTOMATIQUE

| Action | Fréquence | Heure (Paris) |
|--------|-----------|---------------|
| **Scraper événements** | Toutes les heures | XX:00 |
| **Envoi email recap** | 1x par jour | 12:00 (midi) |
| **Nettoyage vieux événements** | Automatique | À chaque scrape |

---

## 🐛 DÉPANNAGE

### Email non reçu ?
1. Vérifier que l'email est dans la base : `SELECT email FROM users WHERE prenom = 'Julien';`
2. Vérifier la clé Resend configurée
3. Vérifier les logs : `SELECT * FROM cron.job_run_details ... LIMIT 5;`

### Événements pas à jour ?
1. Vérifier que la table existe : `SELECT * FROM outings LIMIT 5;`
2. Tester manuellement le scraper (voir ÉTAPE 5)
3. Vérifier les logs du cron : `SELECT * FROM cron.job_run_details ... LIMIT 5;`

### Préférences pas rafraîchies ?
1. Ouvrir les DevTools → Console
2. Chercher le message : "✅ Événements rafraîchis avec nouvelles préférences"
3. Si erreur, vérifier que le provider est bien importé

---

**🎉 C'EST PRÊT ! Exécute les étapes dans l'ordre et tout devrait fonctionner.**

# ✅ ÉTAPES FINALES - CONFIGURATION SUPABASE

## 📊 ÉTAT ACTUEL

✅ **FAIT :**
1. Emails ajoutés : Julien et Lou ✅
2. Table `outings` créée ✅
3. Fonction `update-outings` déployée ✅

🔧 **À FAIRE (2 étapes simples) :**

---

## 🔧 ÉTAPE 2/4 : Configurer les variables d'environnement

### **Action :**
1. Va sur : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/settings/functions
2. Clique sur **"Add new variable"**
3. Ajoute ces 3 variables :

```
Nom: RESEND_API_KEY
Valeur: [Ta clé API Resend - à récupérer sur https://resend.com/api-keys]
```

```
Nom: SUPABASE_URL
Valeur: https://joupiybyhoytfuncqmyv.supabase.co
```

```
Nom: SUPABASE_SERVICE_ROLE_KEY
Valeur: [Va sur Settings → API → service_role key (secret)]
```

4. Clique sur **"Save"**

✅ **Dis-moi "ok" quand c'est fait**

---

## ⏰ ÉTAPE 3/4 : Configurer les cron jobs (envoi email à MIDI + scraper)

### **Action :**
1. Va sur : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql
2. Crée une **nouvelle requête**
3. Copie-colle **TOUT** le contenu ci-dessous :

```sql
-- Configuration du cron job pour l'envoi quotidien d'emails À MIDI (12h00)
-- À exécuter dans Supabase SQL Editor : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- 1. Supprimer l'ancien cron job (s'il existe)
SELECT cron.unschedule('daily-email-recap');

-- 2. Créer le nouveau cron job pour 12h00 (MIDI) chaque jour
SELECT cron.schedule(
  'daily-email-recap',
  '0 11 * * *',  -- 11h UTC = 12h Paris (hiver), 10h UTC = 12h Paris (été)
  $$
  SELECT extensions.http_post(
    url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/daily-email',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NTQwOTEsImV4cCI6MjA0ODAzMDA5MX0.qCq2Dc4SgMaNy2aBgV6Vj6FVuW1pPGq7YO0cT_Tc2eI"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 3. Créer le cron job pour mettre à jour les événements (toutes les heures)
SELECT cron.schedule(
  'update-outings-hourly',
  '0 * * * *',  -- Toutes les heures à 00 minutes
  $$
  SELECT extensions.http_post(
    url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/update-outings',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NTQwOTEsImV4cCI6MjA0ODAzMDA5MX0.qCq2Dc4SgMaNy2aBgV6Vj6FVuW1pPGq7YO0cT_Tc2eI"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 4. Vérifier que les cron jobs ont été créés
SELECT jobname, schedule, active FROM cron.job 
WHERE jobname IN ('daily-email-recap', 'update-outings-hourly');
```

4. Clique sur **"Run"**
5. Tu dois voir 2 lignes dans le résultat :
   - `daily-email-recap | 0 11 * * * | true`
   - `update-outings-hourly | 0 * * * * | true`

✅ **Dis-moi "ok" quand c'est fait**

---

## 🧪 ÉTAPE 4/4 : Tester le scraper manuellement

### **Action :**
Retourne dans le terminal et je lancerai automatiquement les tests !

---

## 📋 RÉSUMÉ DE CE QUI SERA ACTIF

Une fois tout configuré :

| Fonction | Fréquence | Heure |
|----------|-----------|-------|
| **📧 Email automatique** | 1x par jour | 12h00 midi (Paris) |
| **🎉 Scraper Shotgun/Vortex** | Toutes les heures | XX:00 |
| **📝 Nouvel inscrit** | Instantané | Email sauvegardé automatiquement |
| **🔄 Préférences modifiées** | Instantané | Carousel se met à jour |

---

**👉 COMMENCE PAR L'ÉTAPE 2, puis reviens me dire "ok" !**

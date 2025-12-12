-- Configuration du cron job pour l'envoi quotidien d'emails
-- À exécuter dans Supabase SQL Editor : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- 1. Activer l'extension pg_cron (si pas déjà fait)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Activer l'extension http pour les requêtes externes
CREATE EXTENSION IF NOT EXISTS http WITH SCHEMA extensions;

-- 3. Créer le cron job pour 8h00 chaque matin (7h UTC = 8h Paris en hiver)
SELECT cron.schedule(
  'daily-email-recap',
  '0 7 * * *',  -- 7h UTC = 8h Paris (ajuster à 6h UTC en été)
  $$
  SELECT extensions.http_post(
    url := 'https://joupiybyhoytfuncqmyv.supabase.co/functions/v1/daily-email',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvdXBpeWJ5aG95dGZ1bmNxbXl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI0NTQwOTEsImV4cCI6MjA0ODAzMDA5MX0.qCq2Dc4SgMaNy2aBgV6Vj6FVuW1pPGq7YO0cT_Tc2eI"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);

-- 4. Vérifier que le cron job a été créé
SELECT * FROM cron.job WHERE jobname = 'daily-email-recap';

-- 5. Pour voir l'historique d'exécution
SELECT * FROM cron.job_run_details WHERE jobid = (
  SELECT jobid FROM cron.job WHERE jobname = 'daily-email-recap'
) ORDER BY start_time DESC LIMIT 10;

-- 6. Pour supprimer le cron job (si besoin)
-- SELECT cron.unschedule('daily-email-recap');

-- NOTE: pg_cron exécute les jobs selon le fuseau horaire du serveur (généralement UTC).
-- Ici nous programmons 07:00 UTC qui correspond à 08:00 en heure de Paris (hiver).
-- Pendant l'heure d'été (CEST) Paris = UTC+2, il faudra alors appeler 06:00 UTC pour obtenir 08:00 Paris.
-- Si vous voulez un horaire qui suit automatiquement l'heure locale de Paris,
-- il faut soit ajuster le cron lors des changements DST, soit exécuter un job plus fréquent
-- côté serveur qui vérifie la dateLocale Europe/Paris et n'envoie l'email que lorsque
-- c'est l'heure voulue en Europe/Paris. Une autre option est d'utiliser une infrastructure
-- de planification qui supporte explicitement les zones (ex: systemd timers, external scheduler).

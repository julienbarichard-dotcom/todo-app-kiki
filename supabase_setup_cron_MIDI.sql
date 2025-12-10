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

-- 5. Pour voir l'historique d'exécution
SELECT jobid, jobname, status, return_message, start_time, end_time 
FROM cron.job_run_details 
WHERE jobid IN (
  SELECT jobid FROM cron.job 
  WHERE jobname IN ('daily-email-recap', 'update-outings-hourly')
) 
ORDER BY start_time DESC 
LIMIT 20;

-- NOTE: 
-- - Email envoyé à 11h00 UTC = 12h00 Paris (hiver UTC+1)
-- - En été (CEST UTC+2), ajuster à 10h00 UTC si nécessaire
-- - Événements mis à jour toutes les heures automatiquement

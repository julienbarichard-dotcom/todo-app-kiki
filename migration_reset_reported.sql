-- Script de migration pour réinitialiser et reporter les tâches
-- À exécuter dans l'éditeur SQL de Supabase

-- ÉTAPE 1: Mettre is_reported à FALSE pour toutes les tâches futures ou d'aujourd'hui
-- (car elles n'ont jamais été reportées, c'est leur date originale)
UPDATE tasks
SET is_reported = false
WHERE (date_echeance >= CURRENT_DATE OR date_echeance IS NULL)
  AND est_complete = false;

-- ÉTAPE 2: Reporter toutes les tâches en retard à AUJOURD'HUI avec le flag is_reported = TRUE
-- Conservation de l'heure si elle existe (pas 00:00:00)
UPDATE tasks
SET 
  date_echeance = CASE
    -- Si l'heure n'est pas 00:00:00, conserver l'heure et changer juste la date
    WHEN EXTRACT(HOUR FROM date_echeance) != 0 
         OR EXTRACT(MINUTE FROM date_echeance) != 0 
         OR EXTRACT(SECOND FROM date_echeance) != 0 
    THEN 
      CURRENT_DATE + (date_echeance::time)
    -- Sinon juste la date d'aujourd'hui
    ELSE 
      CURRENT_DATE
  END,
  is_reported = true
WHERE date_echeance < CURRENT_DATE
  AND est_complete = false;

-- ÉTAPE 3: Afficher le résultat
SELECT 
  id, 
  titre, 
  date_echeance, 
  is_reported,
  CASE 
    WHEN date_echeance < CURRENT_DATE THEN '⚠️ ERREUR: Encore en retard!'
    WHEN date_echeance = CURRENT_DATE AND is_reported = true THEN '🔺 Reportée aujourd''hui'
    WHEN date_echeance = CURRENT_DATE AND is_reported = false THEN '📅 Aujourd''hui (pas reportée)'
    WHEN date_echeance > CURRENT_DATE THEN '📅 Future (pas de triangle)'
    ELSE 'Sans date'
  END as statut
FROM tasks
WHERE est_complete = false
ORDER BY date_echeance ASC NULLS LAST;

-- Statistiques finales
SELECT 
  COUNT(*) FILTER (WHERE is_reported = true) as taches_reportees_avec_triangle,
  COUNT(*) FILTER (WHERE is_reported = false AND date_echeance IS NOT NULL) as taches_normales_sans_triangle,
  COUNT(*) FILTER (WHERE date_echeance IS NULL) as taches_sans_date,
  COUNT(*) FILTER (WHERE est_complete = true) as taches_terminees
FROM tasks;

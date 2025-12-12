-- ============================================
-- SCRIPT DE RESTAURATION DES TÂCHES TERMINÉES
-- ============================================

-- Étape 1: Vérifier les tâches terminées (supprimées)
SELECT id, titre, est_complete, statut, updated_at 
FROM tasks 
WHERE est_complete = true OR statut = 'termine'
ORDER BY updated_at DESC
LIMIT 50;

-- Étape 2: Réactiver TOUTES les tâches terminées
UPDATE tasks 
SET est_complete = false, statut = 'enAttente', updated_at = NOW()
WHERE est_complete = true OR statut = 'termine';

-- Étape 3: Vérifier le nombre de tâches réactivées
SELECT COUNT(*) as total_taches, 
       COUNT(CASE WHEN est_complete = false THEN 1 END) as taches_actives,
       COUNT(CASE WHEN est_complete = true THEN 1 END) as taches_terminees
FROM tasks;

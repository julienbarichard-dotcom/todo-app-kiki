-- Migration pour ajouter la colonne statut à la table tasks
-- À exécuter dans l'éditeur SQL de Supabase : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- Ajouter la colonne statut (type TEXT pour stocker le statut: enAttente, enCours, termine)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS statut TEXT DEFAULT 'enAttente';

-- Ajouter un commentaire pour documenter la colonne
COMMENT ON COLUMN tasks.statut IS 'Statut de la tâche: enAttente, enCours, termine';

-- Vérifier que la colonne a été créée
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'tasks' AND column_name = 'statut';

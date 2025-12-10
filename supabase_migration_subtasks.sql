-- Migration pour ajouter la colonne sub_tasks à la table tasks
-- À exécuter dans l'éditeur SQL de Supabase : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- Ajouter la colonne sub_tasks (type JSONB pour stocker un array de sous-tâches)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS sub_tasks JSONB DEFAULT '[]'::jsonb;

-- Ajouter un commentaire pour documenter la colonne
COMMENT ON COLUMN tasks.sub_tasks IS 'Liste des sous-tâches au format JSON: [{"id": "...", "titre": "...", "est_complete": false}]';

-- Vérifier que la colonne a été créée
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'tasks' AND column_name = 'sub_tasks';

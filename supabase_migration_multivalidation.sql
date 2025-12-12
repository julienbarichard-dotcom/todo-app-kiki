-- Migration pour ajouter la multi-validation collaborative aux tâches
-- À exécuter dans l'éditeur SQL de Supabase : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- 1. Ajouter la colonne is_multi_validation (booléen)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS is_multi_validation BOOLEAN DEFAULT false;

-- 2. Ajouter la colonne validations (JSONB pour stocker {"prenom": true/false})
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS validations JSONB DEFAULT '{}'::jsonb;

-- 3. Ajouter la colonne comments (JSONB pour stocker liste de commentaires)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS comments JSONB DEFAULT '[]'::jsonb;

-- 4. Ajouter la colonne is_rejected (booléen - card rouge si rejeté)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS is_rejected BOOLEAN DEFAULT false;

-- 5. Ajouter la colonne last_updated_validation (timestamp)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS last_updated_validation TIMESTAMP;

-- Ajouter des commentaires pour documenter
COMMENT ON COLUMN tasks.is_multi_validation IS 'Active le mode multi-validation collaborative';
COMMENT ON COLUMN tasks.validations IS 'Objet JSON: {"Julien": true, "Lou": false, ...}';
COMMENT ON COLUMN tasks.comments IS 'Tableau JSON: [{"author": "Julien", "text": "...", "timestamp": "..."}, ...]';
COMMENT ON COLUMN tasks.is_rejected IS 'Card rouge si au moins un rejet';
COMMENT ON COLUMN tasks.last_updated_validation IS 'Timestamp dernière validation/rejet';

-- Vérifier que les colonnes ont été créées
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name IN ('is_multi_validation', 'validations', 'comments', 'is_rejected', 'last_updated_validation')
ORDER BY column_name;

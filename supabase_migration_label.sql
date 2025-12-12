-- Migration pour ajouter la colonne label à la table tasks
-- À exécuter dans l'éditeur SQL de Supabase : https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- Ajouter la colonne label (type TEXT pour stocker la catégorie)
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS label TEXT;

-- Ajouter un commentaire pour documenter la colonne
COMMENT ON COLUMN tasks.label IS 'Catégorie de la tâche: Perso, B2B, Cuisine, Administratif, Loisir, Autre';

-- Vérifier que la colonne a été créée
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'tasks' AND column_name = 'label';

-- Migration pour ajouter la colonne email à la table users
-- Exécuter dans Supabase SQL Editor: https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql

-- Ajouter la colonne email (optionnelle)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS email VARCHAR(255) NULL;

-- Créer un index pour optimiser les recherches par email
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Mettre à jour les emails des utilisateurs existants (optionnel)
-- UPDATE users SET email = 'loubrossier@gmail.com' WHERE prenom = 'Lou';
-- UPDATE users SET email = 'julien.barichard@gmail.com' WHERE prenom = 'Julien';

-- Vérifier la structure
SELECT * FROM users;

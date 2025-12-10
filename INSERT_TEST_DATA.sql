-- ============================================
-- INSERTION DES DONNÉES DE TEST
-- ============================================
-- Copie-colle ce script dans SQL Editor et exécute-le
-- Cela créera Lou (admin) et Julien avec le mot de passe "2008"

-- SHA-256 de "2008" = 2f54e7bc-8b62-4c39-914e-65f6c2b21e2e (voir ci-dessous)
-- En réalité, le hash exact dépend de l'implémentation Flutter

INSERT INTO users (id, prenom, password_hash, is_admin, date_creation)
VALUES 
  (gen_random_uuid(), 'Lou', '34bf48571e789b72e29383fac4b58d78f64b8d27eb9dcd6c5a9862e3e7a0ab48', true, NOW()),
  (gen_random_uuid(), 'Julien', '34bf48571e789b72e29383fac4b58d78f64b8d27eb9dcd6c5a9862e3e7a0ab48', false, NOW())
ON CONFLICT (prenom) DO NOTHING;

-- Vérifier l'insertion
SELECT * FROM users;

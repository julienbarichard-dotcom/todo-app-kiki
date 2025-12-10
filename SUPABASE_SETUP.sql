-- ============================================
-- INSTRUCTIONS SUPABASE
-- ============================================
-- 1. Va sur https://supabase.com/dashboard
-- 2. Sélectionne ton projet
-- 3. Va dans "SQL Editor" (en bas à gauche)
-- 4. Crée une nouvelle requête
-- 5. Copie-colle tout le code ci-dessous
-- 6. Clique "RUN"
-- 7. C'est bon !

-- ============================================
-- TABLE USERS
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prenom TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT false,
  date_creation TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- TABLE TASKS
-- ============================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre TEXT NOT NULL,
  description TEXT,
  urgence TEXT DEFAULT 'moyenne',
  date_echeance TIMESTAMP,
  assigned_to TEXT[] DEFAULT ARRAY[]::TEXT[],
  est_complete BOOLEAN DEFAULT false,
  notification_enabled BOOLEAN DEFAULT false,
  notification_minutes_before INTEGER,
  date_creation TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- ENABLE REALTIME (important pour la sync)
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;

-- ============================================
-- ROW LEVEL SECURITY (optionnel mais recommandé)
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "Enable read access for all users" ON users;
DROP POLICY IF EXISTS "Enable read access for all tasks" ON tasks;
DROP POLICY IF EXISTS "Enable all insert" ON tasks;
DROP POLICY IF EXISTS "Enable all update" ON tasks;
DROP POLICY IF EXISTS "Enable all delete" ON tasks;

-- Créer une politique pour que chacun puisse lire les utilisateurs
CREATE POLICY "Enable read access for all users" 
ON users FOR SELECT 
USING (true);

-- Créer une politique pour que chacun puisse lire les tâches
CREATE POLICY "Enable read access for all tasks" 
ON tasks FOR SELECT 
USING (true);

-- Créer une politique pour que chacun puisse insérer/modifier ses tâches
CREATE POLICY "Enable all insert" 
ON tasks FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Enable all update" 
ON tasks FOR UPDATE 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Enable all delete" 
ON tasks FOR DELETE 
USING (true);

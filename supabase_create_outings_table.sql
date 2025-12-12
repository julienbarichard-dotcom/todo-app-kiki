-- Créer la table outings pour stocker les événements Shotgun/Vortex
-- À exécuter dans Supabase SQL Editor

CREATE TABLE IF NOT EXISTS outings (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  location TEXT NOT NULL,
  url TEXT NOT NULL,
  source TEXT NOT NULL,
  categories TEXT[] DEFAULT '{}',
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour rechercher par date
CREATE INDEX IF NOT EXISTS idx_outings_date ON outings(date DESC);

-- Index pour rechercher par source
CREATE INDEX IF NOT EXISTS idx_outings_source ON outings(source);

-- Index pour rechercher par catégories (GIN pour les tableaux)
CREATE INDEX IF NOT EXISTS idx_outings_categories ON outings USING GIN(categories);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_outings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_outings_updated_at
  BEFORE UPDATE ON outings
  FOR EACH ROW
  EXECUTE FUNCTION update_outings_updated_at();

-- Donner les permissions
ALTER TABLE outings ENABLE ROW LEVEL SECURITY;

-- Politique: Tout le monde peut lire
CREATE POLICY "Allow public read access" ON outings
  FOR SELECT USING (true);

-- Politique: Seul le service role peut écrire
CREATE POLICY "Allow service role write access" ON outings
  FOR ALL USING (auth.role() = 'service_role');

-- Vérifier la création
SELECT * FROM outings LIMIT 5;

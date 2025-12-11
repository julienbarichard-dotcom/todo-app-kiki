-- 🎯 MIGRATION: user_preferences table
-- À exécuter dans: https://supabase.com/dashboard/project/joupiybyhoytfuncqmyv/sql
-- Cliquez "+ New Query" et collez ce code

CREATE TABLE IF NOT EXISTS public.user_preferences (
  user_id uuid PRIMARY KEY DEFAULT auth.uid(),
  preferred_categories text[] DEFAULT '{"concert", "soiree", "electro", "expo"}',
  preferred_start_time time DEFAULT '19:00',
  preferred_end_time time DEFAULT '03:00',
  min_price numeric DEFAULT 0,
  max_price numeric DEFAULT 1000,
  exclude_keywords text[] DEFAULT '{"enfant", "jeune public", "famille", "kids"}',
  enable_notifications boolean DEFAULT true,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Row Level Security: Users can only see/edit their own preferences
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own preferences" ON public.user_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON public.user_preferences
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON public.user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);

-- ✅ Résultat attendu: "0 rows affected" (création réussie)

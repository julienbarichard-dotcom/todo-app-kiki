-- Migration : ajouter emails manquants pour Lou & Quentin
-- et créer un trigger pour synchroniser automatiquement les nouveaux comptes
-- A exécuter dans Supabase SQL Editor ou via supabase CLI

-- 1) Mettre à jour les adresses connues (modifier si nécessaire)
UPDATE users SET email = 'loubrossier@gmail.com' WHERE prenom = 'Lou' AND (email IS NULL OR email = '');
UPDATE users SET email = 'quentin@exemple.com' WHERE prenom = 'Quentin' AND (email IS NULL OR email = '');

-- 2) Créer une function qui synchronise auth.users -> public.users
--    Lorsqu'un nouvel utilisateur s'inscrit (auth.users INSERT), on crée/mettre à jour
--    une ligne dans la table `users` avec id, prenom et email.
--    Cette fonction est tolerant : utilise le prénom si présent dans user_metadata,
--    sinon utilise la partie locale de l'email.

CREATE OR REPLACE FUNCTION public.sync_auth_user_to_users()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  u_email text := NEW.email;
  u_meta jsonb := NEW.raw_user_meta_data::jsonb; -- supabase stores user_metadata/raw
  u_prenom text;
BEGIN
  -- Try to read common metadata keys for first name
  IF u_meta ? 'prenom' THEN
    u_prenom := (u_meta ->> 'prenom');
  ELSIF u_meta ? 'first_name' THEN
    u_prenom := (u_meta ->> 'first_name');
  ELSIF u_meta ? 'name' THEN
    u_prenom := (u_meta ->> 'name');
  ELSE
    -- fallback to local-part of email
    u_prenom := split_part(u_email, '@', 1);
  END IF;

  -- Upsert into public.users
  INSERT INTO public.users (id, prenom, email, date_creation)
  VALUES (NEW.id, u_prenom, u_email, now())
  ON CONFLICT (id) DO UPDATE
    SET email = COALESCE(public.users.email, EXCLUDED.email),
        prenom = COALESCE(public.users.prenom, EXCLUDED.prenom);

  RETURN NEW;
END;
$$;

-- 3) Create trigger on auth.users (runs after insert)
-- Note: requires sufficient privileges (service role) to create trigger on auth schema.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    WHERE t.tgname = 'tr_sync_auth_user_to_users'
  ) THEN
    CREATE TRIGGER tr_sync_auth_user_to_users
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE PROCEDURE public.sync_auth_user_to_users();
  END IF;
END$$;

-- IMPORTANT:
-- - Exécutez ce fichier depuis Supabase SQL Editor (ou supabase db query) avec un rôle
--   qui a le droit de créer fonctions et triggers (p.ex. via le panneau SQL du projet).
-- - Si votre projet Supabase stocke user metadata sous une clé différente, ajustez
--   l'extraction de `prenom` dans la fonction ci‑dessus.

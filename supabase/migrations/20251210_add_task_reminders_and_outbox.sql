-- Migration: Ajouter colonne reminders (jsonb) à la table tasks
-- et créer une table email_outbox pour stocker les envois d'e-mail (outbox)
-- Non-destructive: la colonne est nullable et l'ajout est idempotent

BEGIN;

-- Extension pour gen_random_uuid si disponible
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1) Ajouter la colonne reminders (jsonb NULL)
ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS reminders jsonb;

-- 2) Créer la table email_outbox pour stocker les tentatives d'envoi (outbox)
CREATE TABLE IF NOT EXISTS public.email_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id uuid,
  to_email text,
  subject text,
  body jsonb,
  channel text,
  status text DEFAULT 'pending', -- pending | sent | failed
  attempts integer DEFAULT 0,
  last_error text,
  scheduled_at timestamptz,
  created_at timestamptz DEFAULT now()
);

COMMIT;

-- Rollback (si nécessaire):
-- ALTER TABLE public.tasks DROP COLUMN IF EXISTS reminders;
-- DROP TABLE IF EXISTS public.email_outbox;

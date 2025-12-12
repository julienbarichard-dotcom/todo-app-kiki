-- Migration: Remove notification and due-date columns
-- Date: 2025-12-10
-- IMPORTANT: This operation is destructive. Run a backup before applying.

-- Backup (recommended): create a copy of tasks table
-- CREATE TABLE IF NOT EXISTS tasks_backup AS TABLE tasks;

BEGIN;

-- Drop columns if they exist (safe to run multiple times)
ALTER TABLE public.tasks
  DROP COLUMN IF EXISTS date_echeance,
  DROP COLUMN IF EXISTS notification_enabled,
  DROP COLUMN IF EXISTS notification_minutes_before,
  DROP COLUMN IF EXISTS reminders;

COMMIT;

-- After applying: update any client code and restart services consuming the DB.

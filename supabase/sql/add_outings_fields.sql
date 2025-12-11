-- Migration: Add missing event fields to outings table
-- This enriches the outings table to capture more event details from different sources

ALTER TABLE public.outings
ADD COLUMN IF NOT EXISTS location text,
ADD COLUMN IF NOT EXISTS organizer text,
ADD COLUMN IF NOT EXISTS price text,
ADD COLUMN IF NOT EXISTS start_time time,
ADD COLUMN IF NOT EXISTS end_time time,
ADD COLUMN IF NOT EXISTS tags text[];

-- Create index on location for filtering by venue
CREATE INDEX IF NOT EXISTS idx_outings_location ON public.outings(location);
CREATE INDEX IF NOT EXISTS idx_outings_organizer ON public.outings(organizer);

-- Update last_seen on each upsert (handled by application layer)

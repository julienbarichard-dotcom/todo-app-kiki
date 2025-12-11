-- Schedule daily scraping at 06:00 UTC
-- Using pg_cron extension (must be enabled in Supabase)
-- This will call the update-outings function every day at 6 AM

-- First, ensure pg_cron extension is enabled (Supabase usually has it)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule the scraping job
-- Note: You still need to set up the actual HTTP call via Supabase Dashboard
-- Dashboard → Functions → update-outings → Schedules → New Schedule

-- Alternative: Store the job ID for reference
-- SELECT cron.schedule('update-outings-daily', '0 6 * * *', 'SELECT 1');

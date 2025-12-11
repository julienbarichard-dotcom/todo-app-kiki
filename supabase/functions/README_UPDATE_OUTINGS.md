README - update-outings function

But: This function scrapes configured sources and normalizes events into the `outings` table.

Environment variables required (set in Supabase dashboard or Deno Deploy):
- `SUPABASE_URL` - your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - your service role key (required for writes/upserts)

Database tables (run SQL in `SQL Editor`):
- `supabase/sql/create_scraper_sources.sql` (creates `scraper_sources`)
- `supabase/sql/create_outings.sql` (creates `outings`)

Usage:
- POST /update-outings  -> runs scraping and upserts into `outings` when service role key provided.
- GET /                -> returns sample scraped items (for debug).

Scheduler:
- Use Supabase Scheduled Functions (or external cron) to call POST /update-outings every 6 or 12 hours.
  Example cron using curl:

  curl -X POST https://<YOUR_FUNCTION_URL>/update-outings -H "apikey: <anon_or_service_role_if_needed>"

Notes:
- The function will prefer `scraper_sources` rows (active=true) when the Supabase client is available.
- Ensure `SUPABASE_SERVICE_ROLE_KEY` has insert/update privileges on `outings`.

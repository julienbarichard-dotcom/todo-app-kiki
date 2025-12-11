-- Create table for normalized outings/events scraped from sources
create extension if not exists pgcrypto;

create table if not exists public.outings (
  id uuid primary key default gen_random_uuid(),
  url text not null unique,
  title text,
  source text,
  categories jsonb,
  date timestamptz,
  image text,
  description text,
  last_seen timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_outings_date on public.outings(date);
create index if not exists idx_outings_source on public.outings(source);

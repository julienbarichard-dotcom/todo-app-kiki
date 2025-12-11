-- Create table for scraper source URLs
create extension if not exists pgcrypto;

create table if not exists public.scraper_sources (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  url text not null,
  active boolean not null default true,
  last_checked timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_scraper_sources_active on public.scraper_sources(active);

-- Example inserts (replace or run once)
insert into public.scraper_sources (name, url) values
('sortiramarseille','https://www.sortiramarseille.fr/'),
('tarpin-bien','https://tarpin-bien.com/'),
('marseille-tourisme','https://www.marseille-tourisme.com/vivez-marseille-blog/agenda/');

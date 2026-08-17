-- PakSoc site backend schema.
-- Run this once in the Supabase SQL Editor (Project → SQL Editor → New query → Run).
-- Then run seed.sql.

-- Supabase installs pgcrypto's functions into the `extensions` schema by
-- default, not `public` — schema-qualify every crypt()/gen_salt() call below
-- so it works regardless of search_path.
create extension if not exists pgcrypto with schema extensions;

-- ── Content tables (public read, service-role write only) ──────────────
create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  date date not null,
  pinned boolean not null default false,
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  date date,
  time text not null default '',
  place text not null default '',
  body text not null default '',
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.albums (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  date date,
  sample boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.photos (
  id uuid primary key default gen_random_uuid(),
  album_id uuid not null references public.albums(id) on delete cascade,
  caption text not null default '',
  tags text[] not null default '{}',
  storage_path text,      -- set for real uploads (path in the paksoc-media bucket)
  external_src text,      -- set only for seeded sample photos (inline SVG data URI)
  sample boolean not null default false,
  created_at timestamptz not null default now(),
  constraint photo_has_a_source check (storage_path is not null or external_src is not null)
);
create index photos_album_id_idx on public.photos(album_id);

create table public.crew_overrides (
  member_id text primary key,        -- matches CONFIG.committee[].id in index.html
  name text,
  has_img boolean not null default false,
  storage_path text,
  updated_at timestamptz not null default now()
);

create table public.charity_overrides (
  charity_id text primary key,       -- matches CONFIG.charities[].id in index.html
  org text,
  url text,
  blurb text,
  updated_at timestamptz not null default now()
);

-- Public, non-secret site state (highlight photo flag).
create table public.site_flags (
  id boolean primary key default true,
  highlight_img boolean not null default false,
  highlight_updated_at timestamptz,
  seeded boolean not null default false,
  constraint site_flags_singleton check (id)
);
insert into public.site_flags (id) values (true);

-- Passcode hash — never exposed to anon/authenticated, only touched by the
-- service-role key inside the dashboard-api Edge Function.
create table public.admin_settings (
  id boolean primary key default true,
  passcode_hash text not null,
  updated_at timestamptz not null default now(),
  constraint admin_settings_singleton check (id)
);
-- Seeds the current CONFIG.defaultPasscode ("paksoc2627"), hashed. Change it
-- via the dashboard's "Save passcode" once the site is live.
insert into public.admin_settings (id, passcode_hash)
  values (true, extensions.crypt('paksoc2627', extensions.gen_salt('bf', 8)));

-- ── Passcode check/change — service_role only ───────────────────────────
create or replace function public.verify_passcode(input text)
returns boolean
language sql security definer set search_path = public, extensions
as $$
  select passcode_hash = extensions.crypt(input, passcode_hash) from public.admin_settings where id = true;
$$;

create or replace function public.set_passcode(input text)
returns void
language sql security definer set search_path = public, extensions
as $$
  update public.admin_settings
    set passcode_hash = extensions.crypt(input, extensions.gen_salt('bf', 8)), updated_at = now()
    where id = true;
$$;

-- Supabase auto-exposes every public-schema function as a PostgREST RPC
-- endpoint reachable with the anon key by default — lock these two down so
-- nobody can call verify_passcode()/set_passcode() straight from the browser.
revoke all on function public.verify_passcode(text) from public, anon, authenticated;
revoke all on function public.set_passcode(text)    from public, anon, authenticated;
grant execute on function public.verify_passcode(text) to service_role;
grant execute on function public.set_passcode(text)    to service_role;

-- ── Row Level Security ───────────────────────────────────────────────────
alter table public.announcements     enable row level security;
alter table public.events            enable row level security;
alter table public.albums            enable row level security;
alter table public.photos            enable row level security;
alter table public.crew_overrides    enable row level security;
alter table public.charity_overrides enable row level security;
alter table public.site_flags        enable row level security;
alter table public.admin_settings    enable row level security;

create policy "public read" on public.announcements     for select using (true);
create policy "public read" on public.events             for select using (true);
create policy "public read" on public.albums              for select using (true);
create policy "public read" on public.photos              for select using (true);
create policy "public read" on public.crew_overrides       for select using (true);
create policy "public read" on public.charity_overrides    for select using (true);
create policy "public read" on public.site_flags           for select using (true);
-- admin_settings: deliberately NO policies. RLS enabled + zero policies means
-- anon/authenticated get zero access; service_role bypasses RLS entirely,
-- which is how the Edge Function reads/writes it.

-- No insert/update/delete policies anywhere: every write goes through the
-- dashboard-api Edge Function using the service-role key, which bypasses RLS.
-- anon/authenticated are denied all writes by default.

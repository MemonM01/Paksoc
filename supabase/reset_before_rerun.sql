-- One-time cleanup: undoes the partial run of schema.sql that failed on the
-- crypt() error, so schema.sql can be re-run cleanly from scratch. Only
-- needed once — delete this file (or ignore it) after you've re-run
-- schema.sql successfully.
drop table if exists public.photos cascade;
drop table if exists public.albums cascade;
drop table if exists public.announcements cascade;
drop table if exists public.events cascade;
drop table if exists public.crew_overrides cascade;
drop table if exists public.charity_overrides cascade;
drop table if exists public.site_flags cascade;
drop table if exists public.admin_settings cascade;
drop function if exists public.verify_passcode(text);
drop function if exists public.set_passcode(text);

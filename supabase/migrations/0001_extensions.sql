create schema if not exists extensions;
create schema if not exists private;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists btree_gist with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create extension if not exists citext with schema extensions;

grant usage on schema extensions to public;
revoke all on schema private from public, anon, authenticated;

alter default privileges in schema public revoke all on tables from anon, authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

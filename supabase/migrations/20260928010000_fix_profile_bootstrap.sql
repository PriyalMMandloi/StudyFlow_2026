-- Safe profile bootstrap fix for StudyFlow.
-- Purpose:
--   1) ensure every auth user has a valid profile row
--   2) ensure every auth user has an empty studyflow_user_data row
--   3) backfill missing profile values without deleting existing data
--   4) do not add a unique username constraint unless it is explicitly required
--      by app behavior and verified against the actual data set
--
-- This migration is intentionally non-destructive and safe to apply to the existing schema.
-- It does not modify auth UI, app behavior, or unrelated tables.

begin;

-- Backfill missing profile username/display_name values without overwriting real data.
alter table public.profiles
  add column if not exists username text;

update public.profiles
set username = trim(display_name)
where username is null or btrim(username) = '';

update public.profiles
set username = 'StudyFlow User'
where username is null or btrim(username) = '';

update public.profiles
set display_name = coalesce(
  nullif(trim(display_name), ''),
  username,
  'StudyFlow User'
)
where display_name is null or btrim(display_name) = '';

-- If there are existing duplicate usernames, keep this as a report-only check.
-- We intentionally avoid adding a unique constraint in this migration.
do $$
declare
  duplicate_count bigint;
begin
  select count(*)
  into duplicate_count
  from (
    select lower(trim(username)) as normalized_username
    from public.profiles
    where username is not null
      and btrim(username) <> ''
    group by lower(trim(username))
    having count(*) > 1
  ) duplicates;

  if duplicate_count > 0 then
    raise notice 'Duplicate usernames detected: %. No unique constraint was added by this migration.', duplicate_count;
  end if;
end $$;

-- Optional non-unique lookup index for username searches.
create index if not exists profiles_username_idx
  on public.profiles (username);

-- Ensure every auth user has a matching profile row.
insert into public.profiles (id, username, display_name)
select
  au.id,
  coalesce(
    nullif(trim(au.raw_user_meta_data ->> 'username'), ''),
    nullif(trim(au.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(au.raw_user_meta_data ->> 'name'), ''),
    split_part(au.email, '@', 1),
    'StudyFlow User'
  ) as username,
  coalesce(
    nullif(trim(au.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(au.raw_user_meta_data ->> 'name'), ''),
    split_part(au.email, '@', 1),
    'StudyFlow User'
  ) as display_name
from auth.users au
left join public.profiles p on p.id = au.id
where p.id is null
on conflict (id) do nothing;

-- Ensure every auth user has an empty studyflow_user_data row.
insert into public.studyflow_user_data (user_id, state)
select
  au.id,
  '{}'::jsonb
from auth.users au
left join public.studyflow_user_data d on d.user_id = au.id
where d.user_id is null
on conflict (user_id) do nothing;

-- Replace the trigger function with a safer bootstrap implementation.
create or replace function public.create_studyflow_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_username text;
  v_display_name text;
begin
  v_username := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
    split_part(new.email, '@', 1),
    'StudyFlow User'
  );

  v_display_name := coalesce(
    nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
    v_username,
    'StudyFlow User'
  );

  insert into public.profiles (id, username, display_name)
  values (new.id, v_username, v_display_name)
  on conflict (id) do nothing;

  insert into public.studyflow_user_data (user_id, state)
  values (new.id, '{}'::jsonb)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

revoke all on function public.create_studyflow_profile_for_new_user()
  from public, anon, authenticated;

drop trigger if exists on_auth_user_created_studyflow_profile on auth.users;
create trigger on_auth_user_created_studyflow_profile
after insert on auth.users
for each row execute function public.create_studyflow_profile_for_new_user();

commit;

-- Validation queries (safe, read-only):
-- 1) Profile row coverage
select
  au.id,
  au.email,
  p.username,
  p.display_name,
  p.avatar_url,
  d.user_id is not null as has_user_data_row
from auth.users au
left join public.profiles p on p.id = au.id
left join public.studyflow_user_data d on d.user_id = au.id
order by au.created_at desc;

-- 2) Missing profile data
select
  p.id,
  p.username,
  p.display_name
from public.profiles p
where p.username is null
   or btrim(p.username) = ''
   or p.display_name is null
   or btrim(p.display_name) = '';

-- 3) Missing studyflow_user_data rows
select
  au.id,
  au.email
from auth.users au
left join public.studyflow_user_data d on d.user_id = au.id
where d.user_id is null;

-- 4) Duplicate usernames (report only)
select
  lower(trim(username)) as normalized_username,
  count(*) as duplicate_count
from public.profiles
where username is not null
  and btrim(username) <> ''
group by lower(trim(username))
having count(*) > 1;

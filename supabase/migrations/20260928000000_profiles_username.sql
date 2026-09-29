alter table public.profiles
  add column if not exists username text;

update public.profiles
set username = trim(display_name)
where username is null or btrim(username) = '';

update public.profiles
set username = 'StudyFlow User'
where username is null or btrim(username) = '';

alter table public.profiles
  alter column username set not null;

create index if not exists profiles_username_idx
  on public.profiles (username);

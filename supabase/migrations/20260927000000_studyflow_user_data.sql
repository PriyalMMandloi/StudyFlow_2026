create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'StudyFlow User',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.studyflow_user_data (
  user_id uuid primary key references auth.users (id) on delete cascade,
  state jsonb not null default '{}'::jsonb
    check (jsonb_typeof(state) = 'object'),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.studyflow_user_data enable row level security;

create policy "Users can manage their own profile"
  on public.profiles
  for all
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Users can manage their own study data"
  on public.studyflow_user_data
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.studyflow_user_data to authenticated;

create or replace function public.create_studyflow_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      'StudyFlow User'
    )
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.create_studyflow_profile_for_new_user()
  from public, anon, authenticated;

drop trigger if exists on_auth_user_created_studyflow_profile on auth.users;
create trigger on_auth_user_created_studyflow_profile
after insert on auth.users
for each row execute function public.create_studyflow_profile_for_new_user();

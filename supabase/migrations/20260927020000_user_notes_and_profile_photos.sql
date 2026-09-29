create table if not exists public.study_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  subject text check (subject is null or char_length(btrim(subject)) <= 120),
  content text not null check (char_length(btrim(content)) between 1 and 50000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists study_notes_owner_updated_idx
  on public.study_notes (user_id, updated_at desc);

alter table public.study_notes enable row level security;

drop policy if exists "Users can manage their own study notes"
  on public.study_notes;
create policy "Users can manage their own study notes"
  on public.study_notes
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.study_notes to authenticated;

create or replace function public.set_study_note_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_study_note_updated_at()
  from public, anon, authenticated;

drop trigger if exists set_study_notes_updated_at on public.study_notes;
create trigger set_study_notes_updated_at
before update on public.study_notes
for each row execute function public.set_study_note_updated_at();

insert into public.study_notes (id, user_id, title, subject, content)
select
  md5(
    'legacy-study-note:' || user_data.user_id::text || ':' ||
      entry.ordinality::text
  )::uuid,
  user_data.user_id,
  btrim(entry.item ->> 'title'),
  nullif(btrim(entry.item ->> 'subject'), ''),
  btrim(entry.item ->> 'preview')
from public.studyflow_user_data as user_data
cross join lateral jsonb_array_elements(
  case
    when jsonb_typeof(user_data.state -> 'notes') = 'array'
      then user_data.state -> 'notes'
    else '[]'::jsonb
  end
) with ordinality as entry(item, ordinality)
where char_length(btrim(coalesce(entry.item ->> 'title', ''))) between 1 and 160
  and char_length(btrim(coalesce(entry.item ->> 'preview', ''))) between 1 and 50000
  and char_length(btrim(coalesce(entry.item ->> 'subject', ''))) <= 120
  and not (
    (entry.item ->> 'title' = 'IP — Chapter 1'
      and entry.item ->> 'subject' = 'Information Practices'
      and entry.item ->> 'preview' =
        'Introduction to Python and basic concepts...')
    or (entry.item ->> 'title' = 'SQL Commands'
      and entry.item ->> 'subject' = 'Database'
      and entry.item ->> 'preview' =
        'SELECT, INSERT, UPDATE and DELETE...')
    or (entry.item ->> 'title' = 'ML Revision'
      and entry.item ->> 'subject' = 'Machine Learning'
      and entry.item ->> 'preview' =
        'Important concepts for upcoming revision...')
  )
on conflict (id) do nothing;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-photos',
  'profile-photos',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']::text[]
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can view their own profile photos"
  on storage.objects;
create policy "Users can view their own profile photos"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Users can upload their own profile photos"
  on storage.objects;
create policy "Users can upload their own profile photos"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Users can update their own profile photos"
  on storage.objects;
create policy "Users can update their own profile photos"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "Users can delete their own profile photos"
  on storage.objects;
create policy "Users can delete their own profile photos"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

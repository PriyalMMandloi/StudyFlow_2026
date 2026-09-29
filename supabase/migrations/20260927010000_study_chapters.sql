create table if not exists public.study_chapters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  subject text not null check (char_length(btrim(subject)) between 1 and 120),
  description text,
  estimated_minutes integer not null default 30
    check (estimated_minutes between 1 and 10080),
  sort_order integer not null default 0 check (sort_order >= 0),
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, user_id)
);

insert into public.study_chapters (
  id,
  user_id,
  title,
  subject,
  estimated_minutes,
  sort_order,
  is_completed,
  completed_at
)
select
  md5('legacy-study-plan:' || user_data.user_id::text || ':' ||
    (entry.item ->> 'id'))::uuid,
  user_data.user_id,
  btrim(entry.item ->> 'title'),
  btrim(entry.item ->> 'subject'),
  case
    when (entry.item ->> 'durationMinutes') ~ '^[0-9]{1,5}$' then
      case
        when (entry.item ->> 'durationMinutes')::integer between 1 and 10080
          then (entry.item ->> 'durationMinutes')::integer
        else 30
      end
    else 30
  end,
  (entry.ordinality - 1)::integer,
  coalesce((entry.item ->> 'completed') = 'true', false),
  case
    when entry.item ->> 'completed' = 'true' then now()
    else null
  end
from public.studyflow_user_data as user_data
cross join lateral jsonb_array_elements(
  case
    when jsonb_typeof(user_data.state -> 'plannerTasks') = 'array'
      then user_data.state -> 'plannerTasks'
    else '[]'::jsonb
  end
) with ordinality as entry(item, ordinality)
where nullif(btrim(entry.item ->> 'id'), '') is not null
  and entry.item ->> 'id' not in (
    'seed-chapter-1',
    'seed-chapter-2',
    'seed-sql'
  )
  and char_length(btrim(coalesce(entry.item ->> 'title', ''))) between 1 and 160
  and char_length(btrim(coalesce(entry.item ->> 'subject', ''))) between 1 and 120
on conflict (id) do nothing;

create table if not exists public.study_chapter_tasks (
  id uuid primary key default gen_random_uuid(),
  chapter_id uuid not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 160),
  estimated_minutes integer check (
    estimated_minutes is null or estimated_minutes between 1 and 10080
  ),
  sort_order integer not null default 0 check (sort_order >= 0),
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (chapter_id, user_id)
    references public.study_chapters (id, user_id)
    on delete cascade
);

create index if not exists study_chapters_user_order_idx
  on public.study_chapters (user_id, sort_order, created_at);
create index if not exists study_chapter_tasks_owner_chapter_order_idx
  on public.study_chapter_tasks (user_id, chapter_id, sort_order, created_at);

alter table public.study_chapters enable row level security;
alter table public.study_chapter_tasks enable row level security;

create policy "Users can manage their own study chapters"
  on public.study_chapters
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can manage tasks in their own chapters"
  on public.study_chapter_tasks
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.study_chapters to authenticated;
grant select, insert, update, delete on public.study_chapter_tasks to authenticated;

create or replace function public.set_study_plan_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_study_plan_updated_at()
  from public, anon, authenticated;

drop trigger if exists set_study_chapters_updated_at on public.study_chapters;
create trigger set_study_chapters_updated_at
before update on public.study_chapters
for each row execute function public.set_study_plan_updated_at();

drop trigger if exists set_study_chapter_tasks_updated_at on public.study_chapter_tasks;
create trigger set_study_chapter_tasks_updated_at
before update on public.study_chapter_tasks
for each row execute function public.set_study_plan_updated_at();

create or replace function public.reorder_study_chapters(p_chapter_ids uuid[])
returns void
language plpgsql
set search_path = ''
as $$
declare
  owner_id uuid := (select auth.uid());
  requested_count integer;
  owned_count integer;
begin
  if owner_id is null or p_chapter_ids is null then
    raise exception 'An authenticated user and chapter list are required.'
      using errcode = '22023';
  end if;

  select count(*) into requested_count
  from unnest(p_chapter_ids) as requested(chapter_id);

  select count(distinct chapter_id) into owned_count
  from unnest(p_chapter_ids) as requested(chapter_id)
  join public.study_chapters chapter
    on chapter.id = requested.chapter_id
   and chapter.user_id = owner_id;

  if requested_count <> owned_count or requested_count <> (
    select count(*) from public.study_chapters chapter
    where chapter.user_id = owner_id
  ) then
    raise exception 'The chapter list must contain every owned chapter exactly once.'
      using errcode = '22023';
  end if;

  update public.study_chapters chapter
  set sort_order = requested.ordinality - 1
  from unnest(p_chapter_ids) with ordinality
    as requested(chapter_id, ordinality)
  where chapter.id = requested.chapter_id
    and chapter.user_id = owner_id;
end;
$$;

revoke all on function public.reorder_study_chapters(uuid[])
  from public, anon;
grant execute on function public.reorder_study_chapters(uuid[])
  to authenticated;

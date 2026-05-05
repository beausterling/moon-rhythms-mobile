-- Moon Rhythms Mobile core schema
-- Safe to run in a Supabase project that already has auth enabled.

create extension if not exists "pgcrypto";

-- Profiles are owned 1:1 by auth.users.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  birth_date date,
  birth_time time,
  birth_timezone text,
  birth_location_name text,
  birth_latitude double precision,
  birth_longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Saved natal / Human Design readings.
create table if not exists public.birth_readings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text,
  birth_date date not null,
  birth_time time,
  birth_timezone text,
  birth_location_name text,
  birth_latitude double precision,
  birth_longitude double precision,
  chart_payload jsonb not null default '{}'::jsonb,
  human_design_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists birth_readings_user_created_idx
  on public.birth_readings(user_id, created_at desc);

-- Saved personality quiz results.
create table if not exists public.quiz_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  quiz_type text not null check (quiz_type in ('mbti', 'big_five', 'enneagram', 'disc')),
  result_code text,
  scores jsonb not null default '{}'::jsonb,
  answers jsonb not null default '[]'::jsonb,
  result_payload jsonb not null default '{}'::jsonb,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists quiz_results_user_completed_idx
  on public.quiz_results(user_id, completed_at desc);

create index if not exists quiz_results_user_type_idx
  on public.quiz_results(user_id, quiz_type);

-- User notification preferences.
create table if not exists public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  moon_sign_notifications_enabled boolean not null default true,
  quiet_hours_start time,
  quiet_hours_end time,
  timezone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Shared updated_at trigger.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger birth_readings_set_updated_at
  before update on public.birth_readings
  for each row execute function public.set_updated_at();

create trigger quiz_results_set_updated_at
  before update on public.quiz_results
  for each row execute function public.set_updated_at();

create trigger notification_preferences_set_updated_at
  before update on public.notification_preferences
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.birth_readings enable row level security;
alter table public.quiz_results enable row level security;
alter table public.notification_preferences enable row level security;

-- Profiles RLS
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Birth readings RLS
create policy "birth_readings_select_own"
  on public.birth_readings for select
  using (auth.uid() = user_id);

create policy "birth_readings_insert_own"
  on public.birth_readings for insert
  with check (auth.uid() = user_id);

create policy "birth_readings_update_own"
  on public.birth_readings for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "birth_readings_delete_own"
  on public.birth_readings for delete
  using (auth.uid() = user_id);

-- Quiz results RLS
create policy "quiz_results_select_own"
  on public.quiz_results for select
  using (auth.uid() = user_id);

create policy "quiz_results_insert_own"
  on public.quiz_results for insert
  with check (auth.uid() = user_id);

create policy "quiz_results_update_own"
  on public.quiz_results for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "quiz_results_delete_own"
  on public.quiz_results for delete
  using (auth.uid() = user_id);

-- Notification preferences RLS
create policy "notification_preferences_select_own"
  on public.notification_preferences for select
  using (auth.uid() = user_id);

create policy "notification_preferences_insert_own"
  on public.notification_preferences for insert
  with check (auth.uid() = user_id);

create policy "notification_preferences_update_own"
  on public.notification_preferences for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

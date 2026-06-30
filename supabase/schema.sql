create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  nickname text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  device_name text not null default '',
  platform text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, device_id)
);

create table if not exists public.game_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  game_name text not null,
  selected_character text not null default '',
  selected_team_key text not null default '',
  preferences_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  game_name text not null,
  character_or_team_key text not null,
  opponent_nick text not null default '',
  opponent_character text not null default '',
  result text not null default '',
  score text not null default '',
  match_data_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.character_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  game_name text not null,
  character_or_team_key text not null,
  rank_name text not null default '',
  pdl integer not null default 0,
  stats_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  preferences_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  favorite_type text not null,
  game_name text not null default '',
  target_key text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.sync_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  entity_type text not null,
  entity_id uuid not null,
  operation text not null,
  status text not null default 'pending',
  error_message text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_user_id_idx
  on public.profiles (user_id);

create index if not exists devices_user_device_idx
  on public.devices (user_id, device_id);

create index if not exists game_profiles_user_game_idx
  on public.game_profiles (user_id, game_name);

create index if not exists matches_user_game_updated_idx
  on public.matches (user_id, game_name, updated_at desc);

create index if not exists character_progress_user_game_key_idx
  on public.character_progress (user_id, game_name, character_or_team_key);

create index if not exists user_preferences_user_idx
  on public.user_preferences (user_id);

create index if not exists favorites_user_target_idx
  on public.favorites (user_id, favorite_type, game_name, target_key);

create index if not exists sync_events_user_status_idx
  on public.sync_events (user_id, status, updated_at desc);

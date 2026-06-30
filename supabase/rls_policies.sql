alter table public.profiles enable row level security;
alter table public.devices enable row level security;
alter table public.game_profiles enable row level security;
alter table public.matches enable row level security;
alter table public.character_progress enable row level security;
alter table public.user_preferences enable row level security;
alter table public.favorites enable row level security;
alter table public.sync_events enable row level security;

create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = user_id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = user_id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "profiles_delete_own"
  on public.profiles for delete
  using (auth.uid() = user_id);

create policy "devices_select_own"
  on public.devices for select
  using (auth.uid() = user_id);

create policy "devices_insert_own"
  on public.devices for insert
  with check (auth.uid() = user_id);

create policy "devices_update_own"
  on public.devices for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "devices_delete_own"
  on public.devices for delete
  using (auth.uid() = user_id);

create policy "game_profiles_select_own"
  on public.game_profiles for select
  using (auth.uid() = user_id);

create policy "game_profiles_insert_own"
  on public.game_profiles for insert
  with check (auth.uid() = user_id);

create policy "game_profiles_update_own"
  on public.game_profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "game_profiles_delete_own"
  on public.game_profiles for delete
  using (auth.uid() = user_id);

create policy "matches_select_own"
  on public.matches for select
  using (auth.uid() = user_id);

create policy "matches_insert_own"
  on public.matches for insert
  with check (auth.uid() = user_id);

create policy "matches_update_own"
  on public.matches for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "matches_delete_own"
  on public.matches for delete
  using (auth.uid() = user_id);

create policy "character_progress_select_own"
  on public.character_progress for select
  using (auth.uid() = user_id);

create policy "character_progress_insert_own"
  on public.character_progress for insert
  with check (auth.uid() = user_id);

create policy "character_progress_update_own"
  on public.character_progress for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "character_progress_delete_own"
  on public.character_progress for delete
  using (auth.uid() = user_id);

create policy "user_preferences_select_own"
  on public.user_preferences for select
  using (auth.uid() = user_id);

create policy "user_preferences_insert_own"
  on public.user_preferences for insert
  with check (auth.uid() = user_id);

create policy "user_preferences_update_own"
  on public.user_preferences for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "user_preferences_delete_own"
  on public.user_preferences for delete
  using (auth.uid() = user_id);

create policy "favorites_select_own"
  on public.favorites for select
  using (auth.uid() = user_id);

create policy "favorites_insert_own"
  on public.favorites for insert
  with check (auth.uid() = user_id);

create policy "favorites_update_own"
  on public.favorites for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "favorites_delete_own"
  on public.favorites for delete
  using (auth.uid() = user_id);

create policy "sync_events_select_own"
  on public.sync_events for select
  using (auth.uid() = user_id);

create policy "sync_events_insert_own"
  on public.sync_events for insert
  with check (auth.uid() = user_id);

create policy "sync_events_update_own"
  on public.sync_events for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "sync_events_delete_own"
  on public.sync_events for delete
  using (auth.uid() = user_id);

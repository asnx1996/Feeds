-- رضعات سما: جدول الرضعات + الصلاحيات + التزامن المباشر
-- شغّل هذا الملف مرة وحدة في Supabase: SQL Editor > New query > Run

create table if not exists public.feeds (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  fed_at      timestamptz not null default now(),
  amount_ml   integer not null check (amount_ml > 0 and amount_ml <= 1000),
  formula_no  text,
  given_by    text,
  note        text,
  created_at  timestamptz not null default now()
);

create index if not exists feeds_user_time_idx on public.feeds (user_id, fed_at desc);

-- الصلاحيات: كل حساب يشوف ويعدل رضعاته بس
alter table public.feeds enable row level security;

drop policy if exists "feeds_select_own" on public.feeds;
drop policy if exists "feeds_insert_own" on public.feeds;
drop policy if exists "feeds_update_own" on public.feeds;
drop policy if exists "feeds_delete_own" on public.feeds;

create policy "feeds_select_own" on public.feeds
  for select to authenticated using (auth.uid() = user_id);

create policy "feeds_insert_own" on public.feeds
  for insert to authenticated with check (auth.uid() = user_id);

create policy "feeds_update_own" on public.feeds
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "feeds_delete_own" on public.feeds
  for delete to authenticated using (auth.uid() = user_id);

-- التزامن المباشر بين الموبايلين
alter publication supabase_realtime add table public.feeds;

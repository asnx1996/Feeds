-- رضعات: الأطفال + معلومات الولادة + القياسات الأسبوعية + نوع الرضاعة
-- شغّل هذا الملف مرة وحدة بعد schema.sql في Supabase: SQL Editor > New query > Run
-- الرضعات القديمة تبقى زي ما هي (نوعها صناعي، والتطبيق يربطها بأول طفل تضيفه).

-- ================= الأطفال =================
create table if not exists public.children (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name             text not null check (char_length(name) between 1 and 40),
  sex              text check (sex in ('girl','boy')),
  birth_at         timestamptz,
  birth_weight_g   integer check (birth_weight_g between 300 and 8000),
  birth_length_cm  numeric(4,1) check (birth_length_cm between 20 and 70),
  birth_head_cm    numeric(4,1) check (birth_head_cm between 15 and 50),
  delivery_type    text check (delivery_type in ('natural','csection')),
  gestation_weeks  integer check (gestation_weeks between 20 and 45),
  hospital         text,
  blood_type       text,
  notes            text,
  created_at       timestamptz not null default now()
);

create index if not exists children_user_idx on public.children (user_id, created_at);

alter table public.children enable row level security;

drop policy if exists "children_select_own" on public.children;
drop policy if exists "children_insert_own" on public.children;
drop policy if exists "children_update_own" on public.children;
drop policy if exists "children_delete_own" on public.children;

create policy "children_select_own" on public.children
  for select to authenticated using (auth.uid() = user_id);
create policy "children_insert_own" on public.children
  for insert to authenticated with check (auth.uid() = user_id);
create policy "children_update_own" on public.children
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "children_delete_own" on public.children
  for delete to authenticated using (auth.uid() = user_id);

-- ================= القياسات (وزن / طول / محيط الراس) =================
create table if not exists public.growth (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  child_id     uuid not null references public.children(id) on delete cascade,
  measured_on  date not null default current_date,
  weight_g     integer check (weight_g between 300 and 40000),
  length_cm    numeric(4,1) check (length_cm between 20 and 150),
  head_cm      numeric(4,1) check (head_cm between 15 and 60),
  note         text,
  created_at   timestamptz not null default now(),
  check (weight_g is not null or length_cm is not null or head_cm is not null)
);

create index if not exists growth_child_idx on public.growth (child_id, measured_on);

alter table public.growth enable row level security;

drop policy if exists "growth_select_own" on public.growth;
drop policy if exists "growth_insert_own" on public.growth;
drop policy if exists "growth_update_own" on public.growth;
drop policy if exists "growth_delete_own" on public.growth;

create policy "growth_select_own" on public.growth
  for select to authenticated using (auth.uid() = user_id);
create policy "growth_insert_own" on public.growth
  for insert to authenticated with check (auth.uid() = user_id);
create policy "growth_update_own" on public.growth
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "growth_delete_own" on public.growth
  for delete to authenticated using (auth.uid() = user_id);

-- ================= الرضعات: الطفل + نوع الرضاعة =================
alter table public.feeds
  add column if not exists child_id     uuid references public.children(id) on delete cascade,
  add column if not exists feed_type    text not null default 'formula',
  add column if not exists duration_min integer,
  add column if not exists breast_side  text;

-- الرضاعة الطبيعية ما بيها مل، تنسجل بالدقايق
alter table public.feeds alter column amount_ml drop not null;

alter table public.feeds drop constraint if exists feeds_type_chk;
alter table public.feeds drop constraint if exists feeds_duration_chk;
alter table public.feeds drop constraint if exists feeds_side_chk;
alter table public.feeds drop constraint if exists feeds_amount_by_type_chk;
alter table public.feeds drop constraint if exists feeds_duration_by_type_chk;

alter table public.feeds
  add constraint feeds_type_chk check (feed_type in ('formula','breast')),
  add constraint feeds_duration_chk check (duration_min is null or duration_min between 1 and 300),
  add constraint feeds_side_chk check (breast_side is null or breast_side in ('right','left','both')),
  add constraint feeds_amount_by_type_chk check (feed_type <> 'formula' or amount_ml is not null),
  add constraint feeds_duration_by_type_chk check (feed_type <> 'breast' or duration_min is not null);

create index if not exists feeds_child_time_idx on public.feeds (child_id, fed_at desc);

-- ================= التزامن المباشر =================
alter publication supabase_realtime add table public.children, public.growth;

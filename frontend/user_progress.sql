-- Kullanıcının tamamladığı görevler ve kazandığı mühürler (giriş yapanlar için bulut yedeği).
create table if not exists public.user_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('activity','stamp')),
  ref_id bigint not null,
  created_at timestamptz default now(),
  primary key (user_id, kind, ref_id)
);

alter table public.user_progress enable row level security;

drop policy if exists "ilerleme: kendi satirlarini oku" on public.user_progress;
create policy "ilerleme: kendi satirlarini oku" on public.user_progress
  for select using (auth.uid() = user_id);
drop policy if exists "ilerleme: kendi satirini ekle" on public.user_progress;
create policy "ilerleme: kendi satirini ekle" on public.user_progress
  for insert with check (auth.uid() = user_id);
drop policy if exists "ilerleme: kendi satirini sil" on public.user_progress;
create policy "ilerleme: kendi satirini sil" on public.user_progress
  for delete using (auth.uid() = user_id);
-- upsert (conflict durumunda güncelleme) için güncelleme politikası da gerekir
drop policy if exists "ilerleme: kendi satirini guncelle" on public.user_progress;
create policy "ilerleme: kendi satirini guncelle" on public.user_progress
  for update using (auth.uid() = user_id);

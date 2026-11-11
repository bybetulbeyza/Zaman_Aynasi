-- Kullanıcı profilleri (auth.users ile bire bir)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  preferred_lang text default 'tr',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "profil: kendi satirini oku" on public.profiles
  for select using (auth.uid() = id);
create policy "profil: kendi satirini ekle" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profil: kendi satirini guncelle" on public.profiles
  for update using (auth.uid() = id);

-- Yeni kayıtta profil satırını otomatik oluştur
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, display_name, avatar_url)
  values (
    new.id, new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture')
  ) on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Güvenlik: RLS (satır düzeyi güvenlik) kapalı tablolar, uygulamanın herkese açık anahtarıyla
-- herkes tarafından değiştirilebilir/silinebilir. Aşağısı içerik tablolarını SALT OKUNUR yapar;
-- uygulama yalnızca okuyor, siz içeriği SQL Editor / panelden değiştirmeye devam edersiniz.

-- 1) İçerik tabloları: herkes okur, kimse yazamaz (panel ve SQL Editor RLS'i atlar)
alter table public.heritage_places   enable row level security;
alter table public."Hotspots"        enable row level security;
alter table public.place_activities  enable row level security;

drop policy if exists "herkes okuyabilir" on public.heritage_places;
create policy "herkes okuyabilir" on public.heritage_places for select using (true);
drop policy if exists "herkes okuyabilir" on public."Hotspots";
create policy "herkes okuyabilir" on public."Hotspots" for select using (true);
drop policy if exists "aktiviteler: herkes okuyabilir" on public.place_activities;
create policy "aktiviteler: herkes okuyabilir" on public.place_activities for select using (true);

-- 2) Profiller: herkes yalnızca KENDİ satırını görür/yazar (e-postalar korunur)
alter table public.profiles enable row level security;
drop policy if exists "profil: kendi satirini oku" on public.profiles;
create policy "profil: kendi satirini oku" on public.profiles for select using (auth.uid() = id);
drop policy if exists "profil: kendi satirini ekle" on public.profiles;
create policy "profil: kendi satirini ekle" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "profil: kendi satirini guncelle" on public.profiles;
create policy "profil: kendi satirini guncelle" on public.profiles for update using (auth.uid() = id);

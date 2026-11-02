-- Anonim kullanım sayacı (jüri geri bildirimi için). Ad/e-posta/konum tutulmaz.
-- Supabase > SQL Editor'da çalıştırın.

create table if not exists public.analytics_events (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  event       text not null check (char_length(event) <= 40),
  place_id    text check (char_length(place_id) <= 20),
  device_id   text not null check (char_length(device_id) <= 40),  -- rastgele, cihaza özel
  session_id  text check (char_length(session_id) <= 40),
  lang        text check (lang in ('tr', 'en')),
  meta        jsonb
);

create index if not exists analytics_events_event_idx on public.analytics_events (event, created_at);
create index if not exists analytics_events_place_idx on public.analytics_events (place_id);

-- Uygulama (anon) yalnızca EKLEYEBİLİR; okuma/silme/güncelleme izni yoktur.
alter table public.analytics_events enable row level security;
drop policy if exists "analytics insert only" on public.analytics_events;
create policy "analytics insert only" on public.analytics_events
  for insert to anon, authenticated with check (true);

-- Rapor görünümleri: SQL Editor / Table Editor'dan sizin görmeniz için. Herkese kapalı.
create or replace view public.analytics_summary as
  select event, count(*) as toplam, count(distinct device_id) as farkli_cihaz
  from public.analytics_events group by event order by toplam desc;

-- Envanter yayınlarına (cilt sitesi) tıklama: günlük, nereden (eser kartı / hakkında)
create or replace view public.analytics_inventory_clicks as
  select (created_at at time zone 'Europe/Istanbul')::date as gun,
         meta->>'from' as kaynak,
         count(*) as tiklama,
         count(distinct device_id) as farkli_cihaz
  from public.analytics_events where event = 'inventory_click'
  group by 1, 2 order by 1 desc, 3 desc;

-- En çok bakılan eserler
create or replace view public.analytics_top_places as
  select e.place_id, p.name as eser, count(*) as goruntuleme, count(distinct e.device_id) as farkli_cihaz
  from public.analytics_events e
  left join public.heritage_places p on p.id::text = e.place_id
  where e.event = 'place_view'
  group by e.place_id, p.name order by goruntuleme desc;

-- Günlük aktif cihaz
create or replace view public.analytics_daily_active as
  select (created_at at time zone 'Europe/Istanbul')::date as gun,
         count(distinct device_id) as aktif_cihaz,
         count(*) as olay
  from public.analytics_events group by 1 order by 1 desc;

-- Görünümler API üzerinden açık olmasın
revoke all on public.analytics_summary, public.analytics_inventory_clicks,
              public.analytics_top_places, public.analytics_daily_active
  from anon, authenticated;

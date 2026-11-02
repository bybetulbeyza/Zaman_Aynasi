-- Hotspot id'lerini eser sırasına göre art arda yeniden numaralar: önce 1. eserin tüm hotspot'ları, sonra 2. eserinkiler...
-- (Her eserin içindeki sıra eski id sırasıdır.) Eser id'leri zaten 1-23 art arda.
--
-- ÖNCE: Table Editor > Hotspots > Export to CSV ile yedek alın.
-- SIRA: Bu dosyayı, diğer hotspot dosyaları (db_cleanup, hotspots_2d_3d, koza_han_hotspots, model_hotspots, hotspots_sides_fix)
--       çalıştırıldıktan SONRA çalıştırın. Boşlukları kapatmak için istediğiniz kadar tekrar çalıştırılabilir.
begin;

-- 1) Çakışmayı önlemek için hepsini uzağa taşı
update public."Hotspots" set id = id + 1000000;

-- 2) Eser numarasına, sonra eski sıraya göre 1'den başlayarak yeniden ver
with sirali as (
  select id, row_number() over (order by place_id, id) as yeni
  from public."Hotspots"
)
update public."Hotspots" h set id = s.yeni from sirali s where h.id = s.id;

-- 3) Bundan sonra yeni satırlarda id otomatik üretilsin (artık elle vermek gerekmez)
create sequence if not exists public.hotspots_id_seq owned by public."Hotspots".id;
select setval('public.hotspots_id_seq', (select coalesce(max(id), 1) from public."Hotspots"));
alter table public."Hotspots" alter column id set default nextval('public.hotspots_id_seq');

commit;

-- Kontrol: eserler art arda, kopukluk yok
-- select place_id, min(id) as ilk, max(id) as son, count(*) from public."Hotspots" group by place_id order by place_id;

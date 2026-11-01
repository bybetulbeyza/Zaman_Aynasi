-- 3B model hotspot'ları: mevcut Hotspots tablosuna iki sütun eklenir.
--   model_pos    = "x y z" (metre, model orijini zemin ortası)
--   model_normal = yüzeyin baktığı yön
-- model_pos dolu olan satırlar 3B görünümde de çıkar. Fotoğraf konumu (x_percent/y_percent) olan
-- satırlar fotoğrafta da kalır; target_side = 'model' olanlar yalnızca 3B'dedir.
alter table public."Hotspots"
  add column if not exists model_pos text,
  add column if not exists model_normal text;

-- 1) Var olan Yeşil Türbe hotspot'larına 3B konumu ver (yeni satır açılmaz). Cephe -Z yönünde.
update public."Hotspots" set model_pos = '0 8.4 -12.7',  model_normal = '0 0 -1'
  where place_id = 11 and id = 48;  -- Mukarnaslı Taç Kapı Kavsarası
update public."Hotspots" set model_pos = '0 5.9 -12.7',  model_normal = '0 0 -1'
  where place_id = 11 and id = 49;  -- Giriş Kapısı Üzerindeki Kitabe
update public."Hotspots" set model_pos = '6.9 7.8 -7.6', model_normal = '0.7 0 -0.7'
  where place_id = 11 and id = 46;  -- Pencereler

-- 2) Envanterde karşılığı olmayan, yalnızca 3B'de anlamlı iki yeni nokta (id elle verilir).
insert into public."Hotspots"
  (id, place_id, title, description, title_en, description_en, target_side, x_percent, y_percent, model_pos, model_normal)
select coalesce(max(id), 0) + v.n, 11, v.title, v.descr, v.title_en, v.descr_en, 'model', 0, 0, v.pos, v.nrm
from public."Hotspots",
(values
 (1, 'Kasnak',
  'Kubbeyi taşıyan sekizgen kasnakta sekiz pencere bulunur; türbenin toplam yirmi iki penceresinin sekizi buradadır.',
  'The Drum',
  'The octagonal drum carrying the dome has eight windows, eight of the tomb’s twenty-two in total.',
  '0 15.9 -9.4', '0 0 -1'),
 (2, 'Kubbe',
  'Çelebi Mehmed’in turkuaz çinilerle kaplı sekizgen anıt türbesi kubbeyle örtülüdür. Parlak firuze çini yüzey, yapının en dikkat çeken özelliğidir.',
  'The Dome',
  'Çelebi Mehmed’s octagonal monumental tomb, clad in turquoise tiles, is covered with a dome. The bright turquoise tile surface is the building’s most striking feature.',
  '0 21.7 -8.2', '0 0.72 -0.69')
) as v(n, title, descr, title_en, descr_en, pos, nrm)
group by v.n, v.title, v.descr, v.title_en, v.descr_en, v.pos, v.nrm;

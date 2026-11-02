-- Hotspot'ların hem fotoğrafta (2B) hem modelde (3B) görünmesi.
-- target_side: 'after' = sol (tarihî) fotoğraf, 'before' = sağ (günümüz) fotoğraf; x/y fotoğrafın sol üstünden 0-1.
-- model_pos / model_normal: modelde konum (metre) ve yüzey yönü. Cephe -Z yönünde.

-- 1) Yeşil Türbe: Kasnak ve Kubbe yalnızca 3B'deydi; tarihî fotoğrafta da konum ver.
update public."Hotspots" set target_side = 'after', x_percent = 0.47, y_percent = 0.46
  where place_id = 11 and title = 'Kasnak';
update public."Hotspots" set target_side = 'after', x_percent = 0.47, y_percent = 0.28
  where place_id = 11 and title = 'Kubbe';

-- 2) Koza Han: envanterden iki yeni hotspot (tarihî fotoğraf + model). id elle verilir.
insert into public."Hotspots"
  (id, place_id, title, description, title_en, description_en, target_side, x_percent, y_percent, model_pos, model_normal)
select coalesce(max(id), 0) + v.n, 5, v.title, v.descr, v.title_en, v.descr_en, 'after', v.x, v.y, v.pos, v.nrm
from public."Hotspots",
(values
 (1, 'Köşk Mescidin Şadırvanı',
  'Mescidin altındaki havuz çokgen biçimli bir şadırvandır. Havuzun ortasında sekiz kenarlı, stalaktik başlıklı bir ayak yükselir ve her yüzündeki borudan havuza su akar. Mihrabın altına denk gelen kısımda abdest muslukları bulunur. Mescide, geometrik şebekeli mermer korkuluklu on dört basamaklı bir merdivenle çıkılır. Kaynak: Cilt 1, s. 388.',
  'The Fountain of the Pavilion Masjid',
  'The pool beneath the masjid is a polygonal fountain. An eight-sided pier with a stalactite capital rises in its centre, and water pours into the pool from a pipe on each face. Ablution taps are placed beneath the mihrab. The masjid is reached by a fourteen-step marble staircase with geometrically pierced marble balustrades. Source: Vol. 1, p. 388.',
  0.59::double precision, 0.68::double precision, '0 3 -3.3', '0 0 -1'),
 (2, 'Ahşap Üst Kat Revakı',
  'Hanın ahşap malzemeden yapılmış üst kat revakı, 1950’li yıllarda Bursa Eski Eserleri Sevenler Kurumu tarafından onarılmış, aynı çalışmada ahırlar bölümü de elden geçirilmiştir. Bugün üst katta ipek ticareti yapan işletmeler, alt katta ise çeşitli ürünler satan esnaf yer alır. Kaynak: Cilt 2, s. 21.',
  'The Wooden Upper-Floor Arcade',
  'The han’s upper-floor arcade, built of wood, was repaired by the Bursa Association for the Appreciation of Antiquities in the 1950s, and the stables were overhauled in the same work. Today silk traders occupy the upper floor and shopkeepers selling various goods the lower floor. Source: Vol. 2, p. 21.',
  0.40::double precision, 0.34::double precision, '-12 6.2 18.4', '0 0 -1')
) as v(n, title, descr, title_en, descr_en, x, y, pos, nrm)
group by v.n, v.title, v.descr, v.title_en, v.descr_en, v.x, v.y, v.pos, v.nrm;

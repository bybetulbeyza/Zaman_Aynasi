-- Veritabanı temizliği (denetimden çıkan sorunlar). Güvenle yeniden çalıştırılabilir.

-- 1) Başında/sonunda boşluk ya da satır sonu kalan değerler (bozuk görsel adresi ve kategori eşleşmesi riski)
update public.heritage_places set image_before_url = btrim(image_before_url, E' \n\r\t') where image_before_url <> btrim(image_before_url, E' \n\r\t');
update public.heritage_places set image_after_url  = btrim(image_after_url,  E' \n\r\t') where image_after_url  <> btrim(image_after_url,  E' \n\r\t');
update public.heritage_places set category         = btrim(category,         E' \n\r\t') where category         <> btrim(category,         E' \n\r\t');
update public."Hotspots" set title       = btrim(title,       E' \n\r\t') where title       <> btrim(title,       E' \n\r\t');
update public."Hotspots" set description = btrim(description, E' \n\r\t') where description <> btrim(description, E' \n\r\t');

-- 2) Ulu Camii'nin 80-82 numaralı hotspot'ları: fotoğraf konumu yoktu (sol üst köşede çıkıyordu) ve İngilizceleri eksikti.
--    Konumlar tarihî fotoğraf (target_side = 'after') üzerinde yaklaşık; gerekirse x/y oynatın.
update public."Hotspots" set x_percent = 0.17, y_percent = 0.35,
  title = 'Kuşbakışı Minareler', title_en = 'Minarets from Above',
  description_en = 'Evliya Çelebi called the Ulucami “the Hagia Sophia of Bursa.” It was the first great mosque the Ottomans built in Bursa and remained the city’s largest mosque for six centuries. At its opening on a Friday in 1399, Somuncu Baba, who made his living baking and selling bread from his own oven, was among those present; there he interpreted the Surah al-Fatiha on seven different levels. Its first imam was Süleyman Çelebi, the author of the Mevlid. Seen from above, one of the two minarets stands out: the eastern one, left unfinished in the first construction and used incomplete for a while, became known as the “Stump Minaret” (Güdük Minare).'
  where place_id = 9 and title like 'Kuşbakışı Minareler%';
update public."Hotspots" set x_percent = 0.66, y_percent = 0.46,
  title_en = 'The Mihrab of the Exiled Pasha',
  description_en = 'The mihrab’s decorations were commissioned by Tevfik Pasha, who was exiled to Bursa in 1862. The niche is framed by four friezes: one is a Kufic inscription band, one a stylised motif band, and two carry floral ornament. In the teardrop-shaped field of the lamp depiction with a rumi motif at the centre of the spandrels, a verse is written in thuluth script in the müsennâ (mirrored) style.'
  where place_id = 9 and title like 'Sürgündeki Paşanın Mihrabı%';
update public."Hotspots" set x_percent = 0.30, y_percent = 0.50,
  title_en = 'Domes and Calligraphy from Inside',
  description_en = 'On each face of the twelve piers that carry the domes, examples of the Asma al-Husna are written in celi thuluth and Kufic scripts. In 1630 Evliya Çelebi saw the inscriptions “Yâ Hannân, Yâ Mennân, Yâ Deyyân, Yâ Sübhân” on these piers. The alifs of the letters are about 55 cm long. The inscriptions are by calligraphers such as Abdülfettah Efendi, Kazasker Mustafa İzzet Efendi, Sâmi Efendi and Mehmed Şefik Bey. It is not known whether the roughly one hundred and seventy calligraphic panels in the mosque date from the original construction. After the 1855 earthquake some were restored and some were erased and rewritten.'
  where place_id = 9 and title like 'İç Taraftan Kubbeler%';

-- 3) Sesli rehber İngilizce metni için sütun (uygulama okuyor, tabloda yoktu)
alter table public.heritage_places add column if not exists audio_text_en text;

-- 4) Karışık görünümü düzelt: tablo sırası işlevsel değildir; okumak için eser eser sıralı görünüm
create or replace view public.hotspots_sirali as
  select h.place_id, p.name as eser, h.id, h.title, h.target_side, h.x_percent, h.y_percent,
         h.model_pos, (h.title_en is not null and h.title_en <> '' and h.description_en is not null and h.description_en <> '') as ingilizce_tam
  from public."Hotspots" h
  join public.heritage_places p on p.id = h.place_id
  order by h.place_id, h.id;
revoke all on public.hotspots_sirali from anon, authenticated;

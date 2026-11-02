-- Hotspot'ların doğru döneme ve tek kopyaya getirilmesi. Güvenle yeniden çalıştırılabilir; satırlar id ile değil
-- eser + başlıkla bulunur.
--
-- Kural:  target_side = 'after'  -> TARİHÎ (sol/eski fotoğraf ve ESKİ model): geçmiş dönemle ilgili bilgiler
--                                   (tarih, olaylar, eski kullanım, yapım kayıtları, ustalar).
--         target_side = 'before' -> GÜNÜMÜZ (sağ/yeni fotoğraf ve YENİ model): yapının bugünkü görünümü,
--                                   genel tanım, süsleme, onarım ve bugünkü kullanım.
-- 3B'de de aynı kural: tarihî hotspot'lar yalnızca eski modelde, günümüz hotspot'ları yalnızca yeni modelde görünür.

-- 1) Aynı eser + aynı başlıkla birden fazla eklenmiş kopyaları sil (en eski kayıt kalır)
delete from public."Hotspots" a using public."Hotspots" b
  where a.place_id = b.place_id and btrim(a.title) = btrim(b.title) and a.id > b.id;

-- 2) Koza Han: fazlalık. Geriye 4 hotspot kalır (mescit, taç kapı, şadırvan, ipek loncası revakları).
delete from public."Hotspots" where place_id = 5 and title like 'Ahşap Üst Kat Revakı%';

-- 3) Günümüz (yeni fotoğraf + yeni model) tarafına geçenler: genel tanım, süsleme, onarım, bugünkü durum

update public."Hotspots" set target_side = 'before' where place_id = 4 and title like any (array['Ahşap İşlemeli Şaheser Kubbe%']);  -- Karabaş-ı Velî
update public."Hotspots" set target_side = 'before' where place_id = 5 and title like any (array['Sekizgen Köşk Mescit%', 'Taç Kapı Taş Oymacılığı%', 'Köşk Mescidin Şadırvanı%']);  -- Koza Han
update public."Hotspots" set target_side = 'before' where place_id = 9 and title like any (array['İç Şadırvan%', 'Kündekari Minberi%', 'Müezzin Mahfili%', 'Sürgündeki Paşanın Mihrabı%', 'İç Taraftan Kubbeler ve Hat Yazıları%']);  -- Ulu Camii
update public."Hotspots" set target_side = 'before' where place_id = 10 and title like any (array['Taç Kapı%', 'Taç Kapı Detay%', 'Alçı Nişli Duvar%', 'Hünkar Mahfili%', 'Yeşil Karo Çini ve Madalyon%', 'Fıskiyeli Orta Harim%', 'Mermer Söveli pencere%', 'Kalem İşli Kasnak%', 'Çini Panolu Tabhane%', 'Mihrabın Üstündeki Çini Yazı Panosu%']);  -- Yeşil Camii
update public."Hotspots" set target_side = 'before' where place_id = 11 and title like any (array['Firuze Çini Yüzeyde%', 'İç Mekan ve Sandukalar%', 'Mukarnaslı Taç Kapı%', 'Devlet Hatun Türbesi%', 'Kasnak%', 'Kubbe%']);  -- Yeşil Türbe
update public."Hotspots" set target_side = 'before' where place_id = 13 and title like any (array['Çarşı ve Zanaat Dükkânları%', 'Kemer ve Ayaklardaki Depolar%']);  -- Irgandı Köprüsü
update public."Hotspots" set target_side = 'before' where place_id = 15 and title like any (array['Mermer Sütunlu Ahşap Revaklar%', 'Sekizgen Mermer Şadırvan%']);  -- Emir Sultan
update public."Hotspots" set target_side = 'before' where place_id = 17 and title like any (array['Beş Bölümlü Son Cemaat Yeri%', 'Kubbeler ve Tabhaneler%', 'Tuğla Minareler%']);  -- Muradiye Camii
update public."Hotspots" set target_side = 'before' where place_id = 18 and title like any (array['Taç Kapı%', 'Dershane Kubbesi%', 'Hücre Revakları%', 'Avlunun Cam Örtüsü%']);  -- Muradiye Medresesi
update public."Hotspots" set target_side = 'before' where place_id = 19 and title like any (array['Sofalı Giriş%']);  -- II. Murad Türbesi
update public."Hotspots" set target_side = 'before' where place_id = 20 and title like any (array['Mermer Revak%', 'Çinili İç Mekân%', 'Altıgen Gövde ve Kubbe%']);  -- Cem Sultan Türbesi
update public."Hotspots" set target_side = 'before' where place_id = 21 and title like any (array['Taç Kapı%', 'Sekizgen Kasnak%', 'Kesme Taş ve Tuğla Duvar%']);  -- Şirin Hatun Türbesi

-- 4) Tarihî tarafa geçen: Karabaş-ı Velî semahanesinin 1925'te İdman Yurdu'na dönüşme hikâyesi
update public."Hotspots" set target_side = 'after' where place_id = 4 and title like 'Dairesel Ahşap Semahane%';

-- 5) Yeni fotoğrafta üst üste binen / ağaca denk gelen noktaları kaydır (x/y fotoğrafın sol üstünden 0-1)
update public."Hotspots" set x_percent = 0.36 where place_id = 10 and title like 'Mihrabın Üstündeki Çini Yazı Panosu%';
update public."Hotspots" set x_percent = 0.60, y_percent = 0.52 where place_id = 11 and title like 'Devlet Hatun Türbesi%';

-- 6) Bittikten sonra id'lerdeki boşlukları kapatmak için hotspots_renumber.sql'i tekrar çalıştırın.
-- Kontrol: hangi eserde kaç hotspot hangi tarafta
-- select place_id, target_side, count(*) from public."Hotspots" group by 1, 2 order by 1, 2;

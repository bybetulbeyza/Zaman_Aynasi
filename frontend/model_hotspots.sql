-- 3B model hotspot'ları: Hotspots tablosuna iki sütun eklenir; model_pos dolu olan satırlar
-- yalnızca 3B görünümde, boş olanlar fotoğraf slider'ında görünür.
-- model_pos = "x y z" (metre, model orijini zemin ortası), model_normal = yüzeyin baktığı yön.
alter table public."Hotspots"
  add column if not exists model_pos text,
  add column if not exists model_normal text;

-- Yeşil Türbe (place_id = 11). Cephe -Z yönünde.
-- Konum oynatmak için: update public."Hotspots" set model_pos = 'x y z' where title = '...';
insert into public."Hotspots"
  (place_id, title, description, title_en, description_en, target_side, x_percent, y_percent, model_pos, model_normal)
values
(11, 'Mukarnaslı Taç Kapı',
 'Taç kapının her iki yanında, derinlikli mukarnas kavsaralarla taçlandırılmış birer niş bulunur. İçeri girildiğinde ziyaretçiyi çini kaplı duvarlar, mihrap ve sandukalardan oluşan görkemli bir düzenleme karşılar.',
 'Muqarnas Crown Portal',
 'On both sides of the crown portal is a niche crowned with a deep muqarnas hood. Upon entering, the visitor is met by a magnificent arrangement of tile-covered walls, a mihrab and cenotaphs.',
 'model', 0, 0, '0 8.4 -12.7', '0 0 -1'),
(11, 'Giriş Kapısı Üzerindeki Kitabe',
 'Giriş kapısının üzerindeki dikdörtgen kitabede, lacivert zemin üzerine firuze kıvrık dallar, yapraklar ve çiçek motifleri işlenmiştir. Ortadaki sarı celi sülüs yazı, türbenin Bayezid Han oğlu Sultan Mehmed’e ait olduğunu ve onun Cemaziyelevvel 824’te (Mayıs-Haziran 1421) vefat ettiğini kaydeder.',
 'Inscription above the Entrance Door',
 'On the rectangular inscription above the entrance door, turquoise curling branches, leaves and floral motifs are worked on a navy blue ground. The yellow celi sülüs writing in the center records that the tomb belongs to Sultan Mehmed, son of Bayezid Han, and that he died in Jumada al-awwal 824 (May–June 1421).',
 'model', 0, 0, '0 5.9 -12.7', '0 0 -1'),
(11, 'Çini Bezemeli Pencereler',
 'Türbe toplam yirmi iki pencereyle aydınlatılır: altta altı, üstte sekiz, kasnakta sekiz pencere. Dikdörtgen taş söveli, sivri kemerli pencerelerin üst kısmında çini bezemeli alınlıklar yer alır.',
 'Tile-Decorated Windows',
 'The tomb is lit by a total of twenty-two windows: six at the bottom, eight at the top and eight in the drum. Above the rectangular stone-framed, pointed-arch windows are pediments decorated with tiles.',
 'model', 0, 0, '6.9 7.8 -7.6', '0.7 0 -0.7'),
(11, 'Kasnak',
 'Kubbeyi taşıyan sekizgen kasnakta sekiz pencere bulunur; türbenin toplam yirmi iki penceresinin sekizi buradadır.',
 'The Drum',
 'The octagonal drum carrying the dome has eight windows, eight of the tomb’s twenty-two in total.',
 'model', 0, 0, '0 15.9 -9.4', '0 0 -1'),
(11, 'Kubbe',
 'Çelebi Mehmed’in turkuaz çinilerle kaplı sekizgen anıt türbesi kubbeyle örtülüdür. Parlak firuze çini yüzey, yapının en dikkat çeken özelliğidir.',
 'The Dome',
 'Çelebi Mehmed’s octagonal monumental tomb, clad in turquoise tiles, is covered with a dome. The bright turquoise tile surface is the building’s most striking feature.',
 'model', 0, 0, '0 21.7 -8.2', '0 0.72 -0.69');

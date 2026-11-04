-- Hotspot video metinleri (video_script_tr / video_script_en): hikâyeleştirilmiş, kısa, konuşur gibi.
-- Kapsam: Koza Han, Ulu Camii ve Yeşil Külliye'nin alt eserleri (Yeşil Camii, Yeşil Türbe, Medrese, İmaret).
-- Külliyeden yapılara yönlendiren hotspot'lara (id 59-62) video metni eklenmez; doğrudan yapıya gider.
-- Bilgilerin tamamı hotspot açıklamalarındaki envanter metinlerinden alınmıştır; yeni bilgi eklenmemiştir.
-- Dokunulmayanlar: Müezzin Mahfili (id 21): videosu hazır, altyazı mevcut seslendirmeyle uyuşsun diye metni aynı bırakıldı.
-- Hotspot açıklamaları (description) değişmez; uygulamada kartta aynen görünür.
-- Çalıştırmadan önce metinleri okuyup istediğini düzenle. Güvenle tekrar çalıştırılabilir.
begin;

-- #10 Sekizgen Köşk Mescit
update public."Hotspots" set
  video_script_tr = $q$Bu mescit, komşu hanın tuğlalarıyla yeniden yapıldı. 1948'deki restorasyonda ahşap çatının altından özgün kubbenin izleri çıktı. Tahtakale Hanı'nın enkazından alınan tarihi tuğlalarla aslına uygun biçimde yeniden inşa edildi. Altında altı şadırvan, üstünde sekizgen bir ibadethane.$q$,
  video_script_en = $q$This mosque was rebuilt with the bricks of a neighboring inn. In the 1948 restoration, traces of the original dome appeared beneath the wooden roof. It was rebuilt faithfully using historic bricks salvaged from the ruins of the nearby Tahtakale Inn. Six fountains below, an octagonal prayer space above.$q$
where id = 10;

-- #11 Taç Kapı Taş Oymacılığı
update public."Hotspots" set
  video_script_tr = $q$İpek yüklü kervanlar hana ilk adımda bu kapıyla karşılaşırdı. Geometrik motifler ve mukarnas işçiliği, Erken Osmanlı taş oymacılığının en zarif örneklerinden biri. Kapı, ticaretin ihtişamını daha içeri girmeden anlatırdı.$q$,
  video_script_en = $q$Silk-laden caravans met this gate with their very first step. Its geometric motifs and muqarnas work are among the most elegant examples of Early Ottoman stone carving. The gate announced the splendor of trade before anyone stepped inside.$q$
where id = 11;

-- #12 Tarihi İpek Loncası Revakları
update public."Hotspots" set
  video_script_tr = $q$Koza fiyatını burada kim belirlerdi? Şehrin en kıdemli lonca ustaları. Taş tonozlu bu koridorlarda yüzyıllar boyunca koza pazarlıkları yürütüldü. Bursa ipeği dünyaya buradan yayıldı.$q$,
  video_script_en = $q$Who set the price of cocoons here? The city's most senior guild masters. For centuries, cocoon bargains were struck in these stone-vaulted arcades. Bursa silk spread to the world from here.$q$
where id = 12;

-- #13 Köşk Mescidin Şadırvanı
update public."Hotspots" set
  video_script_tr = $q$Avlunun ortasında tüccarın durağı vardı: mescidin altındaki çokgen şadırvan. Akan sular, tüccarların abdest alıp serinlemesi için tasarlanmıştı.$q$,
  video_script_en = $q$In the middle of the courtyard stood the merchants' resting place: the polygonal fountain beneath the mosque. The flowing water was designed for merchants to wash and cool down.$q$
where id = 13;

-- #19 İç Şadırvan
update public."Hotspots" set
  video_script_tr = $q$Efsane mi, gerçek mi? Şadırvanın yerini satmak istemeyen gayrimüslim bir kadına ait olduğu anlatılır. Ama vakıf arazisi üzerinde şahıs mülkiyeti olmaz: arsa Orhan Gazi Vakfı'na aittir. Yıldırım Bayezid vakfa başka bir arazi verip camiyi yaptırdı. On altı kenarlı mermer havuzun üstü ise su sesinin huzuru için açık bırakıldı.$q$,
  video_script_en = $q$Legend or fact? The story goes that this fountain stands on land owned by a non-Muslim woman who refused to sell. But no private ownership can exist on endowment land: the plot belongs to the Orhan Gazi Foundation. Yıldırım Bayezid gave the foundation another plot and built the mosque. The top of the sixteen-sided marble pool was left open for the calm of the sound of water.$q$
where id = 19;

-- #20 Kündekari Minberi
update public."Hotspots" set
  video_script_tr = $q$Bu minberde tek bir çivi yok. Tutkal da yok. 6.666 ahşap parça, sadece birbirine geçerek duruyor. Gizemini ilk kez 1980'de, emekli bir fen öğretmeni fark etti. Doğu yüzünde Güneş ve gezegenler gerçek oranlarıyla, batı yüzünde bir galaksi. Bir minber, içinde bir evren.$q$,
  video_script_en = $q$There isn't a single nail in this pulpit. No glue either. 6,666 wooden pieces, held together only by how they fit. In 1980, a retired science teacher noticed its secret. On the east face, the Sun and planets in true proportion; on the west face, a galaxy. One pulpit, a whole universe inside.$q$
where id = 20;

-- #22 Kuşbakışı Minareler
update public."Hotspots" set
  video_script_tr = $q$Bursa'nın siluetini iki padişah çizdi. Ulu Camii'nin iki anıtsal minaresi, Yıldırım Bayezid ve Çelebi Mehmed dönemlerinde yapıldı. Kuşbakışı bakınca ikisi birlikte kentin simgesel görüntüsünü tamamlıyor.$q$,
  video_script_en = $q$Two sultans drew the skyline of Bursa. The Grand Mosque's two monumental minarets were built in the reigns of Yıldırım Bayezid and Çelebi Mehmed. Seen from above, together they complete the city's iconic silhouette.$q$
where id = 22;

-- #23 Sürgündeki Paşanın Mihrabı
update public."Hotspots" set
  video_script_tr = $q$Mihrabın sağındaki devasa Vav harfinin önünde Hızır Aleyhisselam'ın namaz kıldığı anlatılır. Bu yüzden burada ibadet etmenin faziletli olduğuna inanılır. Mermer mihrabı ise Sadrazam Koca Ragıp Paşa yaptırdı. Bursa'nın en güzel halk söylencelerinden biri.$q$,
  video_script_en = $q$It is said that Khidr, peace be upon him, prayed in front of the giant letter Waw to the right of the mihrab. That is why worshipping here is believed to be especially blessed. The marble mihrab itself was commissioned by Grand Vizier Koca Ragıp Pasha. One of the loveliest folk legends of Bursa.$q$
where id = 23;

-- #24 İç Taraftan Kubbeler ve Hat Yazıları
update public."Hotspots" set
  video_script_tr = $q$Yirmi kubbenin altındaki duvarlara bakın: 170'ten fazla devasa hat levhası. Ulu Camii bu yüzden adeta bir hüsn-i hat müzesi.$q$,
  video_script_en = $q$Look at the walls beneath the twenty domes: more than 170 giant calligraphy panels. That is why the Grand Mosque is almost a museum of calligraphy.$q$
where id = 24;

-- #25 Taç Kapı
update public."Hotspots" set
  video_script_tr = $q$Üç yıl, tek usta. Bu mermer taç kapı iğne oyası gibi işlendi. Dışa taşkın olmayan mimarisiyle Selçuklu tarzından ayrılıyor. Celi sülüs kitabede Çelebi Mehmed'in zafer mührü okunuyor.$q$,
  video_script_en = $q$Three years, one master. This marble portal was worked like needlelace. Its non-protruding design sets it apart from the Seljuk style. In the thuluth inscription, Çelebi Mehmed's seal of victory can be read.$q$
where id = 25;

-- #26 Taç Kapı Detay
update public."Hotspots" set
  video_script_tr = $q$Yaklaşın: kapı hat ve kabartmayla örülmüş gibi. Celi sülüs yazılar ve taş kabartmalar, Çelebi Sultan Mehmed'in zafer mührünü taşıyor.$q$,
  video_script_en = $q$Come closer: the gate looks woven from calligraphy and relief. Its thuluth lettering and stone carvings bear Sultan Çelebi Mehmed's seal of victory.$q$
where id = 26;

-- #28 Hünkar Mahfili
update public."Hotspots" set
  video_script_tr = $q$Osmanlı mimarisinde bir ilk: Hünkâr Mahfili. Sultana özel ocaklı odası ve dışa açılan balkonlarıyla küçük bir saray kasrı gibi. Kemerindeki renkli sır çinileri, altın yaldızın çiniyle buluştuğu ilk hükümdarlık locası.$q$,
  video_script_en = $q$A first in Ottoman architecture: the Imperial Lodge. With a private room with a fireplace for the sultan and balconies opening outward, it is like a small palace pavilion. Its glazed tiles mark the first royal loge where gold gilding meets tilework.$q$
where id = 28;

-- #30 Minber ve Kitabeli Duvar
update public."Hotspots" set
  video_script_tr = $q$Bu duvarlar imza taşıyor: mimar Hacı İvaz Paşa ve Lâmiî Çelebi'nin dedesi Nakkaş Ali'nin isimleri. Mimarinin hatla, hattın çiniyle yarıştığı bu duvarlar, Erken Osmanlı dehasının belgesi.$q$,
  video_script_en = $q$These walls carry signatures: the names of architect Hacı İvaz Pasha and Nakkaş Ali, the grandfather of Lâmiî Çelebi. Where architecture rivals calligraphy and calligraphy rivals tile, these walls are a record of Early Ottoman genius.$q$
where id = 30;

-- #32 Fıskiyeli Orta Harim
update public."Hotspots" set
  video_script_tr = $q$Bu fıskiye sadece güzel görünmek için değildi. 25 metre yüksekliğindeki dev kubbenin altında, içeride yapılan gizli devlet görüşmelerinin dışarıdan duyulmasını engelleyen doğal bir ses perdesiydi.$q$,
  video_script_en = $q$This fountain wasn't only for beauty. Under the 25-meter-high dome, it served as a natural sound screen, preventing secret state talks held inside from being overheard outside.$q$
where id = 32;

-- #38 Firuze Çini Yüzeyde Mermer Kemerli Pencere
update public."Hotspots" set
  video_script_tr = $q$Osmanlı'nın inşa ettiği en yüksek türbe burada: 25,5 metre. Turkuaz çinilerle kaplı dış duvarlara mermer pencereler oyulmuş. İçeri süzülen ışık, mistik bir hava veriyor.$q$,
  video_script_en = $q$The tallest tomb the Ottomans ever built is here: 25.5 meters. Marble windows are carved into the turquoise-tiled outer walls. The light filtering in creates a mystical atmosphere.$q$
where id = 38;

-- #39 İç Mekan ve Sandukalar
update public."Hotspots" set
  video_script_tr = $q$Çelebi Mehmed'in sandukası tam 2,77 metre. Kabartma sarı harfler, zümrüt yeşili çiniler… Yanındaki sade sandukalar şehzadelere ait. Bu ihtişamla bilerek tezat oluşturulmuş.$q$,
  video_script_en = $q$Çelebi Mehmed's sarcophagus is a full 2.77 meters long. Raised yellow lettering, emerald-green tiles... The plain sarcophagi beside it belong to the princes, a deliberate contrast to this splendor.$q$
where id = 39;

-- #40 Mukarnaslı Taç Kapı Kavsarası
update public."Hotspots" set
  video_script_tr = $q$Bu kapının kanatlarında iki imza var. Mimar Hacı İvaz Paşa ve ahşap ustası Tebrizli Hacı Ali. Derin mukarnaslı nişler ziyaretçiyi, hanedanın ihtişamıyla karşılıyor.$q$,
  video_script_en = $q$The wings of this door carry two signatures: architect Hacı İvaz Pasha and woodworker Hacı Ali of Tabriz. Deep muqarnas niches greet visitors with the grandeur of the dynasty.$q$
where id = 40;

-- #41 Giriş Kapısı Üzerindeki Kitabe
update public."Hotspots" set
  video_script_tr = $q$Lacivert zeminde firuze kıvrık dallar ve bir unvan: Şehit Sultan. Çelebi Mehmed'in bu unvanı, yazının ve çini renklerinin birleştiği en yüksek hat estetiğiyle işlenmiş.$q$,
  video_script_en = $q$Turquoise curling branches on a navy ground, and a title: Martyr Sultan. Çelebi Mehmed's title is rendered in the highest calligraphic beauty, where script and tile colors meet.$q$
where id = 41;

-- #42 Devlet Hatun Türbesi
update public."Hotspots" set
  video_script_tr = $q$Bir sultanın annesi için yapılmış türbe: Devlet Hatun. Mermerden, üstü kapalı yanları açık. Selçuklu baldaken geleneğinin Osmanlı'daki en zarif örneği.$q$,
  video_script_en = $q$A tomb built for a sultan's mother: Devlet Hatun. Made of marble, covered on top and open at the sides. The most elegant Ottoman example of the Seljuk canopy tomb tradition.$q$
where id = 42;

-- #43 Kasnak
update public."Hotspots" set
  video_script_tr = $q$Kubbenin altındaki sekizgen kasnak, 25,5 metrelik yüksek kütleye zarafet katıyor. Pencerelerinden süzülen ışık, kubbeye geçiyor.$q$,
  video_script_en = $q$The octagonal drum beneath the dome adds grace to the 25.5-meter-tall mass. Light filtered through its windows passes into the dome.$q$
where id = 43;

-- #44 Kubbe
update public."Hotspots" set
  video_script_tr = $q$Bursa'nın simgesi bu kubbe. Dışta turkuaz çinilerden bir zırh, içte kalem işleriyle süslü. Sekizgen kütleyi görkemle örtüyor.$q$,
  video_script_en = $q$This dome is the symbol of Bursa. Outside, an armor of turquoise tiles; inside, hand-painted decoration. It crowns the octagonal body with grandeur.$q$
where id = 44;

-- #80 Mutfak ve Yemek Salonu
update public."Hotspots" set
  video_script_tr = $q$26 metrelik dev bir mutfak ve 16 metrelik yemek salonu. Asırlarca günde iki öğün sıcak yemek verilen bir aşevi kompleksi.$q$,
  video_script_en = $q$A giant 26-meter kitchen and a 16-meter dining hall. A soup-kitchen complex that served two hot meals a day for centuries.$q$
where id = 80;

-- #81 Moloz Taş ve Tuğla Duvar
update public."Hotspots" set
  video_script_tr = $q$Moloz taş ve tuğla sırayla örülmüş. Bu almaşık duvarlar, imaretin asırlardır ayakta kalan sağlam gövdesi.$q$,
  video_script_en = $q$Rubble stone and brick laid in alternating courses. These walls form the sturdy body of the soup kitchen, standing for centuries.$q$
where id = 81;

-- #82 Giriş
update public."Hotspots" set
  video_script_tr = $q$Anıtsal giriş kapısının ardında yedi tarihi fırın var. İmaret, yüzlerce kişiyi aynı anda besleyebilen devasa bir mutfaktı.$q$,
  video_script_en = $q$Behind the monumental entrance are seven historic ovens. The soup kitchen was a vast kitchen able to feed hundreds of people at once.$q$
where id = 82;

-- #83 Çini Kaplı Tavan
update public."Hotspots" set
  video_script_tr = $q$Medreseye giren öğrenciyi, daha ilk adımda turkuaz çiniler karşılardı. Tavandaki geometri, matematiğin ve estetiğin güzelliğini hissettirmek için tasarlanmıştı.$q$,
  video_script_en = $q$A student entering the madrasa met turquoise tiles from the very first step. The geometry on the ceiling was designed to let them feel the beauty of mathematics and aesthetics.$q$
where id = 83;

-- #86 Mezar Taşlı Bahçe ve Cephe
update public."Hotspots" set
  video_script_tr = $q$Bu bahçe, bir taş kütüphane. Medrese 1975'ten beri müze. Bursa'nın yıkılan tarihi yapılarından kurtarılan mezar taşları burada sergileniyor.$q$,
  video_script_en = $q$This garden is a library of stone. The madrasa has been a museum since 1975. Gravestones rescued from Bursa's demolished historic buildings are displayed here.$q$
where id = 86;

-- #88 Sanduka Tipi Mezar
update public."Hotspots" set
  video_script_tr = $q$Tek parça mermerden oyulmuş bir mezar. Üzerindeki kabartma celi sülüs hatlar ve rumî motifler, Osmanlı defin sanatının seçkin bir örneği.$q$,
  video_script_en = $q$A tomb carved from a single block of marble. Its raised thuluth calligraphy and rumi motifs make it a distinguished example of Ottoman funerary art.$q$
where id = 88;

-- #90 Kabartma Kitabe Levhası
update public."Hotspots" set
  video_script_tr = $q$Dört satır, mermere kabartma. Bursa'nın yıkılan tarihi yapılarından kurtarılan bu levha, hat sanatının mermer üzerindeki zirvesini gösteriyor.$q$,
  video_script_en = $q$Four lines, carved in relief on marble. Rescued from demolished historic buildings of Bursa, this panel shows the peak of calligraphy on marble.$q$
where id = 90;

commit;

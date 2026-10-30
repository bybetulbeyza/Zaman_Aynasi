/// Arayüz metinleri. Eser/hotspot içerikleri (ad, açıklama) veri tabanındaki `_en` kolonlarından gelir.
const Map<String, String> appStringsTr = {
  // Açılış
  'splash_tagline': 'Vakıf mirasını hikâyeleriyle keşfet',
  'splash_credit': 'Vakıf Katılım katkılarıyla',

  // Genel
  'all': 'Tümü',
  'all_filter': 'Tümü',
  'soon': 'Yakında',
  'retry': 'Tekrar dene',
  'detail': 'Detay',
  'directions': 'Yol tarifi',
  'explore': 'Keşfet',
  'sort': 'Sırala',
  'no_places': 'Eser bulunamadı.',
  'no_match': 'Eşleşen eser bulunamadı.',
  'coming_soon': 'Çok yakında eklenecek.',
  'coming_soon_short': 'Yakında',
  'stops_word': 'durak',
  'search_hint': 'Eser adı ara',

  // Alt gezinme
  'nav_home': 'Ana Sayfa',
  'nav_map': 'Harita',
  'nav_qr': 'QR Okut',
  'nav_routes': 'Rotalarım',
  'nav_profile': 'Profil',

  // Ana sayfa
  'hero_title': 'Vakıf mirasını\nhikâyeleriyle keşfet',
  'qa_nearby': 'Yakınımda',
  'qa_create_route': 'Rota oluştur',
  'qa_scan_qr': 'QR okut',
  'qa_cities': 'Şehirler',
  'home_featured': 'Öne çıkan vakıf eserleri',
  'home_nearby': 'Yakınımdaki eserler',

  // Envanter
  'inv_title': 'Tarih Envanteri',
  'inv_count': "Bursa'da {n} eser",

  // Rota oluştur
  'rc_title': 'Rota oluştur',
  'rc_city': 'Şehir',
  'rc_start': 'Başlangıç noktası',
  'rc_my_location': 'Konumum',
  'rc_now': 'Şimdi',
  'rc_duration': 'Süre',
  'rc_hour': 'saat',
  'rc_types': 'Ne tür yerleri gezmek istersin?',
  'rc_summary': 'Yaklaşık {n} durak · {h} saat',
  'rc_create': 'Rota oluştur',
  'rc_ready_q': 'Hazır rota mı arıyorsun?',
  'rc_browse': "Tarihi Rotalar'a göz at",
  'route_created': '{n} duraklı özel rota oluşturuldu.',

  // Aktif rota
  'ar_title': 'Aktif rotam',
  'ar_stops': '{n} durak',
  'ar_show_map': 'Haritada göster',
  'route_added': 'Rotana eklendi · {n} durak',
  'route_removed': 'Rotandan çıkarıldı.',
  'add_to_route': 'Rotama ekle',
  'in_route': 'Rotada',

  // Tarihi rotalar
  'hr_title': 'Tarihi Rotalar',
  'hr_subtitle': 'Bölgeye ve temaya göre hazır rota paketleri',
  'hr_see_stops': 'Durakları gör',
  'hr_start': 'Rotayı başlat',
  'hr_soon': '{city} için hazır rotalar yakında eklenecek.',

  // Harita
  'map_search_hint': 'Eser adı ara',
  'map_load_error': 'Eserler yüklenemedi.',
  'nearby_route_ready': 'Konumunuza yakın 4 duraklı rota hazırlandı.',
  'nearby_route_title': 'Yakın Çevre Rotası',
  'stop_of': 'Durak {i} / {n}',
  'next_stop': 'Sonraki durak',

  // QR
  'qr_align': 'Karekodu Hizalayın',
  'qr_heading': 'Tabeladaki karekodu okut',
  'qr_body': "Tarihi yapının tabelasındaki karekodu okut. Eserin sayfası önce/bugün fotoğrafıyla açılır. Karekod yoksa Tarih Envanteri'nden ara.",
  'qr_open_camera': 'Kamerayı aç',
  'qr_unknown': "Bu karekod tanınmadı. Tarih Envanteri'nden aramayı deneyin.",

  // Detay
  'period_label': 'Dönem',
  'today_label': 'Bugün',
  'period': 'Dönem',
  'architect': 'Mimar',
  'patron': 'Bani',
  'swipe_up': 'Detaylar için yukarı kaydır',
  'ai_generated': 'AI üretimi',
  'transform_video': 'Tarihî dönüşüm videosu',
  'video_soon': 'Video yakında',
  'video_error': 'Video yüklenemedi.',
  'audio_guide': 'Sesli rehber',
  'history': 'Tarihçe',
  'sources': 'Kaynakça',
  'source_book': 'Vakıf Katılım Envanter Kitabı',
  'source_label': 'Kaynak',
  'source_open': 'Envanter yayınlarına git',
  'verified': 'Doğrulandı',
  'see_details': 'Detayları gör',
  'ai_story': 'AI hikâyesi',

  // Profil
  'profile_title': 'Profil',
  'no_account': 'Hesap gerekmez',
  'no_account_body': 'Tüm içeriklere giriş yapmadan ulaşabilirsiniz.',
  'about_row': 'Hakkında ve kaynaklar',
  'language_row': 'Dil',
  'font_row': 'Yazı boyutu ve kontrast',
  'feedback_row': 'Geri bildirim gönder',
  'profile_footer': 'İçerikler Vakıf Katılım envanter\nkaynaklarından alınmıştır.',

  // Hakkında
  'about_title': 'Hakkında ve kaynaklar',
  'about_project': 'Proje',
  'about_project_body': 'Vakıf Yolu; tarihi vakıf eserlerinin geçmişi ile bugünkü halini etkileşimli karşılaştırma, konum bazlı rotalar ve sesli hikâyelerle sunar.',
  'about_goal': 'Projenin amacı',
  'about_goal_body': 'Uzun ve sıkıcı bulunabilen envanter metinlerini; görsel karşılaştırma, yapay zekâ destekli videolar ve sesli anlatımlarla ilgi çekici hâle getirerek kültürel mirasın daha çok kişiye ulaşmasını sağlamak.',
  'about_sources': 'Arşiv kaynakları',
  'about_sources_body': 'İçerikler Vakıf Katılım envanter kitaplarından alınmıştır. Her eserin sayfasında, kitaptaki cilt ve sayfa numarası belirtilir.',
  'about_open_inventory': 'Envanter yayınlarını aç',
};

const Map<String, String> appStringsEn = {
  // Splash
  'splash_tagline': 'Discover foundation heritage through its stories',
  'splash_credit': 'With the contributions of Vakıf Katılım',

  // General
  'all': 'All',
  'all_filter': 'All',
  'soon': 'Coming soon',
  'retry': 'Try again',
  'detail': 'Details',
  'directions': 'Directions',
  'explore': 'Explore',
  'sort': 'Sort',
  'no_places': 'No landmarks found.',
  'no_match': 'No matching landmarks.',
  'coming_soon': 'Coming very soon.',
  'coming_soon_short': 'Coming soon',
  'stops_word': 'stops',
  'search_hint': 'Search landmarks',

  // Bottom navigation
  'nav_home': 'Home',
  'nav_map': 'Map',
  'nav_qr': 'Scan QR',
  'nav_routes': 'My Routes',
  'nav_profile': 'Profile',

  // Home
  'hero_title': 'Discover foundation\nheritage through its stories',
  'qa_nearby': 'Nearby',
  'qa_create_route': 'Create route',
  'qa_scan_qr': 'Scan QR',
  'qa_cities': 'Cities',
  'home_featured': 'Featured landmarks',
  'home_nearby': 'Landmarks near me',

  // Inventory
  'inv_title': 'Heritage Inventory',
  'inv_count': '{n} landmarks in Bursa',

  // Create route
  'rc_title': 'Create route',
  'rc_city': 'City',
  'rc_start': 'Starting point',
  'rc_my_location': 'My location',
  'rc_now': 'Now',
  'rc_duration': 'Duration',
  'rc_hour': 'hr',
  'rc_types': 'What kind of places do you want to visit?',
  'rc_summary': 'About {n} stops · {h} hr',
  'rc_create': 'Create route',
  'rc_ready_q': 'Looking for a ready-made route?',
  'rc_browse': 'Browse Historic Routes',
  'route_created': 'Custom route with {n} stops created.',

  // Active route
  'ar_title': 'My active route',
  'ar_stops': '{n} stops',
  'ar_show_map': 'Show on map',
  'route_added': 'Added to your route · {n} stops',
  'route_removed': 'Removed from your route.',
  'add_to_route': 'Add to route',
  'in_route': 'In route',

  // Historic routes
  'hr_title': 'Historic Routes',
  'hr_subtitle': 'Ready-made route packages by region and theme',
  'hr_see_stops': 'See stops',
  'hr_start': 'Start route',
  'hr_soon': 'Ready-made routes for {city} are coming soon.',

  // Map
  'map_search_hint': 'Search landmarks',
  'map_load_error': 'Landmarks could not be loaded.',
  'nearby_route_ready': 'A 4-stop route near you is ready.',
  'nearby_route_title': 'Nearby Route',
  'stop_of': 'Stop {i} / {n}',
  'next_stop': 'Next stop',

  // QR
  'qr_align': 'Align the QR code',
  'qr_heading': 'Scan the QR code on the sign',
  'qr_body': "Scan the QR code on the historic building's sign. The page opens with the then/now photos. If there is no code, search in the Heritage Inventory.",
  'qr_open_camera': 'Open camera',
  'qr_unknown': 'This QR code was not recognized. Try searching the Heritage Inventory.',

  // Detail
  'period_label': 'Then',
  'today_label': 'Today',
  'period': 'Period',
  'architect': 'Architect',
  'patron': 'Patron',
  'swipe_up': 'Swipe up for details',
  'ai_generated': 'AI generated',
  'transform_video': 'Historic transformation video',
  'video_soon': 'Video coming soon',
  'video_error': 'The video could not be loaded.',
  'audio_guide': 'Audio guide',
  'history': 'History',
  'sources': 'Sources',
  'source_book': 'Vakıf Katılım Inventory Book',
  'source_label': 'Source',
  'source_open': 'Go to inventory publications',
  'verified': 'Verified',
  'see_details': 'See details',
  'ai_story': 'AI story',

  // Profile
  'profile_title': 'Profile',
  'no_account': 'No account needed',
  'no_account_body': 'You can access all content without signing in.',
  'about_row': 'About and sources',
  'language_row': 'Language',
  'font_row': 'Text size and contrast',
  'feedback_row': 'Send feedback',
  'profile_footer': 'Content is taken from the Vakıf Katılım\ninventory sources.',

  // About
  'about_title': 'About and sources',
  'about_project': 'The project',
  'about_project_body': 'Vakıf Yolu presents historic foundation (waqf) buildings through interactive then-and-now comparisons, location-based routes and audio stories.',
  'about_goal': 'Our goal',
  'about_goal_body': 'To turn long, dry inventory texts into engaging experiences with visual comparison, AI-assisted videos and audio narration, so that cultural heritage reaches more people.',
  'about_sources': 'Archive sources',
  'about_sources_body': 'Content is taken from the Vakıf Katılım inventory books. Each landmark page lists the volume and page number in the book.',
  'about_open_inventory': 'Open inventory publications',
};

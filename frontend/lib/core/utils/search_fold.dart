/// Arama için metni sadeleştirir: küçük harfe çevirir ve Türkçe/şapkalı harfleri düz karşılıklarına indirir.
/// Böylece "kulliye" → "Külliye", "sultaniye" → "Sultaniye", "ISIK" → "ışık" eşleşir.
String searchFold(String s) {
  const map = {
    'ç': 'c',
    'Ç': 'c',
    'ğ': 'g',
    'Ğ': 'g',
    'ı': 'i',
    'I': 'i',
    'İ': 'i',
    'ö': 'o',
    'Ö': 'o',
    'ş': 's',
    'Ş': 's',
    'ü': 'u',
    'Ü': 'u',
    'â': 'a',
    'Â': 'a',
    'î': 'i',
    'Î': 'i',
    'û': 'u',
    'Û': 'u',
  };
  final b = StringBuffer();
  for (final ch in s.split('')) {
    b.write(map[ch] ?? ch.toLowerCase());
  }
  // toLowerCase bazı harflerde birleşik nokta bırakabilir (i̇); temizle
  return b.toString().replaceAll('̇', '');
}

/// [query] boşsa true; değilse alanlardan herhangi biri sadeleştirilmiş sorguyu içeriyorsa true.
bool searchMatches(String query, Iterable<String> fields) {
  final q = searchFold(query.trim());
  if (q.isEmpty) return true;
  return fields.any((f) => searchFold(f).contains(q));
}

/// Arama sonucu sırası: 0 = adı sorguyla başlıyor, 1 = adında herhangi bir kelime sorguyla başlıyor,
/// 2 = adında geçiyor, 3 = yalnızca diğer alanlarda (açıklama, şehir) geçiyor.
int searchRank(String query, Iterable<String> names) {
  final q = searchFold(query.trim());
  if (q.isEmpty) return 0;
  var best = 3;
  for (final n in names) {
    final f = searchFold(n);
    if (f.startsWith(q)) return 0;
    if (f.split(RegExp(r'[\s()\-]+')).any((w) => w.startsWith(q))) {
      best = best < 1 ? best : 1;
    } else if (f.contains(q)) {
      best = best < 2 ? best : 2;
    }
  }
  return best;
}

/// Eser sayfasındaki "Keşif görevi" (Supabase: place_activities).
class PlaceActivity {
  final int id;
  final String placeId;
  final String kind; // gor, kesfet, tat, yap, fotograf, dinlen
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final String source; // örn. 'Cilt 2, s. 17'
  final int sortOrder;

  const PlaceActivity({
    required this.id,
    required this.placeId,
    required this.kind,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.source,
    required this.sortOrder,
  });

  /// Her eserde bulunan, veritabanında olmayan ortak görev: tabeladaki QR kodunu okutmak.
  /// Kimliği eksi eser numarasıdır (veritabanı görevleriyle çakışmaz).
  static int qrIdFor(String placeId) => -(int.tryParse(placeId) ?? 0);

  factory PlaceActivity.qr(String placeId) => PlaceActivity(
    id: qrIdFor(placeId),
    placeId: placeId,
    kind: 'qr',
    title: 'Tabeladaki QR kodunu okut',
    titleEn: 'Scan the QR code on the sign',
    description:
        'Eserin yanındaki tabelada karekodu bul ve uygulamayla okut. Bu görev yalnızca okutunca tamamlanır.',
    descriptionEn:
        'Find the QR code on the sign next to the building and scan it. This task completes only by scanning.',
    source: '',
    sortOrder: -1,
  );

  bool get isQr => kind == 'qr';

  factory PlaceActivity.fromJson(Map<String, dynamic> json) {
    String s(String key) => (json[key] as String? ?? '').trim();
    return PlaceActivity(
      id: (json['id'] as num).toInt(),
      placeId: json['place_id'].toString(),
      kind: s('kind'),
      title: s('title'),
      titleEn: s('title_en'),
      description: s('description'),
      descriptionEn: s('description_en'),
      source: s('source'),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  String titleFor(bool en) => en && titleEn.isNotEmpty ? titleEn : title;
  String descriptionFor(bool en) =>
      en && descriptionEn.isNotEmpty ? descriptionEn : description;

  /// "Cilt 2, s. 17" -> İngilizcede "Vol. 2, p. 17"
  String sourceFor(bool en) => en
      ? source.replaceAll('Cilt', 'Vol.').replaceAll(RegExp(r's\.\s*'), 'p. ')
      : source;
}

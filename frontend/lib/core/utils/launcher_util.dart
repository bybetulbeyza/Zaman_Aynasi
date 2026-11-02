import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics/analytics.dart';

class LauncherUtil {
  /// Harita uygulamasında yürüyüş yol tarifi açar.
  static Future<bool> openDirections(LatLng destination) {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=walking',
    );
    return _open(uri);
  }

  /// [source]: tıklamanın geldiği yer (örn. 'place_card', 'about'); varsa sayılır.
  static Future<bool> openUrl(String url, {String? source, String? placeId}) {
    var uri = Uri.parse(url);
    if (source != null) {
      Analytics.track(
        'inventory_click',
        placeId: placeId,
        meta: {'from': source},
      );
      // Hedef sitenin kendi istatistiğinde "uygulamadan gelen ziyaret" görünsün diye
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'utm_source': 'zaman_aynasi',
          'utm_medium': 'mobil_uygulama',
          'utm_content': source,
        },
      );
    }
    return _open(uri);
  }

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Bağlantı açılamadı: $e');
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics/analytics.dart';

class LauncherUtil {
  /// Harita uygulamasında yürüyüş yol tarifi açar.
  static Future<bool> openDirections(LatLng destination, {String? placeId}) {
    Analytics.track('directions_click', placeId: placeId);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=walking',
    );
    return _open(uri);
  }

  /// [source]: tıklamanın geldiği yer (örn. 'place_card', 'about'); varsa sayılır.
  static Future<bool> openUrl(String url, {String? source, String? placeId}) {
    if (source != null) {
      Analytics.track(
        'inventory_click',
        placeId: placeId,
        meta: {'from': source},
      );
    }
    return _open(Uri.parse(url));
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

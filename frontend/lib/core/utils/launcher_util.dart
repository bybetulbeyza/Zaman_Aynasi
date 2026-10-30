import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static Future<bool> openUrl(String url) => _open(Uri.parse(url));

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Bağlantı açılamadı: $e');
      return false;
    }
  }
}

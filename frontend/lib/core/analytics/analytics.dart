import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_lang.dart';

/// Anonim kullanım sayacı: ad, e-posta ya da konum içermez; yalnızca rastgele bir cihaz kimliği,
/// olay adı ve (varsa) eser kimliği Supabase'deki `analytics_events` tablosuna yazılır.
/// Hata olursa uygulama etkilenmez (sessizce yutulur).
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  static const _kDevice = 'analytics_device_id';
  String? _deviceId;
  final String _sessionId = _rand(12);

  static String _rand(int n) {
    final r = Random.secure();
    return List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _deviceId = p.getString(_kDevice);
      if (_deviceId == null) {
        _deviceId = _rand(24);
        await p.setString(_kDevice, _deviceId!);
      }
    } catch (_) {
      _deviceId ??= _rand(24); // yalnızca bu oturum için
    }
  }

  /// Beklemeden gönderir. Örn: `Analytics.track('inventory_click', placeId: '9', meta: {'from': 'place_card'})`.
  static void track(
    String event, {
    String? placeId,
    Map<String, dynamic>? meta,
  }) {
    instance._send(event, placeId, meta);
  }

  Future<void> _send(
    String event,
    String? placeId,
    Map<String, dynamic>? meta,
  ) async {
    try {
      if (_deviceId == null) await init();
      await Supabase.instance.client.from('analytics_events').insert({
        'event': event,
        'place_id': placeId,
        'device_id': _deviceId,
        'session_id': _sessionId,
        'lang': AppLang.instance.isEnglish ? 'en' : 'tr',
        'meta': meta,
      });
    } catch (e) {
      debugPrint('analytics: $e');
    }
  }
}

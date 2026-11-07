import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_lang.dart';

/// Supabase Auth sarmalayıcısı: e-posta/şifre, Google ve profil senkronu.
class AuthService {
  AuthService._();

  static SupabaseClient get _c => Supabase.instance.client;

  /// Google dönüşünde uygulamayı geri açan adres (AndroidManifest / Info.plist ile aynı).
  static const redirectUrl = 'io.supabase.zamanaynasi://login-callback/';

  static const _seenKey = 'auth_screen_seen';

  /// Giriş ekranı daha önce gösterildi mi (misafir seçilmiş olabilir)?
  static Future<bool> hasSeenAuth() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_seenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markAuthSeen() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_seenKey, true);
    } catch (_) {}
  }

  static User? get user => _c.auth.currentUser;
  static bool get isSignedIn => user != null;
  static Stream<AuthState> get changes => _c.auth.onAuthStateChange;

  static String get displayName {
    final u = user;
    if (u == null) return '';
    final meta = u.userMetadata ?? {};
    final name = (meta['full_name'] ?? meta['name'] ?? meta['display_name'])
        ?.toString()
        .trim();
    if (name != null && name.isNotEmpty) return name;
    return (u.email ?? '').split('@').first;
  }

  /// Önce kullanıcının yüklediği fotoğraf, yoksa Google profil fotoğrafı.
  static String? get avatarUrl {
    final m = user?.userMetadata;
    for (final k in ['custom_avatar_url', 'avatar_url', 'picture']) {
      final v = m?[k]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Yüklenmiş özel fotoğraf var mı (kaldır düğmesi için)?
  static bool get hasCustomAvatar =>
      (user?.userMetadata?['custom_avatar_url']?.toString() ?? '').isNotEmpty;

  static Future<void> signIn(String email, String password) async {
    await _c.auth.signInWithPassword(email: email.trim(), password: password);
    await syncProfile();
  }

  /// true: oturum hemen açıldı; false: e-posta doğrulaması bekleniyor.
  static Future<bool> signUp(String email, String password, String name) async {
    final res = await _c.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()},
      emailRedirectTo: redirectUrl,
    );
    if (res.session != null) {
      await syncProfile();
      return true;
    }
    return false;
  }

  static Future<void> signInWithGoogle() =>
      _c.auth.signInWithOAuth(OAuthProvider.google, redirectTo: redirectUrl);

  static Future<void> signOut() => _c.auth.signOut();

  /// Şifre sıfırlama bağlantısı gönderir (hesap var ya da yok, aynı yanıt döner).
  static Future<void> sendPasswordReset(String email) =>
      _c.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectUrl);

  /// Sıfırlama bağlantısından açılan oturumda yeni şifreyi kaydeder.
  static Future<void> updatePassword(String password) async {
    await _c.auth.updateUser(UserAttributes(password: password));
  }

  /// Hesabı ve ona bağlı profil/ilerleme satırlarını kalıcı olarak siler.
  /// Sunucuda `delete_my_account()` fonksiyonu gerekir (account_setup.sql).
  static Future<void> deleteAccount() async {
    final u = user;
    if (u == null) return;
    try {
      await _c.storage.from('avatars').remove(['${u.id}/avatar.jpg']);
    } catch (_) {}
    await _c.rpc('delete_my_account');
    try {
      await _c.auth.signOut(scope: SignOutScope.local);
    } catch (_) {}
  }

  /// Profil fotoğrafı yükler (`avatars` kovası, kullanıcının kendi klasörü).
  static Future<void> uploadAvatar(Uint8List bytes) async {
    final u = user;
    if (u == null) return;
    final path = '${u.id}/avatar.jpg';
    final bucket = _c.storage.from('avatars');
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    // Sonuna sürüm eklenir; aksi hâlde eski fotoğraf önbellekten görünür
    final url =
        '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
    await _c.auth.updateUser(UserAttributes(data: {'custom_avatar_url': url}));
    await syncProfile();
  }

  /// Yüklenen fotoğrafı kaldırır (varsa Google fotoğrafına döner).
  static Future<void> removeAvatar() async {
    final u = user;
    if (u == null) return;
    try {
      await _c.storage.from('avatars').remove(['${u.id}/avatar.jpg']);
    } catch (_) {}
    await _c.auth.updateUser(UserAttributes(data: {'custom_avatar_url': ''}));
    await syncProfile();
  }

  /// Giriş yöntemi: 'google' ya da 'email'.
  static String get provider =>
      (user?.appMetadata['provider'] ?? 'email').toString();

  static DateTime? get createdAt => DateTime.tryParse(user?.createdAt ?? '');

  /// Görünen adı günceller (hesap meta verisi + `profiles` satırı).
  static Future<void> updateName(String name) async {
    await _c.auth.updateUser(UserAttributes(data: {'full_name': name.trim()}));
    await syncProfile();
  }

  /// `profiles` tablosuna kullanıcının bilgilerini yazar (hata olursa uygulama etkilenmez).
  static Future<void> syncProfile() async {
    final u = user;
    if (u == null) return;
    try {
      await _c.from('profiles').upsert({
        'id': u.id,
        'email': u.email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'preferred_lang': AppLang.instance.isEnglish ? 'en' : 'tr',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Supabase hata mesajını kullanıcıya gösterilecek metnin sözlük anahtarına çevirir.
  static String friendlyErrorKey(Object e) {
    final m = e is AuthException ? e.message.toLowerCase() : e.toString();
    if (m.contains('invalid login')) return 'auth_err_wrong';
    if (m.contains('already registered')) return 'auth_err_exists';
    if (m.contains('email not confirmed')) return 'auth_err_unconfirmed';
    if (m.contains('socket') || m.contains('network'))
      return 'auth_err_network';
    return 'auth_err_generic';
  }
}

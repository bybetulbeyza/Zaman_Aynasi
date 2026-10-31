import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_lang.dart';

/// Supabase Auth sarmalayıcısı: e-posta/şifre, Google ve profil senkronu.
class AuthService {
  AuthService._();

  static SupabaseClient get _c => Supabase.instance.client;

  /// Google dönüşünde uygulamayı geri açan adres (AndroidManifest / Info.plist ile aynı).
  static const redirectUrl = 'io.supabase.zamanaynasi://login-callback/';

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

  static String? get avatarUrl {
    final v =
        user?.userMetadata?['avatar_url'] ?? user?.userMetadata?['picture'];
    return v?.toString();
  }

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

  /// Supabase hata mesajını kullanıcıya göstermelik hâle getirir.
  static String friendlyError(Object e, bool en) {
    final m = e is AuthException ? e.message.toLowerCase() : e.toString();
    if (m.contains('invalid login')) {
      return en ? 'Wrong e-mail or password.' : 'E-posta veya şifre hatalı.';
    }
    if (m.contains('already registered')) {
      return en
          ? 'This e-mail is already registered.'
          : 'Bu e-posta zaten kayıtlı.';
    }
    if (m.contains('email not confirmed')) {
      return en
          ? 'Please confirm your e-mail first.'
          : 'Önce e-postanı doğrulaman gerekiyor.';
    }
    if (m.contains('socket') || m.contains('network')) {
      return en ? 'No connection.' : 'Bağlantı kurulamadı.';
    }
    return en ? 'Something went wrong.' : 'Bir sorun oluştu.';
  }
}

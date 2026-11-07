import 'package:flutter/material.dart';

/// Açık sayfaların adlarını tutar; aynı sayfanın üst üste yığılmasını önlemek için kullanılır.
/// (MaterialApp.navigatorObservers içinde kayıtlıdır.)
class AppNav extends NavigatorObserver {
  AppNav._();
  static final AppNav instance = AppNav._();

  final List<Route<dynamic>> _stack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _stack[i] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
  }

  bool _isOpen(String name) => _stack.any((r) => r.settings.name == name);

  /// Sayfa adları: eser sayfası, hikâye akışı, pasaport…
  static String place(String id) => 'place:$id';
  static String reels(String? placeId) => 'reels:${placeId ?? 'all'}';
  static const String passport = 'passport';

  /// [name] adlı sayfa zaten açıksa ona geri döner (üstündekiler kapanır); değilse yenisini açar.
  static Future<T?> open<T>(
    BuildContext context,
    String name,
    WidgetBuilder builder,
  ) {
    final nav = Navigator.of(context);
    if (instance._isOpen(name)) {
      nav.popUntil((r) => r.settings.name == name || r.isFirst);
      return Future<T?>.value();
    }
    return nav.push<T>(
      MaterialPageRoute<T>(
        settings: RouteSettings(name: name),
        builder: builder,
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

/// Bir Navigator'daki açık sayfaları izler; aynı sayfanın üst üste yığılmasını önlemek için kullanılır.
/// Kök gezgin ve her sekmenin kendi gezgini ayrı bir örnek kullanır.
class StackObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  /// Açık sayfa sayısı (gezinme bitince güncellenir; build sırasında değişmez).
  final ValueNotifier<int> depth = ValueNotifier(0);
  void _changed() => scheduleMicrotask(() => depth.value = _stack.length);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _stack[i] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _changed();
  }

  bool isOpen(String name) => _stack.any((r) => r.settings.name == name);
}

class AppNav {
  AppNav._();

  /// Kök gezginin gözlemcisi (MaterialApp.navigatorObservers).
  static final StackObserver root = StackObserver();

  /// Sayfa adları: eser sayfası, hikâye akışı, pasaport…
  static String place(String id) => 'place:$id';
  static String reels(String? placeId) => 'reels:${placeId ?? 'all'}';
  static const String passport = 'passport';

  /// [name] adlı sayfa bu gezginde zaten açıksa ona geri döner (üstündekiler kapanır);
  /// değilse yenisini açar. [rootNavigator]: tam ekran sayfalar (alt menü görünmez).
  static Future<T?> open<T>(
    BuildContext context,
    String name,
    WidgetBuilder builder, {
    bool rootNavigator = false,
  }) {
    final nav = Navigator.of(context, rootNavigator: rootNavigator);
    final obs = nav.widget.observers.whereType<StackObserver>().firstOrNull;
    if (obs != null && obs.isOpen(name)) {
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

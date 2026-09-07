import 'package:flutter/material.dart';
import 'package:quick_social/theme/app_tokens.dart';

extension BuildContextX on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;

  bool get isMobile => width < AppBreakpoints.tablet;
  bool get isTablet => width >= AppBreakpoints.tablet;
  bool get isDesktop => width >= AppBreakpoints.desktop;

  T responsive<T>({
    required T sm,
    T? md,
    T? lg,
  }) {
    if (isDesktop) {
      return lg ?? md ?? sm;
    } else if (isTablet) {
      return md ?? sm;
    } else {
      return sm;
    }
  }

  Future<T?> push<T>({Route<T>? route, Widget? widget}) {
    assert(route != null || widget != null);

    return Navigator.of(this)
        .push<T>(route ?? MaterialPageRoute(builder: (_) => widget!));
  }

  /// Replaces the current route, so it cannot be returned to.
  Future<T?> pushReplacement<T>({Route<T>? route, Widget? widget}) {
    assert(route != null || widget != null);

    return Navigator.of(this).pushReplacement<T, void>(
      route ?? MaterialPageRoute(builder: (_) => widget!),
    );
  }

  void pop<T>([T? result]) => Navigator.of(this).pop<T>(result);
}

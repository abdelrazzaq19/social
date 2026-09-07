import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_social/theme/app_theme.dart';

/// WCAG relative luminance.
double _luminance(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio, 1.0 (identical) to 21.0 (black on white).
double _contrast(Color foreground, Color background) {
  final double a = _luminance(foreground);
  final double b = _luminance(background);
  final double lighter = math.max(a, b);
  final double darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme', () {
    test('builds both brightnesses', () {
      final ThemeData light = AppTheme.light();
      final ThemeData dark = AppTheme.dark();

      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    });

    test('uses the bundled font family, not a runtime-fetched one', () {
      for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
        expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
      }
    });

    test('text-on-surface pairs meet WCAG AA (4.5:1)', () {
      for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
        final ColorScheme s = theme.colorScheme;
        final String label = s.brightness.name;

        final pairs = <String, (Color, Color)>{
          'onSurface / surface': (s.onSurface, s.surface),
          'onSurfaceVariant / surface': (s.onSurfaceVariant, s.surface),
          'onPrimary / primary': (s.onPrimary, s.primary),
          'onPrimaryContainer / primaryContainer': (
            s.onPrimaryContainer,
            s.primaryContainer,
          ),
          'onSecondaryContainer / secondaryContainer': (
            s.onSecondaryContainer,
            s.secondaryContainer,
          ),
          'onError / error': (s.onError, s.error),
          'onErrorContainer / errorContainer': (
            s.onErrorContainer,
            s.errorContainer,
          ),
          'onInverseSurface / inverseSurface': (
            s.onInverseSurface,
            s.inverseSurface,
          ),
        };

        pairs.forEach((name, pair) {
          final double ratio = _contrast(pair.$1, pair.$2);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$label $name is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }
    });

    test('primary is legible on surface, for accent text and icons', () {
      for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
        final ColorScheme s = theme.colorScheme;
        final double ratio = _contrast(s.primary, s.surface);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${s.brightness.name} primary on surface is '
              '${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('every interactive component clears a 48dp minimum tap target', () {
      final ThemeData theme = AppTheme.light();

      expect(theme.filledButtonTheme.style?.minimumSize, isNotNull);
      expect(theme.outlinedButtonTheme.style?.minimumSize, isNotNull);
      expect(theme.iconButtonTheme.style?.minimumSize, isNotNull);
    });
  });
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_social/theme/app_tokens.dart';

/// The app's Material 3 themes.
///
/// Both brightnesses are derived from a single [seed], so light and dark stay
/// in step: change the seed and the whole system moves with it.
abstract final class AppTheme {
  /// The brand seed colour.
  ///
  /// Measured output, for anything outside Dart that needs to match (the web
  /// manifest and the pre-boot splash in `web/index.html`):
  ///
  /// | role    | light     | dark      |
  /// | ------- | --------- | --------- |
  /// | primary | `#0d6b58` | `#86d6bf` |
  /// | surface | `#f5fbf7` | `#0f1513` |
  static const Color seed = Colors.tealAccent;

  /// Bundled in `assets/fonts/`, so the app renders correctly offline and
  /// never flashes a fallback face.
  static const String fontFamily = 'DM Sans';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final bool isDark = brightness == Brightness.dark;

    // `ThemeData.fontFamily` does not override a family already baked into an
    // explicit `textTheme`, so apply it here rather than relying on that.
    final TextTheme textTheme = _textTheme(
      (isDark
              ? Typography.material2021().white
              : Typography.material2021().black)
          .apply(fontFamily: fontFamily),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: _overlayStyle(scheme, isDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navigationBar,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTapTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minTapTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.pillAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.pillAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.pillAll,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlTop),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: scheme.outlineVariant,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.titleSmall,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  /// Tightens the tracking on the large sizes.
  ///
  /// Material's defaults are tuned for Roboto; DM Sans is wider, so the
  /// display and headline sizes need pulling in to stop them looking loose.
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(letterSpacing: -1),
      displayMedium: base.displayMedium?.copyWith(letterSpacing: -0.75),
      displaySmall: base.displaySmall?.copyWith(letterSpacing: -0.5),
      headlineLarge: base.headlineLarge?.copyWith(letterSpacing: -0.5),
      headlineMedium: base.headlineMedium?.copyWith(letterSpacing: -0.5),
      headlineSmall: base.headlineSmall?.copyWith(letterSpacing: -0.25),
      titleLarge: base.titleLarge?.copyWith(letterSpacing: -0.25),
    );
  }

  /// Keeps the system bars — and, on web, the browser's theme colour — in
  /// step with the active theme.
  static SystemUiOverlayStyle _overlayStyle(ColorScheme scheme, bool isDark) {
    return SystemUiOverlayStyle(
      // On web the engine mirrors this into `<meta name="theme-color">`, and a
      // transparent value leaves the browser chrome untinted — so give the web
      // a real colour. On Android transparent is what edge-to-edge wants.
      statusBarColor: kIsWeb ? scheme.surface : Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: scheme.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  /// The overlay style for a given [brightness], for callers outside an
  /// `AppBar` (a full-bleed page, say).
  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    return _overlayStyle(
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      isDark,
    );
  }
}

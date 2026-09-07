import 'package:flutter/widgets.dart';

/// Design tokens.
///
/// Every spacing, radius, duration, and breakpoint in the app comes from here.
/// A literal in a widget file is a bug: it is the thing that drifts when the
/// design changes.

/// The 4pt spacing scale.
abstract final class AppSpacing {
  /// 4 — hairline gaps, icon-to-label.
  static const double xs = 4;

  /// 8 — inside a chip or a dense tile.
  static const double sm = 8;

  /// 12 — between related elements.
  static const double md = 12;

  /// 16 — the default page and card gutter.
  static const double lg = 16;

  /// 24 — between sections.
  static const double xl = 24;

  /// 32 — around a page's major blocks.
  static const double xxl = 32;
}

/// Corner radii.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  /// Large enough to read as a pill at any height this app uses.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// For sheets and anything anchored to the bottom edge.
  static const BorderRadius xlTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// Animation durations.
///
/// Keep these few. Three speeds read as one system; seven read as noise.
abstract final class AppDuration {
  /// 150ms — state changes the user caused directly (a tap, a toggle).
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — things entering or leaving the screen.
  static const Duration medium = Duration(milliseconds: 250);

  /// 400ms — full-screen transitions.
  static const Duration slow = Duration(milliseconds: 400);
}

/// Layout breakpoints, in logical pixels.
///
/// These are the single source of truth for `BuildContextX.isMobile`,
/// `isTablet`, and `isDesktop`.
abstract final class AppBreakpoints {
  /// At and above this width the layout switches from the bottom navigation
  /// bar to the navigation rail.
  static const double tablet = 768;

  /// At and above this width the navigation rail extends to show labels.
  static const double desktop = 1024;

  /// The widest the main content column is allowed to grow.
  ///
  /// Feed content beyond roughly this width stops being comfortable to read
  /// and starts looking stretched.
  static const double maxContentWidth = 640;
}

/// Fixed component sizes that more than one widget needs to agree on.
abstract final class AppSizes {
  /// The minimum size of anything the user is meant to tap.
  static const double minTapTarget = 48;

  /// Diameter of the avatar in the story row.
  static const double storyAvatar = 60;

  /// Height of the story row, including its label.
  static const double storyRail = 110;

  /// Height of the bottom navigation bar.
  static const double navigationBar = 68;
}

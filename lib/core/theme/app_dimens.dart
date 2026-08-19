/// Spacing, radii and layout metrics for the design system.
///
/// Use these instead of magic numbers so paddings stay consistent
/// across the (landscape) screens.
class AppDimens {
  AppDimens._();

  // ── Spacing scale ───────────────────────────────────────────────────────
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ── Corner radii ────────────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 30;

  // ── Component sizes ─────────────────────────────────────────────────────
  static const double buttonHeight = 52;
  static const double inputHeight = 52;
  static const double iconButton = 44;

  // ── Landscape content constraints ───────────────────────────────────────
  /// Max readable width for a single column of content.
  static const double maxContentWidth = 520;

  /// Max width a ticket card should ever occupy.
  static const double maxTicketWidth = 460;
}

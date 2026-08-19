import 'package:flutter/material.dart';

/// Central design-system palette for the Housie app.
///
/// Every screen and widget must read colors from here instead of
/// hard-coding hex values, so the whole app can be re-themed from one place.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Deepest app background (behind everything).
  static const Color background = Color(0xFF0B1220);

  /// Slightly lifted background used for full-screen decorative layers.
  static const Color backgroundAlt = Color(0xFF0D1B3E);

  /// Standard elevated panel / dialog surface.
  static const Color surface = Color(0xFF111A2E);

  /// Brighter surface for hovered/active panels and chips.
  static const Color surfaceHigh = Color(0xFF1A2540);

  /// Muted surface for low-emphasis fills.
  static const Color surfaceMuted = Color(0xFF16202F);

  // ── Brand ───────────────────────────────────────────────────────────────
  /// Primary violet — buttons, highlights, brand moments.
  static const Color primary = Color(0xFF7C4DFF);

  /// Deeper violet for gradients and pressed states.
  static const Color primaryDark = Color(0xFF5E35B1);

  /// Secondary cyan/teal — links, join actions, accents.
  static const Color secondary = Color(0xFF26C6DA);

  /// Gold/amber — money, prizes, hosts, called numbers.
  static const Color accent = Color(0xFFFFB300);

  /// Deep gold used in prize-pool gradients.
  static const Color accentDark = Color(0xFFB8860B);

  // ── Status ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00E676);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB300);
  static const Color online = Color(0xFF69F0AE);
  static const Color offline = Color(0xFFFF5252);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8C4D9);
  static const Color textMuted = Color(0xFF6B7A90);

  /// Dark text placed on top of bright accents (amber, white ticket, etc.).
  static const Color onAccent = Color(0xFF14161B);

  // ── Borders & lines ─────────────────────────────────────────────────────
  static const Color border = Color(0x1AFFFFFF); // white @ 10%
  static const Color borderStrong = Color(0x33FFFFFF); // white @ 20%

  // ── Ticket (light paper look, kept readable in dark mode) ───────────────
  static const Color ticketBg = Colors.white;
  static const Color ticketBorder = Color(0xFF94A3B8);
  static const Color ticketEmpty = Color(0xFFF1F5F9);
  static const Color ticketGridLine = Color(0xFFCBD5E1);
  static const Color ticketNumber = Color(0xFF0F172A);

  // ── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFF26C6DA)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF131E33), Color(0xFF0D1626)],
  );
}

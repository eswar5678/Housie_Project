import 'package:flutter/material.dart';

/// Central design-system palette — "Aurora Lounge".
///
/// Deep space-indigo base with violet / fuchsia / teal aurora accents and a
/// celebratory gold. Every screen and widget reads colors from here only.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  /// Deepest app background.
  static const Color background = Color(0xFF07070F);

  /// Deeper edge used at the bottom of background gradients.
  static const Color backgroundDeep = Color(0xFF05050C);

  /// Standard elevated panel / glass surface.
  static const Color surface = Color(0xFF141422);

  /// Brighter surface for hovered/active panels and chips.
  static const Color surfaceHigh = Color(0xFF1C1C31);

  /// Muted surface for low-emphasis fills.
  static const Color surfaceMuted = Color(0xFF0E0E1A);

  // ── Brand ───────────────────────────────────────────────────────────────
  /// Primary violet.
  static const Color primary = Color(0xFF8B5CF6);

  /// Deeper violet for gradients and pressed states.
  static const Color primaryDark = Color(0xFF6D28D9);

  /// Secondary teal — join actions, links, accents.
  static const Color secondary = Color(0xFF2DD4BF);

  /// Gold — money, prizes, hosts, called numbers.
  static const Color accent = Color(0xFFFBBF24);

  /// Deep gold used in prize gradients.
  static const Color accentDark = Color(0xFFB45309);

  /// Fuchsia — celebration, life, claims.
  static const Color fuchsia = Color(0xFFEC4899);

  /// Cyan — joins, cool highlights.
  static const Color cyan = Color(0xFF22D3EE);

  // ── Status ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFBBF24);
  static const Color online = Color(0xFF34D399);
  static const Color offline = Color(0xFFFB7185);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFC7D0EA);
  static const Color textMuted = Color(0xFF7C87A8);

  /// Dark text placed on top of bright accents (gold, white ticket, etc.).
  static const Color onAccent = Color(0xFF17100A);

  // ── Borders & lines ─────────────────────────────────────────────────────
  static const Color border = Color(0x1AFFFFFF); // white @ 10%
  static const Color borderStrong = Color(0x2EFFFFFF); // white @ 18%

  // ── Ticket (warm paper look, kept readable in dark mode) ────────────────
  static const Color ticketBg = Color(0xFFFFFDF6);
  static const Color ticketBorder = Color(0xFFE7E1D4);
  static const Color ticketEmpty = Color(0xFFF4EFE4);
  static const Color ticketGridLine = Color(0xFFDCD5C4);
  static const Color ticketNumber = Color(0xFF22303E);

  // ── Gradients ───────────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2DD4BF), Color(0xFF22D3EE)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFFDE68A)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF16162A), Color(0xFF0C0C18)],
  );

  /// Gradient used to render the wordmark / headline text.
  static const LinearGradient titleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFA78BFA), Color(0xFFEC4899), Color(0xFFFBBF24)],
  );
}

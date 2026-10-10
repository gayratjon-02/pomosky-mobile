import 'package:flutter/animation.dart';

/// The design language of the app in one place. Screens use these names, never
/// loose numbers or colours, so the whole app keeps one rhythm.
///
/// The look: a night sky with a warm sun. Ink backgrounds, cream text (never
/// pure white), one warm accent (apricot) for what matters, a cool sky blue
/// for calm things, mint for rest. Surfaces are frosted glass over the live
/// sky. Spacing follows a 4-point scale.
abstract final class Night {
  static const background = Color(0xFF0A0D1F); // deepest night
  static const surface = Color(0xFF141936); // solid panels
  static const raised = Color(0xFF1D2347);
}

abstract final class Tint {
  static const cream = Color(0xFFF6F0E4); // main text
  static const creamDim = Color(0xB3F6F0E4); // secondary text (70%)
  static const creamFaint = Color(0x80F6F0E4); // hints (50%)
  static const apricot = Color(
    0xFFFFB36B,
  ); // the accent: focus, primary actions
  static const apricotDeep = Color(0xFFFF8F5A);
  static const sky = Color(0xFF8FB4FF); // calm, links, selection
  static const mint = Color(0xFF7BE0B4); // breaks
  static const rose = Color(0xFFFF8A9B); // errors
  static const amber = Color(0xFFF5C26B); // paused
}

/// Spacing on a 4-point scale.
abstract final class Gap {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;
}

abstract final class Radii {
  static const double chip = 14;
  static const double card = 24;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class Motion {
  static const quick = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const curve = Curves.easeOutCubic;
}

/// Frosted glass: a see-through wash with a hairline edge.
abstract final class Glass {
  static const fill = Color(0x1AFFFFFF); // white at 10%
  static const fillStrong = Color(0x29FFFFFF); // 16%
  static const edge = Color(0x24FFFFFF); // 14%
  static const blur = 18.0;
}

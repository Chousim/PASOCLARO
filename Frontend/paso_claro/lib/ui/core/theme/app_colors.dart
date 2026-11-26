import 'package:flutter/material.dart';

/// Calibrated color palette from DESIGN.md (WCAG AAA, single Zinc neutral family,
/// single Agave Jade accent, strictly no pure black #000000, no purple/neon).
abstract final class AppColors {
  // Neutral Zinc surfaces & borders
  static const Color canvasAlabaster = Color(0xFFFAFAFA);
  static const Color purePaper = Color(0xFFFFFFFF);
  static const Color softStone = Color(0xFFF4F4F5);
  static const Color whisperBorder = Color(0xFFE4E4E7);
  static const Color strongBorder = Color(0xFFD4D4D8);

  // Neutral Zinc ink hierarchy (never pure #000000)
  static const Color charcoalInk = Color(0xFF18181B);
  static const Color slateCharcoal = Color(0xFF3F3F46);
  static const Color graphiteSecondary = Color(0xFF52525B);
  static const Color mutedMeta = Color(0xFF71717A);

  // Single Brand Accent (Agave Jade — saturation 66%, AAA with white)
  static const Color agaveJade = Color(0xFF135D4F);
  static const Color agaveDeep = Color(0xFF0E4A3E);
  static const Color agaveMist = Color(0xFFECF5F3);

  // Semantic Alert Ink (Strictly for Missing-Document Gap Detector & errors)
  static const Color brickAlert = Color(0xFF9F2D20);
  static const Color brickWash = Color(0xFFFEF2F2);
}

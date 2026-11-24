import 'dart:ui' show Color;

/// Design values shared by the People Bridge apps.
abstract final class AppTokens {
  /// Provisional pastel seed colour (owner decision, 2026-11-23). The final
  /// brand (decision D5) replaces it here only.
  static const Color seed = Color(0xFF9CD3C4);

  static const double spaceSmall = 8;
  static const double spaceMedium = 16;

  static const double radius = 16;
}

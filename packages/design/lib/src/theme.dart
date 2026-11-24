import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Light and dark themes built from [AppTokens.seed].
///
/// The tonal scheme keeps containers and surfaces pastel while text colours
/// stay dark enough to read (checked by the contrast tests).
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.seed,
      brightness: brightness,
    ),
    // Keeps every tappable control at least 48 x 48 dp.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: AppTokens.spaceMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppTokens.radius)),
      ),
    ),
  );
}

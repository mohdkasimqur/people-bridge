import 'package:app_design/app_design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, theme, brightness) in [
    ('light', AppTheme.light(), Brightness.light),
    ('dark', AppTheme.dark(), Brightness.dark),
  ]) {
    group('$name theme', () {
      final s = theme.colorScheme;

      test('uses the requested brightness', () {
        expect(s.brightness, brightness);
      });

      test('meets 48 dp tap targets', () {
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      });

      // WCAG 2.1 AA: at least 4.5:1 for normal text.
      for (final (pair, fg, bg) in [
        ('onSurface / surface', s.onSurface, s.surface),
        ('onSurfaceVariant / surface', s.onSurfaceVariant, s.surface),
        ('onPrimary / primary', s.onPrimary, s.primary),
        (
          'onPrimaryContainer / primaryContainer',
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        (
          'onSecondaryContainer / secondaryContainer',
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
      ]) {
        test('$pair contrast is at least 4.5:1', () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }
    });
  }

  test('the light theme is pastel: containers are light tints', () {
    final s = AppTheme.light().colorScheme;
    expect(s.primaryContainer.computeLuminance(), greaterThan(0.5));
    expect(s.surface.computeLuminance(), greaterThan(0.8));
  });
}

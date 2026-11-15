# Phase 1 (Foundation) — part 2 evidence

Date: 2026-11-16. Machine: Windows 11, Flutter 3.50.0 (Dart 3.14.0). No device or emulator used.

This repairs the broker login screen so the app compiles. **Phase 1 is still not complete.**

## Cause (confirmed)

One line was missing in `submitProfile()` in `lib/jober_indiaScreens.dart/broker/screen_broker_login.dart`: the opening `if` of the Privacy Policy check. The code read:

```dart
  privacyPolicyError =
      'Please accept the Privacy Policy and Terms & Conditions.';
  valid = false;
} else {
  privacyPolicyError = null;
}
```

The orphaned `} else {` closed `submitProfile` and then the whole state class early. Everything after it, including `build`, fell outside the class, which produced all 252 errors. The line is missing in baseline commit `912d74b` as well, and it was not a commented-out line there.

## Fix

- Added the missing line `if (!privacyPolicyAccepted) {`. `privacyPolicyAccepted` is the field the screen's own Privacy Policy checkbox already sets, and `if (!privacyPolicyAccepted)` is the check used by sibling login screens (`food_delivery_login.dart`, `fish_delivery_login.dart`, `corrier_login.dart`). Nothing else in the file was changed.
- Removed the unused import of `location_backgrnd_servce.dart` from `lib/main.dart`. `screen_home.dart` still imports that file, so its background entry point stays in the app.
- Added `test/app_compiles_test.dart`: it imports `main.dart`, so the test run compiles every screen the app reaches, and it constructs `MyApp`. It does not start the app.

Guessed: nothing. Status of the condition: confirmed from the surrounding code and the sibling screens.

## Commands and results

| Command | Before (commit `50b917e`) | After |
|---|---|---|
| `flutter analyze` errors | 252 | 0 |
| `flutter analyze` warnings | 7 | 0 |
| `flutter analyze` infos | 131 | 125 |
| `flutter test` | 2 passed | 3 passed, 0 failed |
| `flutter build apk --debug` | failed (toolchain) | failed (toolchain) |
| `graphify update .` | — | graph rebuilt |

`flutter analyze` still exits with code 1 because of the 125 infos: 113 deprecated API uses, 10 `unnecessary_underscores`, 1 `use_build_context_synchronously`, 1 `unnecessary_import`. They were not touched.

Build failure message: "The Java version used for the build is 25.0.4, which is incompatible with Gradle 8.14." The machine and the Android toolchain files were not changed.

## Left open

- In the repaired check, `privacyPolicyError`, `locationError` are set without `setState`, unlike the neighbouring checks. This is how the code was written; it was left as is to avoid a behaviour change. The message may not show until the next rebuild.
- The other 6 warnings that disappeared (unused fields and variable in the same file) were side effects of the broken class and needed no change.

## Not tested

- No Android or iOS build completed; nothing was installed or run on a device or emulator.
- The broker registration flow was not run: OTP, the Privacy Policy check, saving to Hive and Firestore.
- The standard regression set was not run.

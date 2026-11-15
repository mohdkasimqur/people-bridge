# Phase 1 (Foundation) — part 1 evidence

Date: 2026-11-15. Machine: Windows 11, Flutter 3.50.0 (Dart 3.14.0). No device or emulator used.

This covers the unblocked half of Phase 1 only. **Phase 1 is not complete**: brand name and IDs, signing, Firebase rules export, Firestore export, Crashlytics, log clean-up and the check script are still open.

## Result in one table

| Measure | Before | After |
|---|---|---|
| Dart lines under `lib/` | 300,930 | 222,921 |
| Dart files under `lib/` | 149 | 148 |
| `flutter analyze` errors | 252 | 252 |
| `flutter analyze` warnings | 7 | 7 |
| `flutter analyze` infos | 133 | 131 |
| `flutter test` | failed to compile (0 passed, 1 failed) | 2 passed, 0 failed |
| `flutter build apk --debug` | failed (toolchain) | failed (toolchain) |

## Important finding: the app did not compile before this work

All 252 analyzer errors, and 6 of the 7 warnings, are in one file, `lib/jober_indiaScreens.dart/broker/screen_broker_login.dart` (173 undefined identifiers, 42 undefined functions, syntax errors). They exist in baseline commit `912d74b`. They were **not fixed** here, because the task allowed no behaviour change. After normalising line numbers, the set of error and warning messages is identical before and after. The seventh warning is an unused import in `lib/main.dart`.

Until that file is repaired the app cannot be built on any machine. Status: confirmed, open.

## Commands run

| Command | Before | After |
|---|---|---|
| `flutter pub get` | OK, "Changed 8 dependencies" | OK, "Changed 21 dependencies" |
| `flutter analyze` | exit 1; 392 issues | exit 1; 390 issues |
| `flutter test` | exit 1; `widget_test.dart` failed to load (compile errors in `screen_broker_login.dart`) | exit 0; "All tests passed!" (2 tests) |
| `flutter build apk --debug` | exit 1 | exit 1 |
| `graphify update .` | — | graph rebuilt |

Build failure message, both runs: "Gradle build failed due to Java/Gradle incompatibility. The Java version used for the build is 25.0.4, which is incompatible with Gradle 8.14." `android/local.properties` also points `sdk.dir` at a Linux path from another machine. The machine was not changed. The Dart compile step was never reached, and it would fail on the 252 errors above.

## Commented-out code removal

Done by a script kept outside the project. It removes whole-line `//` comments that are disabled code, plus headings and separators that sit inside a disabled block, and collapses the blank lines left behind.

- 95 files changed; 76,742 lines removed: 62,664 comment lines and 14,078 blank lines.
- 13,531 whole-line comments kept: explanatory comments, section headings attached to live code, `// ignore:` directives.
- `///` doc comments, `/* */` blocks and comments at the end of a code line were not touched.

Verification, run on `git diff -U0 -- lib` before any other change was made:

| Check | Result |
|---|---|
| Removed lines that are not a `//` comment and not blank | 0 |
| Removed `///` doc lines | 0 |
| Removed `// ignore` lines | 0 |
| Added lines that are not blank | 0 (3 blank lines shown as added by diff alignment) |
| Analyzer messages before vs after, line numbers ignored | identical, 392 = 392, 0 differences |

Known limits: the code-or-prose decision is a heuristic. A prose comment separated by a blank line from live code and next to a disabled block was treated as part of that block. About 6% of `lib/` lines are still whole-line comments. The audit estimate of 47% commented-out lines was not reproduced: whole-line `//` comments were 76,779 of 300,930 lines (25.5%) before removal.

## Call feature removal

Search used: `graphify query` and a text search for `screen_call`, `ScreenCall`, `webrtc`, `RTC*`, `'calls'`. The only caller was the chat screen.

- Deleted `lib/jober_indiaScreens.dart/Message/screen_call.dart` (the only file using `flutter_webrtc`).
- In `lib/jober_indiaScreens.dart/Message/screen_message.dart` removed: the `screen_call.dart` import; the `_incomingCallSubscription` and `_activeIncomingCallId` fields; `_startIncomingCallListener` and its call in `initState`; `_showIncomingVoiceCall`; `_rejectIncomingCall`; `_acceptIncomingCall`; the "Voice call" button in the chat app bar; `_startVoiceCall`; the subscription cancel in `dispose`.
- This removed every read and write of the Firestore `calls` collection in the app (5 places). Existing `calls` documents and any rules for them in Firebase were not touched.
- Phone-dialler buttons (`url_launcher`, for example `callShop`) are not in-app calls and were left alone.

## Packages removed from `pubspec.yaml`

Each had zero imports under `lib/` and `test/` when searched.

| Package | Reason |
|---|---|
| `flutter_webrtc` | only used by the deleted call screen |
| `firebase_messaging` | unused |
| `flutter_background_service` | unused |
| `flutter_overlay_window` | unused |
| `google_places_flutter` | unused |
| `permission_handler` | unused (`openAppSettings` in the code is Geolocator's) |

Also removed the `flutter_overlay_window` `OverlayService` declaration from `android/app/src/main/AndroidManifest.xml`. No package turned out to be in use. Permissions in the manifest were not reviewed or changed.

## Test

`test/widget_test.dart` (the default counter test, which could never pass) was replaced by `test/distance_plan_test.dart`: two tests of `DistancePlan.finalPrice`, the subscription price after an offer percentage. It was executed and passed. It does not load the app, so it is not a smoke test of the app; a real smoke test is impossible until `screen_broker_login.dart` compiles.

## Other changes in the commit

- `analysis_options.yaml`: Flutter 3.50 added an `analyzer: exclude:` block for build and platform folders during `flutter pub get`. Kept, because the tool re-adds it.
- `pubspec.lock` and the generated plugin registrants for Linux, macOS and Windows were rewritten by `flutter pub get`.

## Not tested

- No Android or iOS build completed, so nothing was installed or run on a device or emulator.
- The standard regression set (sign in, register partners, LIVE, search, chat, logout) was not run, before or after.
- The chat screen without the call button was not seen running.
- Release build, cold-start time and app size were not measured.
- iOS was not built and iOS pods were not reinstalled.

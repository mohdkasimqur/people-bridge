# Phase 1 (Foundation) — part 3 evidence: verification

Date: 2026-11-16. Machine: Windows 11, Flutter 3.50.0 (Dart 3.14.0). No device or emulator used.

**Phase 1 cannot be marked complete.** The gate needs a signed release build installed on a phone and the standard regression set run. No Android build is possible on this machine, and the owner-blocked items are still open. See "Blockers".

## 1. Git

| Check | Result |
|---|---|
| Branch | `main` |
| Remote | `origin` = `github.com/mohdkasimqur/people-bridge` |
| Working tree at start | clean |
| History | `912d74b` → `13866b3` → `50b917e` → `ee0d33b`, linear |
| Local `HEAD` vs `origin/main` at start | both `ee0d33b` |

## 2. Analyze and test

| Command | At start (`ee0d33b`) | After this part |
|---|---|---|
| `flutter analyze` errors | 0 | 0 |
| `flutter analyze` warnings | 0 | 0 |
| `flutter analyze` infos | 125 | 114 |
| `flutter test` | 3 passed, 0 failed | 3 passed, 0 failed |

`flutter analyze` exits with code 1 because infos remain.

## 3. Broker privacy-policy check and `setState`

Confirmed: **no defect; nothing changed.** In `submitProfile()` the Privacy Policy and location errors are assigned without `setState`, but the method always calls `setState` earlier in the same synchronous run (the state/district/town check is unconditional), and there is no `await` before the `if (!valid) return`. The screen is therefore rebuilt and shows both messages.

It is fragile: it only works while an earlier `setState` exists. Recommended: wrap those assignments in `setState` when the screen is next changed.

No test added. The screen creates `FirebaseAuth` and Firestore objects when built, so it cannot be opened in a test without Firebase mocks, which would be a new dependency.

Also seen, not changed (open, owner to decide): the second mobile number is mandatory (must be 10 digits).

## 4. Analyzer infos

| Info | Count | Action |
|---|---|---|
| `unnecessary_underscores` | 10 | fixed with `dart fix` (`(_, __, ___)` → `(_, _, _)`), 5 files |
| `unnecessary_import` (`hive.dart` beside `hive_flutter.dart`) | 1 | fixed with `dart fix` |
| `deprecated_member_use`: `package:flutter/material.dart` | 104 | left: Flutter 3.50 asks for the new `material_ui` package; that is a project-wide migration and a new dependency |
| `deprecated_member_use`: localization delegates, `withOpacity`, `desiredAccuracy` | 9 | left: same migration, or small behaviour risk |
| `use_build_context_synchronously` (`screen_home.dart:2401`) | 1 | left: guarded by `mounted`; low risk |

## 5 and 6. Calls and removed packages

`git grep -i` over all tracked files except docs and the graph, for `screen_call`, `ScreenCall`, `webrtc`, `collection('calls')`, `VoiceCall`, `IncomingCall`, `firebase_messaging`, `flutter_background_service`, `flutter_overlay_window`, `google_places_flutter`, `permission_handler`: **0 matches**. This covers Dart code, `pubspec.yaml`, `pubspec.lock`, the Android manifest and the generated plugin registrants. No call icon remains in the chat folder. Phone-dialler buttons (`tel:` links) remain by design.

## 7. Android build configuration

| Item | Value |
|---|---|
| Gradle wrapper | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 |
| Java source/target | 17 |
| Application ID | `com.example.jober_india` (placeholder) |
| Release signing | debug key (placeholder) |

**Java requirement: JDK 17 or JDK 21.** Gradle 8.14 does not run on Java 25, and the Android Gradle Plugin needs at least 17.

State of this machine:
- The only JDK is Android Studio's bundled one, version 25.0.4. No JDK 17 or 21 is installed.
- Android SDK 36 is at `C:\Users\mohdk\AppData\Local\Android\sdk`; the command-line tools are missing and the SDK licences are not accepted.
- `android/local.properties` holds a Linux `sdk.dir` (file is not in git).

Nothing was changed. To build here, the owner would approve: install JDK 17 or 21 and point Flutter at it (`flutter config --jdk-dir=<path>`), install the SDK command-line tools, accept the licences. Upgrading the project to Gradle 9.1+ instead is not recommended without testing it against plugin 8.11.1.

## 8. iOS configuration (needs a Mac)

Found in the repo:
- Bundle ID `com.example.joberIndia` (placeholder); no development team set; deployment target iOS 13.0.
- No `ios/Podfile` and no `ios/Runner/GoogleService-Info.plist`. `lib/firebase_options.dart` does contain iOS options.
- `Info.plist` has **no permission texts** at all. The app uses location, camera, photos, microphone and speech recognition; iOS closes an app that requests these without the texts.

Needs macOS with Xcode:
1. `flutter build ios` to create the Podfile and install pods; raise the deployment target if the Firebase pods require it (to verify on the Mac).
2. Add the permission texts to `Info.plist`.
3. Set the final bundle ID, team and signing.
4. Phone OTP on iOS: add the Firebase URL scheme and push (APNs) setup, then test on a real iPhone.
5. Check the Google Maps iOS key and background location mode.

This is Phase 9 work; it is listed here only as findings.

## 9. Regression checklist

Executed here: only the automated checks.

| # | Check | Result |
|---|---|---|
| A1 | `flutter analyze`: 0 errors, 0 warnings | passed |
| A2 | Whole app compiles (`app_compiles_test.dart`) | passed |
| A3 | Subscription price calculation (`distance_plan_test.dart`, 2 tests) | passed |
| A4 | No call or removed-package reference left | passed |

Not run — need an Android phone and a debug build:

| # | Area | Steps | Expected |
|---|---|---|---|
| M1 | Start | Fresh install; then install over the old version | Both start without a crash |
| M2 | Authentication | Enter number, receive OTP, verify; wrong OTP; resend | Signed in; wrong OTP rejected |
| M3 | Customer flow | Open home, pick a category, see nearby partners, open a profile | Lists load; distance shown |
| M4 | Partner registration, mobile | Register one mobile partner (for example taxi) | Profile saved; visible in search |
| M5 | Partner registration, fixed | Register one fixed business (for example shop) | Profile saved; visible in search |
| M6 | Broker registration | Submit with Privacy Policy unticked, then ticked | Message shown when unticked; saved when ticked |
| M7 | LIVE | Turn LIVE on, check from a second phone, turn off | Partner appears, then disappears |
| M8 | Chat | Send text, photo and voice note between two accounts | Delivered; no call button in the chat bar |
| M9 | Hive persistence | Close and reopen the app; go offline and reopen | Still signed in; saved profile shown |
| M10 | Logout and login | Log out while LIVE; log in again | LIVE stopped, partner offline, local data cleared; profile kept after login |

## Blockers

| Blocker | Who |
|---|---|
| No Android build on this machine (JDK 17/21, SDK tools, licences) | owner approval to change the machine, or another machine |
| Manual regression M1–M10 not run | needs the build and a phone |
| Brand name, app IDs, release keystore | owner |
| Firebase rules and Firestore export; whether live data exists | owner |
| Crashlytics, release-log clean-up, check script | not started; next Phase 1 work |
| Cold-start time and app size baseline | needs the build |

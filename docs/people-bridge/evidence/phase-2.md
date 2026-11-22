# Phase 2 (New project skeleton and platform) — evidence

Machine: Windows 11 Pro, Flutter 3.50.0 (Dart 3.14.0), JDK 21.0.13+9. No Android device or emulator; no Mac.
Criteria: [06 §8 Phase 2](../06-fresh-rebuild-amendment.md). Phase 2 started on the owner's instruction on 2026-11-19.

## Owner decisions for Phase 2 (2026-11-19)

| ID | Decision | Status |
|---|---|---|
| Q1 | Tag `legacy-app-final` at `6b5ec4e`, verify recovery, then retire the old app from `main`; preserve translations, district data and the category list | OWNER APPROVED; done in Module 2.1 |
| O1 | D5 identifiers stay OPEN until before any Firebase app registration or store publication | OWNER APPROVED |
| O2 | Staging Firebase app registration deferred until the staging project exists (Phase 3); no staging project in Phase 2; production registration gated by D5 and owner approval | OWNER APPROVED |
| O3 | App Check stays gated; no API enabling; no silent move | OWNER APPROVED |
| O4 | No hardware purchase; Android real-device and iOS build/signing acceptance BLOCKED until hardware and signing access exist | OWNER APPROVED |

**Proposed amendments, NOT applied (owner confirmation needed):**

- **C (required by O2).** In 06 §8 Phase 2, replace "Final app IDs registered in the staging and production Firebase apps (production: register only; no data change)." with:
  > Final app IDs registered in the production Firebase project only, after D5 and explicit owner approval (no data change). Staging app registration moves to Phase 3, once the staging project exists (D3).

  Add to Phase 3's deliverables: "Staging app registration under the D5 IDs."
- **D (optional, for O3).** In 06 §8 Phase 2, replace "Crashlytics, App Check in monitor mode, …" with:
  > Crashlytics; App Check in monitor mode, only after explicit owner approval to enable the App Check API and register providers. If the Play and Apple accounts (B6) are not available at Phase 2 sign-off, the owner decides then whether it carries to Phase 3; …

## Module 2.1 — workspace skeleton (2026-11-19)

### Legacy protection

| Step | Command / check | Result |
|---|---|---|
| Preconditions | branch, HEAD, sync, clean tree, tag absent locally and on `origin` | `main` @ `6b5ec4e032f91fdb7a944b1a1991c7b06a30134a`, 0/0, clean, no tag |
| Tag | `git tag -a legacy-app-final 6b5ec4e…` | tag object `a35cfde…` → commit `6b5ec4e…` |
| Push (tag only) | `git push origin refs/tags/legacy-app-final` | `[new tag]`, exit 0 |
| Remote check | `git ls-remote --tags origin 'legacy-app-final*'` | `refs/tags/legacy-app-final^{}` = `6b5ec4e…` |
| Recovery | `git worktree add --detach <scratch> legacy-app-final` | HEAD `6b5ec4e…`; 148 Dart files in `lib/`; 23 ARB; district file present; 0 tracked files missing. Worktree removed afterwards |

### Preserved content

| Content | New path | Verification |
|---|---|---|
| 23 translation files | `apps/mobile/lib/l10n/*.arb` | SHA-256 23/23 identical to the originals and to `legacy-app-final` (not yet wired up; module 2.4) |
| District data | `packages/core/assets/data/india_districts.json` | SHA-256 `80b6c584…6900`, identical to the tag. **Development only; reuse rights OPEN; not declared as an asset, so not bundled** |
| Category list (22) | `packages/core/assets/data/categories.json` | Matches blueprint §2.3 [Confirmed] exactly (scripted comparison) |
| Not carried over | old images (WhatsApp images, vehicles, commercials) and per-category field lists | Recoverable from `legacy-app-final` |

### Changes

- **Removed from `main` (`git rm`, 327 tracked files):** `lib/`, `test/`, `assets/`, `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `pubspec.yaml` and `pubspec.lock` (old versions), `l10n.yaml`, `missing.json`, `.metadata`, `analysis_options.yaml` (old version), `firebase.json`.
  - The git-ignored generated leftovers of the old app in `android/`, `ios/` and `macos/` were deleted too; they became visible once their `.gitignore` files were removed. They included the Gradle wrapper, plugin registrants, `local.properties`, IDE files and Gradle cache.
- **Added:**
  - root `pubspec.yaml` (workspace: `apps/mobile`, `apps/admin`, `packages/core`), root `pubspec.lock` (single lockfile), root `analysis_options.yaml` (`flutter_lints` plus strict-casts, strict-inference and strict-raw-types; members include it);
  - `apps/mobile` (`app_mobile`; Android and iOS; `flutter create --empty`, placeholder org `com.example`);
  - `apps/admin` (`app_admin`; web);
  - `packages/core` (`app_core`): `LocaleController` (a `ValueNotifier<Locale>`) with an injected `LocaleStore` and `InMemoryLocaleStore`, plus 5 unit tests;
  - one smoke test per app;
  - `firebase/` (`firebase.json` with emulator configuration only and no project alias; deny-all `firestore.rules` and `storage.rules`; empty `firestore.indexes.json`).
- **Updated:** `README.md`; `CLAUDE.md`; 04 and 06 status lines; 06 approval record (Q1, O1–O4; C and D proposed).
- **Dependencies:**
  - `app_mobile`: `flutter`, `material_ui`, `app_core`;
  - `app_admin`: `flutter`, `material_ui`;
  - `app_core`: `flutter`;
  - dev: `flutter_test`, `flutter_lints`.
  - `material_ui` is the official Material library (publisher `flutter.dev`, repository `flutter/packages`), included by the Flutter 3.50 template.
  - No Firebase or state-management package (D9).

### Acceptance results

| # | Criterion | Command | Result |
|---|---|---|---|
| 1 | Tag and recovery | see above | **PASS** |
| 2 | Preserved files byte-identical | `sha256sum` against originals and tag | **PASS** (23/23 ARB; districts identical; 22 categories match) |
| 3 | Workspace resolves, single lockfile | `flutter pub get` at root | **PASS** (exit 0; only `pubspec.lock` at root) |
| 4 | Formatting | `dart format --output=none --set-exit-if-changed apps packages` | **PASS** (exit 0, 8 files, 0 changed) |
| 4 | Analysis | `flutter analyze` at root | **PASS** ("No issues found!", infos included) |
| 5 | Tests | `flutter test` in each member | **PASS** (core 5, mobile 1, admin 1) |
| 6 | Android debug build | `flutter build apk --debug` in `apps/mobile` (`JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true` for that run) | **PASS** (exit 0, 212 s, `app-debug.apk` 157,869,482 bytes) |
| 6 | Admin web build | `flutter build web` in `apps/admin` | **PASS** (exit 0, 116 s, `build/web` produced) |
| 7 | No Firebase or state-management packages; no Firebase commands | `grep` of pubspecs and `pubspec.lock` | **PASS** (0 matches; no Firebase command run) |
| 8 | Only planned changes; no secrets, keys or build output | `git status`, pattern scan | **PASS** |

### Not verified / blocked

- **iOS build:** BLOCKED (no Mac; O4).
- **Install and run on a real Android device:** BLOCKED (no device or emulator; O4).
- **App identifiers:** placeholders `com.example.app_mobile` (Android) and the iOS template default (D5 OPEN).
- **District data reuse rights:** OPEN.
- **Commit and push of Module 2.1:** done on the owner's authorisation: committed and pushed to `origin/main` as `053fed7af634611036efde3d722cae90516b1928`.

## Repository security review (2026-11-19, read-only)

Done before the Module 2.2 commit, on the owner's instruction. No GitHub setting, Firebase resource, credential or git history was changed.

### Findings

| Item | Result | Status |
|---|---|---|
| Visibility | **PUBLIC** (`gh api`: `visibility: public`). Public since creation on 2026-11-15 (repository event at 17:21 UTC, before the first push), so every pushed commit and the `legacy-app-final` tag have been public | CONFIRMED |
| Forks, stars, watchers | 0, 0, 0 | CONFIRMED |
| Traffic (14 days) | 14 clones by 11 unique cloners; 6 views by 1 unique visitor. Cloners not identifiable | CONFIRMED |
| GitHub secret scanning and push protection | both disabled | CONFIRMED |
| Firebase client configuration in history | added in `912d74b`, deleted in `053fed7`, still in history and the tag: `android/app/google-services.json` (project ID and number, storage bucket, Android app ID, package `com.example.jober_india`, 1 API key); `lib/firebase_options.dart` (Android, iOS, macOS, Windows-as-web options: API keys, app IDs, sender ID, auth domain, Analytics measurement ID); old root `firebase.json` (FlutterFire app IDs). 3 distinct `AIza…` API keys (Android, Apple, web). No `GoogleService-Info.plist` | CONFIRMED |
| Genuine secrets in history | every blob of all 12 commits on `main`, `origin/main` and `legacy-app-final` scanned for private keys, service-account JSON, signing keystores and passwords, GitHub, Google OAuth, AWS, Slack, OpenAI-style and Anthropic tokens, `.env` and credential files, OAuth client IDs, password or token assignments: **none found**. Phone-number matches were all false positives (project number, Xcode IDs, lockfile hash, image bytes) | CONFIRMED |
| Personal data | the owner's commit e-mail address is public in commit metadata | CONFIRMED |

Firebase client configuration identifies the project and ships inside every app; it is not a secret. Protection comes from security rules, App Check and API-key restrictions. No history rewrite is needed: it would not remove existing copies, and there is no genuine secret to remove. Key rotation is optional; the retired apps' keys can be deleted or restricted when the D5 apps are registered.

**Owner decision (2026-11-19):** keep the repository **public**. `CLAUDE.md` and 04 were corrected to match, and the CI-cost cell in 08 §5 was corrected (GitHub-hosted standard runners are free in public repositories). Historical records that describe the repository as private were left unchanged and are inaccurate on that point: `evidence/phase-1-closing-report.md` (Phase 1 table), 05 §1 (Git row) and 06 (Phase 1 history row).

### Outstanding before Phase 3 (Firebase console checks, owner approval needed; NOT VERIFIED)

1. **API-key restrictions:** restrict the 3 keys by application (Android package plus signing fingerprint, iOS bundle ID, allowed websites for the web key) and by API (only the Firebase APIs the app needs). Part of the deferred P2a checks (06 amendment B).
2. **Auth abuse exposure:** check which sign-in providers are enabled, the billing plan, and the SMS region policy (India only). With a public key, an enabled Phone provider on the Blaze plan is open to paid-SMS abuse.

## Module 2.2 — CI (2026-11-19)

Workflow `.github/workflows/ci.yml`, committed and pushed on the owner's authorisation as `e1f7256bb33342c1c9db61982b52c0abfce276f5` (parent `d7b5a61`). Triggers: pull requests and pushes to `main`, and manual dispatch. One job on `ubuntu-24.04`, 30-minute timeout, `permissions: contents: read`, no secrets, checkout without persisted credentials. Actions pinned to full commit SHAs: `actions/checkout` v7.0.1 (`3d3c42e…`), `actions/setup-java` v6.2.0 (`77dd5b2…`, Temurin 21, Gradle cache), `subosito/flutter-action` v2.23.0 (`1a44944…`, stable 3.50.0, cache on).

### Local verification before commit (Windows)

YAML parsed with Dart `yaml` 3.1.4 (offline): 3 triggers, 12 steps. Every workflow command was run locally and exited 0: revision `ab2912035e…`, `flutter pub get --enforce-lockfile` (lockfile unchanged), format (8 files, 0 changed), `flutter analyze --fatal-infos --fatal-warnings` (no issues), tests (core 5, mobile 1, admin 1), `flutter build apk --debug` (50 s, local IPv4 workaround only), `flutter build web` (81 s).

### GitHub Actions runs

| Run | Event / ref / commit | Result | Duration |
|---|---|---|---|
| [44577261801](https://github.com/mohdkasimqur/people-bridge/actions/runs/44577261801) | `push`, `main`, `e1f7256` | **success**: all 12 steps passed; revision `ab2912035e`; format 8 files, 0 changed; "No issues found!"; tests core 5, mobile 1, admin 1; APK and web built; no annotations | job 5 min 26 s (17:26:53–17:32:19 UTC); run 5 min 30 s (17:26:50–17:32:20 UTC); cold caches (Flutter, pub, Gradle and Gradle-wrapper caches not found). Steps: Flutter setup 51 s, analyze 7 s, tests 8 + 10 + 10 s, APK 2 min 39 s, web 35 s |
| [44578452460](https://github.com/mohdkasimqur/people-bridge/actions/runs/44578452460) | `workflow_dispatch`, temporary branch `ci-deliberate-failure-test`, `b62a836` (one deliberately unformatted file added) | **failure, as intended**: "Check formatting" failed (`Changed packages/core/lib/ci_failure_probe.dart`, exit code 1); analyze, tests and builds skipped | job 44 s (17:33:31–17:34:15 UTC); run 48 s (17:33:27–17:34:15 UTC) |
| [44579241665](https://github.com/mohdkasimqur/people-bridge/actions/runs/44579241665) | `push`, `main`, `65a5b85ad11a0ea30ae575dc2888556200fdca93` (evidence commit) | **success**: all 12 steps passed | job 3 min 16 s (17:37:54–17:41:10 UTC); run 3 min 20 s (17:37:51–17:41:11 UTC); caches reused (see below) |

Durations come from GitHub's timestamps: "job" is the job's start to completion, and "run" is the run's creation to its last update.

The push of the temporary branch triggered no run (as designed: push runs only on `main`); the test used manual dispatch, so no pull request was opened. The branch was never merged (`b62a836` is not an ancestor of `main`), then deleted from `origin` and locally; `origin` now has only `main` at `e1f7256`. Commit `b62a836` may stay reachable on GitHub by its SHA through the run record; it contains only the unformatted test function.

### Cache verification

Run 44579241665 restored every cache that run 44577261801 had saved. The log shows a "Cache hit" and "Cache restored from key" for the Flutter SDK, pub and Gradle keys, and a cache hit on the Gradle wrapper. No new caches were saved ("not saving cache").

| Measure (cold run 44577261801 → cached run 44579241665) | Before | After |
|---|---|---|
| Job (start → completion) | 5 min 26 s | 3 min 16 s |
| Run (creation → last update) | 5 min 30 s | 3 min 20 s |
| Flutter setup step | 51 s (17:27:03–17:27:54) | 27 s (17:38:27–17:38:54) |
| Build Android debug APK step | 2 min 39 s (17:28:32–17:31:11) | 63 s (17:39:30–17:40:33) |

These are two single runs on GitHub-hosted runners, not an average.

### Not verified

- **Pull-request trigger: NOT VERIFIED** (not exercised; no pull request opened).

## Module 2.3 — localization (2026-11-20)

Scope approved by the owner on 2026-11-20: connect the 23 preserved ARB files to `apps/mobile`. Owner decisions: (1) `flutter_localizations` and `intl` become direct mobile dependencies, later also `cupertino_ui` (approved after implementation showed it was needed, see below); (2) Flutter's own widget text falls back to English where the framework has no translation, while the app's text stays in the selected language; (3) the admin app stays English-only.

### Changes (local; not committed)

- `apps/mobile/pubspec.yaml`: direct dependencies `cupertino_ui: ^1.0.0`, `flutter_localizations` (SDK) and `intl: ^0.20.2`; `generate: true`. All three were already in `pubspec.lock` as dependencies of `material_ui` (`cupertino_ui` 1.1.7 and `intl` 0.20.3; `material_ui` and `cupertino_ui` published by `flutter.dev`), so **`pubspec.lock` is unchanged** and nothing new is downloaded.
- `apps/mobile/l10n.yaml` (new): ARB directory `lib/l10n`, template `app_en.arb`, non-nullable getter, formatted output.
- `apps/mobile/lib/l10n/localizations.dart` (new): the delegate list (app, `material_ui` Material, `cupertino_ui` Cupertino, Flutter widgets, then English fallbacks), and the supported-locale list with English first so that an unsupported language resolves to English rather than to the first language alphabetically.
- `apps/mobile/lib/main.dart`: `MaterialApp` uses that delegate list and locale list.
- `apps/mobile/analysis_options.yaml`: excludes the generated `lib/l10n/app_localizations*.dart` (its unused `localizationsDelegates` constant names `flutter_localizations` delegates that Flutter 3.50 deprecates).
- `apps/mobile/.gitignore`: ignores the generated files.
- `apps/mobile/test/localization_test.dart` (new): 27 tests.
- The 23 ARB files are unchanged; no key or translation was corrected, renamed or removed.

### Why `cupertino_ui` was needed

`material_ui`'s `MaterialApp` always adds `cupertino_ui`'s default Cupertino delegate, which supports English only (`isSupported`: `languageCode == 'en'`). Without `cupertino_ui`'s `GlobalCupertinoLocalizations`, every non-English locale raised "This application's locale, … is not supported by all of its localization delegates" (22 locale tests and the runtime-switch test failed). The deprecated `flutter/cupertino` delegate is a different type and does not fix it.

### Translation coverage (what is and is not translated)

| Layer | Languages translated | Fallback |
|---|---|---|
| App text (the 120 ARB messages) | all 23 | none needed (untranslated-messages report `{}`) |
| Material widget text (`material_ui` 1.11.1) | 14: as, bn, en, gu, hi, kn, ml, mr, ne, or, pa, ta, te, ur | **English** for brx, doi, kok, ks, mai, mni, sa, sat, sd |
| Cupertino widget text (`cupertino_ui` 1.1.7) | the same 14 | **English** for the same 9 |
| Widget text and text direction (`flutter_localizations`) | the same 14 | English for the same 9; **right to left kept for Kashmiri and Sindhi** (and Urdu through Flutter) |

Flutter's own widget text is therefore **not** available in all 23 languages: for 9 languages it is English.

### Code generation

- Flutter 3.50's `flutter pub get` runs the localization generator for every workspace package with `generate: true` (`flutter_tools/lib/src/commands/packages.dart`, `GenerateLocalizationsTarget`). The generated files are not committed.
- **Clean-checkout test:** fresh clone of `cc74ac4` with these changes applied (tree identical to the working copy apart from git-ignored files). Before `flutter pub get --enforce-lockfile`: 0 generated files. After: 24 (exit 0), none shown by `git status`, lockfile unchanged. Then, in the clone: format exit 0 (34 files, 0 changed); `flutter analyze --fatal-infos --fatal-warnings` "No issues found!"; tests core 5, mobile 28, admin 1, all passed. CI's existing first step therefore generates the code before analysis, tests and builds; **no CI change was needed**.
- One-off generator run with an untranslated-messages report (option added to `l10n.yaml` for that run only, then removed): report `{}`.

### Verification (Windows, Flutter 3.50.0, revision `ab2912035e…`)

| Check | Result |
|---|---|
| `flutter pub get --enforce-lockfile` | exit 0; lockfile unchanged |
| `dart format --output=none --set-exit-if-changed apps packages` | exit 0 (34 files, 0 changed) |
| `flutter analyze --fatal-infos --fatal-warnings` | "No issues found!" |
| `flutter test` core / mobile / admin | 5 / 28 / 1 passed |
| Mobile tests in detail | the app's languages equal the 23 ARB `@@locale` values; exactly the 9 expected languages need the fallback; for each of the 23 languages the app starts with no exception or delegate warning, resolves to that language, shows `logout` and `home` exactly as in its ARB file, shows the Material and Cupertino text of that library's own translation (English for the 9), and has the expected text direction (RTL for ur, ks, sd); runtime switch English → Santali; French falls back to English; existing smoke test |
| `flutter build apk --debug` (local IPv4 workaround) | exit 0, 51 s; 182,563,668 bytes (Module 2.1: 157,869,482; **+24,694,186 bytes**) |
| `flutter build web` (admin) | exit 0, 69 s |
| ARB byte identity | SHA-256 23/23 identical to the baseline taken before any change (which matched `HEAD` and `legacy-app-final:lib/l10n`); also re-checked 23/23 against `legacy-app-final` |

**Correction (2026-11-22, Module 2.4):** the debug APK measured above (182,563,668 bytes, "+24,694,186") contained 24,457,163 bytes of unreferenced data (no APK entry points to them). It was built in the main workspace on top of earlier builds; that the bytes are stale data left by an earlier build is a hypothesis, not a proven cause. Fresh builds of `cc74ac4` and `2f6bc51` with identical commands differ by **+244,244 bytes**. The original figures are kept as recorded; see "Module 2.4 — release build and app-size baseline" below for the fresh-build comparison.

### Limitations and not verified

- **Flutter widget text is English for 9 languages** (brx, doi, kok, ks, mai, mni, sa, sat, sd), as decided by the owner.
- **GitHub Actions run:** not run (needs a push).
- **Real devices:** BLOCKED (O4). Santali uses the Ol Chiki script; whether phones render it, and how right-to-left screens look, is unverified. Widget tests do not render glyphs.
- **Release APK size:** not measured; the debug size grew by about 24.7 MB. *(Corrected in Module 2.4: the APK held 24,457,163 unreferenced bytes; the fresh-build increase is 244,244 bytes.)*
- **Translation quality and provenance:** not reviewed. Some messages belong to old features (for example the "display over other apps" permission text).
- **Not included:** language picker screen; saving the chosen language across restarts (the store is still in memory); bundled fonts; iOS `CFBundleLocalizations` in `Info.plist` (no Mac); admin localization.

## Module 2.4 — release build and app-size baseline (2026-11-22)

Measurement only, approved by the owner on 2026-11-22. No application code, dependency, signing, CI, Firebase or app-ID change. Release builds use the Flutter template's debug signing (`signingConfig = signingConfigs.getByName("debug")`, unchanged); they were for local measurement only and were never distributed, uploaded or committed. No signing key was created.

### Method

- Environment: Windows 11 Pro; Flutter 3.50.0 (framework `ab2912035e…`, engine `bf601093ad…`), Dart 3.14.0; Temurin JDK 21.0.13; Gradle 9.5.0; Android Gradle Plugin 9.3.1; Kotlin 2.4.20; `JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true` for every build.
- Two temporary detached worktrees outside the repository: `a` at `cc74ac4` (before Module 2.3) and `b` at `2f6bc51` (Module 2.3). In each, `flutter pub get --enforce-lockfile` (lockfile unchanged), then the same commands in `apps/mobile`:
  - `flutter build apk --debug`
  - `flutter build apk --release --split-per-abi`
  - `flutter build apk --release --analyze-size --target-platform android-<arm|arm64|x64> --code-size-directory=build/size-android-<…>` (all three in `b`; arm64 in `a`)
  - `flutter build appbundle --release`
- APK and AAB contents read from the ZIP central directory; unreferenced bytes = file size minus local headers, entry data, central directory and end record. The worktrees and their build outputs were deleted afterwards.

### Finding: fresh builds do not reproduce the "+24.7 MB" debug APK increase (Module 2.3)

| Debug APK | Size (bytes) | Unreferenced bytes |
|---|---|---|
| `cc74ac4`, fresh worktree | 157,869,518 | 4,096 |
| `2f6bc51`, fresh worktree | 158,113,762 | 4,096 |
| Module 2.3 measurement (main workspace, built over earlier builds) | 182,563,668 | **24,457,163** |

- **Confirmed:** built the same way, Module 2.3 adds **244,244 bytes** to the debug APK. The only changed entry is `assets/flutter_assets/kernel_blob.bin` (compressed 24,453,039 → 24,697,283; uncompressed 74,549,952 → 75,242,856). The Module 2.3 APK has the same 147 entries but carries 24,457,163 bytes that no entry references.
- **Confirmed:** the Module 2.3 figure of "+24,694,186 bytes" does not reflect app growth. The fresh-build increase is 244,244 bytes, and the Module 2.3 APK holds 24,457,163 unreferenced bytes. The Module 2.3 section keeps its original figures with a correction note pointing here.
- **Hypothesis (cause not proven):** incremental APK packaging in the main workspace may have left the previous build's `kernel_blob.bin` data in the file as dead space. Supporting but not conclusive: the unreferenced 24,457,163 bytes are close to that entry's compressed size at `cc74ac4` (24,453,039). The packaging behaviour was not examined.

### Release APKs (per architecture, debug-key signed, local only)

| Architecture | `cc74ac4` (bytes) | `2f6bc51` (bytes) | Change |
|---|---|---|---|
| armeabi-v7a | 12,172,985 | 12,369,593 | +196,608 |
| arm64-v8a | 14,716,865 | 14,913,473 | +196,608 |
| x86_64 | 15,903,131 | 16,099,739 | +196,608 |

- **Confirmed:** in every architecture the only changed entry is `lib/<abi>/libapp.so` (compiled Dart, stored uncompressed): arm64 2,950,104 → 3,146,712 bytes. `libflutter.so` is byte-identical. The `--analyze-size` builds produced APKs within 4 bytes of these.
- **Largest contributors (arm64, 2f6bc51, confirmed):** `libflutter.so` (Flutter engine) is about 11.3 MB uncompressed; Dart code `libapp.so` 3.1 MB, of which `package:flutter` 973 KB, `package:material_ui` 270 KB, `dart:core` 246 KB, `dart:ui` 177 KB, `dart:typed_data` 180 KB; `classes.dex` 235 KB; `flutter_assets` 112 KB (Material icons font tree-shaken).

### Localization contribution (arm64 release, `cc74ac4` → `2f6bc51`, from the size-analysis JSON)

**Measured total:** `libapp.so` grows by 196,608 bytes (2,950,104 → 3,146,712). The size-analysis tree covers 167,136 bytes of that growth (2,890,112 → 3,057,248), split as follows.

**A. Attributed to named packages (measured): +126,287 bytes**

| Package | Change (bytes) | Notes |
|---|---|---|
| `package:intl` | +38,241 | new in the binary |
| `package:flutter_localizations` | +26,014 | date (8,714) and widget (6,855) localizations; **its deprecated Material and Cupertino tables are not in the binary** (removed by tree shaking) |
| `package:material_ui` | +22,113 | `generated_material_localizations.dart` 17,344 |
| `package:cupertino_ui` | +20,982 | `generated_cupertino_localizations.dart` 17,325 |
| `package:app_mobile` | +11,353 | includes generated `l10n` 10,387 |
| Subtotal, the five localization-related packages | **+118,703** | |
| Other named libraries | +7,584 | mostly `package:flutter` +3,084, `dart:core` +1,777, `dart:_compact_hash` +1,078 |

**B. Unattributed (measured, but not assigned to any package by the tool): +70,321 bytes**

| Bucket | Change (bytes) |
|---|---|
| `@shared` | +27,978 |
| `@unknown` | +11,661 |
| `@stubs` | +1,210 |
| Outside the analysis tree (196,608 − 167,136) | +29,472 |

- **Confirmed:** Module 2.3 adds 196,608 bytes (192 KiB) per architecture to the release APK, all in compiled Dart code; 118,703 bytes of it are attributed to the five localization-related packages.
- **Hypothesis:** the 23 × 120 translated strings account for much of the unattributed amount; the tool does not name them.

### Release App Bundle (all architectures, debug-key signed, local only)

- `cc74ac4` 43,227,187 bytes → `2f6bc51` 43,589,107 bytes (**+361,920**). `base/lib/<abi>/libapp.so` grows as in the APKs.
- About 21 MB of the bundle is `BUNDLE-METADATA/…/debugsymbols/*.sym` (native debug symbols kept by Google Play, not delivered to phones).

### Limitations

- Download and install size per device from the bundle was not measured: it needs `bundletool`, which is not installed (installing needs owner approval).
- No phone (O4): cold start, install and on-device size not measured.
- Release builds are signed with the template debug key; real signing is not configured (Phase 2 release-signing deliverable still open).
- Single builds on one machine; no repeat runs.

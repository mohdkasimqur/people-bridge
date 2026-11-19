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

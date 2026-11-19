# People Bridge

Working name, provisional. A Flutter app for India connecting customers with service partners, plus a separate Super Admin web dashboard.

## Repository layout (Dart pub workspace)

| Path | Package | Purpose |
|---|---|---|
| `apps/mobile` | `app_mobile` | Android and iOS app |
| `apps/admin` | `app_admin` | Super Admin web app |
| `packages/core` | `app_core` | Shared models and services |
| `firebase/` | — | Local emulator config and deny-all rules; never deployed from Phase 2 |
| `docs/people-bridge/` | — | Requirements, roadmap, decisions and evidence |

App IDs are still Flutter's `com.example.*` placeholders (decision D5 is open). `packages/core/assets/data/india_districts.json` is for development only: its reuse rights are unverified, and it is not bundled into any app.

The old app is retired from `main`. It stays recoverable from the tag `legacy-app-final`:

```
git worktree add <folder> legacy-app-final
```

## Common commands (from the repository root)

```
flutter pub get
dart format --output=none --set-exit-if-changed apps packages
flutter analyze
```

Run `flutter test` inside each of `packages/core`, `apps/mobile` and `apps/admin`.

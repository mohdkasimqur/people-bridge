> Preserved verbatim from the planning session of 2026-11-14. Do not edit; corrections go in 03-master-blueprint.md.

# People Bridge — Read-Only Audit Report

Nothing was created, edited, run or deployed. Findings come from reading the code and config in `D:\MyWork\jober_india`. Each finding is tagged **Confirmed**, **Possible** or **Unknown**.

## 1. Executive summary

The Android app has broad feature coverage (23 provider modules, OTP login, LIVE location, chat, calls, 23 languages), but it is not ready for either store and not ready for India-wide load.

- **iOS cannot run.** Firebase is initialised only on Android, and the iOS project has no Firebase plist, no Podfile and no permission strings.
- **Android cannot be published.** The app ID is `com.example.jober_india` and release builds are signed with the debug key.
- **Security rules are not in the repo.** The client code only works if rules are permissive, so this is the largest unverified risk.
- **Discovery downloads whole collections.** There are no geo queries; every user reads nationwide data and filters on the phone. This is the main cost and scale problem.
- **Logout deletes the provider's profile** and runs the cleanup after navigating away, with timeouts, so partial deletes are likely.
- **Subscription is local-only.** Plan state lives in Hive and no payment gateway is connected.
- **Maintainability is poor.** About 310,000 lines in 125 files, roughly 47% commented-out code, 33 files over 3,000 lines, no git, no real tests.

Firebase should stay. The problems are in how it is used, not in the choice of backend.

## 2. Project structure and technology inventory

| Item | Actual state |
|---|---|
| Flutter / Dart | Dart SDK `^3.11.5`; lockfile requires Flutter ≥ 3.44, Dart ≥ 3.12 |
| Firebase project | `citizen-india`; Auth (phone OTP), Firestore, Storage in use |
| Declared but unused packages | `firebase_messaging`, `flutter_background_service`, `flutter_overlay_window`, `google_places_flutter`, `permission_handler` (0 imports each); `geoflutterfire_plus` imported once, its query API never called |
| Background work | `flutter_foreground_task` (location service), `overlay_pop_up` (floating bubble) |
| Maps | `flutter_map` with OpenStreetMap tiles (5 files), `google_maps_flutter` (1 file) |
| Local storage | Hive (17 box names), SharedPreferences |
| State management | `setState` only (1,657 calls); no Provider/Bloc/Riverpod |
| Routing | Imperative `Navigator.push`; no named routes |
| Backend code | None. No Cloud Functions, no `firestore.rules`, `storage.rules` or `firestore.indexes.json` |
| Repo hygiene | No `.git`, no CI, default README, `lib/build/` artefact inside `lib` |
| Naming | Three brand names in code: "People Bridge", "Citizen India", "Jober India" |

Layout: [main.dart](lib/main.dart), shared services under `lib/jober_indiaScreens.dart/` (a folder, despite the name), one subfolder per category, and older screens under `lib/screens/`.

## 3. Architecture and data flow

1. [main.dart](lib/main.dart) initialises Firebase (Android only), the foreground task, Hive boxes and prefs.
2. [screen_splash.dart](lib/screens/splash/screen_splash.dart) asks for location, then routes on `FirebaseAuth.currentUser` to Home or Choose Role.
3. Each category has its own `*_login.dart` (24 files call `verifyPhoneNumber`), which writes `collection/{uid}` and copies fields into Hive.
4. [screen_home.dart](lib/jober_indiaScreens.dart/screen_home.dart) (13,255 lines) holds search, counts, subscription, LIVE toggle and all logout cleanup.
5. LIVE runs in a foreground service that writes `liveLocations/{uid}` every 20 seconds.
6. Seekers open `*_nearby.dart` screens that fetch documents and compute distance on the device.

There is no service or repository layer apart from [common_profile_services.dart](lib/jober_indiaScreens.dart/common_profile_services.dart) and a small chat repository. Each module re-implements auth, upload, permissions and queries.

## 4. Firebase and Firestore audit

About 48 top-level collections: one per provider type, one or two category collections per type, plus `liveLocations`, `conversations/messages`, `calls`, `rideRequests`, `users`.

| # | Priority | Finding | Evidence | Status |
|---|---|---|---|---|
| F1 | Critical | Security rules, Storage rules and indexes are not version-controlled and could not be inspected | No rules files in the project; `firebase.json` has only FlutterFire config | Unknown |
| F2 | Critical | Client behaviour implies permissive rules: users delete shared category docs and rewrite shared owner arrays | `cleanupOtherBusinessOnLogout`, `cleanupTeaShopOnLogout` in [screen_home.dart:5496](lib/jober_indiaScreens.dart/screen_home.dart:5496), [:7630](lib/jober_indiaScreens.dart/screen_home.dart:7630) | Possible |
| F3 | High | Whole-collection reads and listeners with no filter or limit | `clinics`, `medicalShops`, `rentals`, `tea_shops`, `doctors`, `companies`, `selfEmployees`, `auto_spare_parts_shops`, `fishDeliveryGuys`, `workers`, `taxi_commercial` | Confirmed |
| F4 | High | Home screen opens 13 live listeners at once; the More screen adds about 8 more | [screen_home.dart:3352](lib/jober_indiaScreens.dart/screen_home.dart:3352), `screen_more.dart` | Confirmed |
| F5 | High | `liveLocations where isLive == true` is fetched nationwide, then filtered on device | `screen_workers_nearby.dart:676`, `recovery_drivers.dart`, `screen_comrcil_drvrs.dart`, `screen_searchcab.dart`, `fish_delivery_nearby.dart` | Confirmed |
| F6 | Medium | The `workers` query combines `arrayContains` with a latitude range, which needs a composite index | `screen_workers_nearby.dart:576` | Unknown whether the index exists |
| F7 | Medium | Role strings are inconsistent (`doctors`/`doctor`, `medicalShop`, `autoSpareParts`, `tea_shop`); logout compensates with multi-alias switches | [screen_home.dart:5165](lib/jober_indiaScreens.dart/screen_home.dart:5165) | Confirmed |
| F8 | Low | Only 22 `.limit()` calls; real pagination exists in chat only | [chat_message_reposistory.dart](lib/jober_indiaScreens.dart/Message/chat_message_reposistory.dart) | Confirmed |

Direction: put rules and indexes in the repo first, then replace whole-collection reads with geohash-bounded queries and aggregate counts. Testing needs the Firebase emulator with rules tests.

## 5. Hive and local storage audit

| # | Priority | Finding | Evidence | Status |
|---|---|---|---|---|
| H1 | High | **Tea Shop cleanup targets the wrong box.** Registration writes `teaShop*` keys to box `settings`; logout deletes them from `appSettings`. `teaShopRegistered` survives logout | `screen_tea_shop_login.dart:3910, 5699` vs [screen_home.dart:7843](lib/jober_indiaScreens.dart/screen_home.dart:7843) | Confirmed |
| H2 | Medium | Two near-identical boxes, `settings` and `appSettings`, hold overlapping data; logout reads role from `userBox` then `appSettings` | [screen_home.dart:4646](lib/jober_indiaScreens.dart/screen_home.dart:4646) | Confirmed |
| H3 | Medium | Box naming is inconsistent: `medical_shop_local`, `grocery`, `garageProfiles`, `labProfiles`, `appBox`, `workerBox` | [main.dart:209](lib/main.dart:209) | Confirmed |
| H4 | Medium | Six boxes are opened lazily rather than in `main` (`appSettings`, `rentalProfiles`, `labProfiles`, `foodDeliveryProfiles`, `fishDeliveryProfiles`, `selfBusinessProfiles`). The sites I read are guarded with `isBoxOpen`; not every site was checked | `screen_laboratory_login.dart:5353` | Possible |
| H5 | Medium | `userBox` is never cleared as a whole; cleanup deletes selected keys per role | [screen_home.dart:6130](lib/jober_indiaScreens.dart/screen_home.dart:6130) onward | Confirmed |
| H6 | Low | `isLoggedIn` pref is set to true and never set back to false. It is read at startup but not used for routing | [common_profile_services.dart](lib/jober_indiaScreens.dart/common_profile_services.dart), [main.dart:230](lib/main.dart:230) | Confirmed |
| H7 | Low | Two typed adapters (`OwnerData`, `WorkerData`) exist with no versioning or migration; everything else is untyped maps | [owner_data.dart](lib/owner_data.dart), [worker_data.dart](lib/worker_data.dart) | Confirmed |

Hive is appropriate as a cache. The problem is that it is also treated as the source of truth for registration state and subscription.

## 6. Authentication, registration and provider roles

| # | Priority | Finding | Evidence | Status |
|---|---|---|---|---|
| A1 | High | **No account deletion.** No call to `user.delete()` anywhere. Both stores require in-app account deletion | Search across `lib` | Confirmed |
| A2 | High | **Logout deletes the Firestore profile.** I read the Tea Shop and Other Business cleanups in full; about 20 more `cleanup*OnLogout` functions follow the same naming and were not all read | [screen_home.dart:4638](lib/jober_indiaScreens.dart/screen_home.dart:4638) | Confirmed for two roles, Possible for the rest |
| A3 | High | Logout navigates away first, then runs cleanup in a detached future with 5–20 second timeouts, then signs out. A timeout does not cancel the work, so deletes can continue after sign-out and fail half-way | [screen_home.dart:4684](lib/jober_indiaScreens.dart/screen_home.dart:4684), [:5238](lib/jober_indiaScreens.dart/screen_home.dart:5238) | Confirmed design, Possible data loss |
| A4 | Medium | OTP flow is duplicated in 24 files; no shared auth service and no `authStateChanges` listener | 24 × `verifyPhoneNumber` | Confirmed |
| A5 | Medium | One phone number gives one UID, but a UID can own documents in several provider collections, while `liveLocations/{uid}` and `userBox.role` hold a single role | [location_backgrnd_servce.dart:1186](lib/jober_indiaScreens.dart/location_backgrnd_servce.dart:1186) | Possible |
| A6 | Medium | Every re-login after logout needs a new OTP and a full re-registration; SMS is a paid resource | Follows from A2 | Confirmed |

## 7. Category ownership and synchronisation

- **Other Business** (Medium, Confirmed): after deleting the profile, logout deletes a custom category if no other business uses it. This is a read-then-delete outside a transaction, so two concurrent actions can delete a category another user just adopted. Evidence: [screen_home.dart:5531](lib/jober_indiaScreens.dart/screen_home.dart:5531).
- **Tea Shop** (Medium, Confirmed): cleanup reads the entire `tea_shops` collection to decide which categories are still used ([screen_home.dart:7723](lib/jober_indiaScreens.dart/screen_home.dart:7723)). Cost grows with every shop, and it runs inside a 15-second timeout.
- **Ownership arrays** (Medium, Confirmed): category docs carry `teaShopUids`, `workerUids`, `companyUids`, `clinicUids`. Arrays in one document will hit the 1 MB document limit for popular categories at national scale.
- **Counts versus lists** (Medium, Confirmed): Other Business counts come from a listener on all active businesses, computed on device ([other_business_categories.dart:404](lib/jober_indiaScreens.dart/otherBusiness/other_business_categories.dart:404)).

Direction: move category bookkeeping server-side (a small Cloud Function or transactional counters) so that logout does not have to do it.

## 8. LIVE status and location

| # | Priority | Finding | Evidence | Status |
|---|---|---|---|---|
| L1 | High | Two readers never check `expiresAt`, so a driver whose app was killed stays visible indefinitely | `screen_comrcil_drvrs.dart`, `screen_searchcab.dart` (zero `expiresAt` references) | Confirmed |
| L2 | High | The service's `onDestroy` does not mark the provider offline | [location_backgrnd_servce.dart:1377](lib/jober_indiaScreens.dart/location_backgrnd_servce.dart:1377) | Confirmed |
| L3 | High | `isOnline` on profile documents has no heartbeat or expiry. Home badge counts query `isOnline == true`, so killed or uninstalled apps inflate counts | [screen_home.dart:3535](lib/jober_indiaScreens.dart/screen_home.dart:3535) | Confirmed |
| L4 | Medium | A 20-second heartbeat means 180 writes per provider per hour, moving or not | [location_backgrnd_servce.dart:1280](lib/jober_indiaScreens.dart/location_backgrnd_servce.dart:1280), `:1502` | Confirmed |
| L5 | Medium | If LIVE OFF cannot reach Firestore, the error is swallowed and local state becomes OFF while the cloud stays `isLive: true` until expiry | `stop()` and `markOffline()` at `:2011`, `:2087` | Confirmed |
| L6 | Medium | `Geolocator.requestPermission` is called in 46 files plus the splash dialog; there is no single permission service | Search across `lib` | Confirmed |
| L7 | Medium | LIVE requires "display over other apps" permission before it will start | [screen_home.dart:1055](lib/jober_indiaScreens.dart/screen_home.dart:1055) | Confirmed |
| L8 | Low | Four stream subscription fields in Home are cancelled but never assigned | [screen_home.dart:801](lib/jober_indiaScreens.dart/screen_home.dart:801), `:886` | Confirmed |

Rental "online" counts: the rental category screen counts `isActive && isRegistered`, while the nearby list applies neither filter ([screen_rentals_nearby.dart:109](lib/jober_indiaScreens.dart/rentals/screen_rentals_nearby.dart:109)). Counts and lists can disagree. **Confirmed.**

## 9. Nearby discovery and subscription

- **No server-side geo filtering** (High, Confirmed). Workers use a latitude range plus on-device longitude filter. Rentals, fish delivery, commercial drivers and others fetch everything and compute distance locally. A `geohash` is written to `liveLocations` but never queried.
- **N+1 reads** (Medium, Confirmed). Workers nearby fetches each matching worker's profile individually (`screen_workers_nearby.dart:796`).
- **Radius rules differ by module** (Medium, Confirmed). Home defaults `paidDistance` to 5 km and resets to 1 km on expiry; rentals use 1 km free and a 50 km cap; ambulances use a fixed 50 km.
- **Subscription is local and unverified** (High, Confirmed). Plan, expiry and amount are stored only in Hive `settings` ([screen_home.dart:2292](lib/jober_indiaScreens.dart/screen_home.dart:2292)). Expiry is checked against the device clock. Reinstalling loses a paid plan; changing the clock extends one.
- **No payment gateway** (High, Confirmed). `startSubscriptionPayment` only shows a snackbar ([screen_home.dart:1685](lib/jober_indiaScreens.dart/screen_home.dart:1685)). Whether any UI path reaches `activateSubscription` without payment was not traced.

## 10. Security and privacy

| Priority | Finding | Status |
|---|---|---|
| Critical | Rules unknown (F1, F2). Provider documents contain mobile numbers (112 field writes in 35 files) and exact coordinates, and clients read whole collections | Unknown / Possible |
| High | Privacy policy, terms and website URLs are empty strings in `Privacy&Terms/web_liknks.dart`, while registration asks users to accept a policy | Confirmed |
| High | No App Check, so the Firestore API is callable by any client holding the public config | Confirmed absent in code |
| Medium | Uploaded photos and chat media are never deleted from Storage when profiles are deleted | Confirmed (no Storage delete calls) |
| Medium | Calls use STUN only, no TURN server (`screen_call.dart:89`). Calls will fail on many mobile carrier networks | Confirmed config, Possible impact |
| Low | Firebase API keys in `firebase_options.dart` are normal for client apps; they need restriction in the Google Cloud console | Unknown whether restricted |

No hard-coded secrets, test OTPs or server keys were found.

## 11. Performance and scalability

- Read cost scales with total providers × app opens, not with what the user sees (F3–F5). This is acceptable for a pilot town and unaffordable nationally.
- 892 `debugPrint`/`print` calls, including coordinates and UIDs.
- No Crashlytics or analytics, so production failures will be invisible.
- No Firestore cache configuration; defaults apply.
- Single-`State` screens of 5,000–13,000 lines rebuild large widget trees on each count update.

## 12. Android, iOS and store readiness

**Android**

| Priority | Finding | Evidence |
|---|---|---|
| Critical | `applicationId` is `com.example.jober_india`; Play rejects `com.example` | [build.gradle.kts:27](android/app/build.gradle.kts:27) |
| Critical | Release build signed with debug key; no keystore config | [build.gradle.kts:40](android/app/build.gradle.kts:40) |
| High | `ACCESS_BACKGROUND_LOCATION`, `SYSTEM_ALERT_WINDOW`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` all trigger Play policy review; the last two appear unused | [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) |
| High | No Google Maps API key in the manifest, but `GoogleMap` is used in `food_delivery_profiile.dart:554` | Manifest has no `com.google.android.geo.API_KEY` |
| Medium | Manifest declares the `flutter_overlay_window` service, a package the code never imports | Manifest lines 59–67 |
| Medium | No `<queries>` entries for `tel:` or `https`; `canLaunchUrl` (13 uses) can return false on Android 11+ | Manifest |
| Medium | OpenStreetMap public tile server is used directly; its usage policy does not permit heavy app traffic | `food_delivery_nearby.dart`, `recovery_drivers.dart` |

**iOS**

| Priority | Finding | Evidence |
|---|---|---|
| Critical | Firebase initialised only `if (Platform.isAndroid)`; the splash screen then calls `FirebaseAuth` and will crash | [main.dart:172](lib/main.dart:172) |
| Critical | No `GoogleService-Info.plist`, no `Podfile` | `ios/` listing |
| Critical | `Info.plist` has no usage descriptions for location, camera, microphone, speech or photos, and no background modes | [Info.plist](ios/Runner/Info.plist) |
| High | Bundle ID `com.example.joberIndia`, display name "Jober India" | `project.pbxproj`, Info.plist |
| High | The floating bubble and foreground service are Android concepts; LIVE needs a separate iOS design | Design gap |

## 13. Testing and documentation

- One test file, the default counter template, which cannot pass against this app ([widget_test.dart](test/widget_test.dart)).
- README is the Flutter default. No architecture notes, no schema document.
- No git repository in this folder, so there is no history or rollback.
- `missing.json` is stale: all 23 ARB files have the same 120 keys.

**Localization:** English and Malayalam ARB files are in sync with no placeholders. One case-only duplicate key exists (`searchForAService` / `searchforaservice`). The larger problem is coverage: 442 localised lookups against a far greater volume of hard-coded English strings (for example the splash permission dialog and LIVE snackbars). The Sanskrit file is named `app_san.arb` but generated as `sa`.

## 14. Confirmed bugs, possible risks, unknowns

**Confirmed bugs**
1. iOS crashes at startup (Firebase not initialised).
2. Tea Shop Hive cleanup uses the wrong box (H1).
3. Commercial and taxi search show expired LIVE providers (L1).
4. Rental count and rental list use different filters.
5. `GoogleMap` screen has no Android API key.
6. Privacy and terms links are empty.
7. The only test fails by construction.

**Possible risks**
1. Permissive rules exposing phone numbers and allowing cross-user writes.
2. Half-completed profile deletion on logout.
3. Category deletion race in Other Business.
4. Subscription unlock without payment, and clock tampering.
5. Call failures without TURN.
6. Play rejection over background location and overlay permissions.

**Unknowns (not inspectable from this folder)**
Firestore rules, Storage rules, composite indexes, TTL policy on `liveLocations.expiresAt`, App Check, API key restrictions, Firestore region, billing plan, current usage, and whether another copy of this code is under version control (the Firebase log shows a Linux path).

## 15. Keep / change / refactor

| Keep | Change | Refactor |
|---|---|---|
| Firebase Auth, Firestore, Storage | App ID, signing, iOS setup | One auth service instead of 24 OTP copies |
| Hive as a cache | Logout should sign out, not delete; add a separate "Delete account" | One permission and location service |
| Foreground-service LIVE design with `expiresAt` | All readers must check `expiresAt`; heartbeat should be slower when stationary | One generic provider registration and nearby module, parameterised by category |
| Chat pagination pattern | Subscription state must live server-side | Split `screen_home.dart`; delete commented-out code |
| ARB structure | Remove unused packages and permissions | Canonical role constants |

## 16. Firebase vs PostgreSQL

PostgreSQL/PostGIS would solve one real problem here: radius queries. It would add a server, an API layer, auth bridging and operations work that this project has no capacity for today.

The same problem can be solved inside Firestore with geohash range queries (the hash is already written, and `geoflutterfire_plus` is already a dependency) plus aggregate count queries. That removes most of the read cost with no new infrastructure.

**Assessment:** stay on Firebase. A hybrid is not justified now. Revisit only if you later need multi-attribute search, ranking, or reporting that Firestore cannot express, and decide on measured usage rather than expectation.

## 17. Budget-friendly infrastructure

Figures are order-of-magnitude and depend on region and current Google pricing, which I did not look up.

- **LIVE writes:** 180 per provider-hour. 1,000 providers live for 8 hours is about 1.4 million writes a day. Sending a heartbeat every 60–90 seconds when stationary cuts this by two-thirds or more.
- **Reads:** currently proportional to collection size per app open. Geo-bounded queries and count aggregation make this proportional to results shown.
- **SMS OTP:** billed per message. Stopping delete-on-logout removes repeat OTPs.
- **Maps:** OSM public tiles are free but not licensed for this use; budget for a low-cost tile provider or a capped Google Maps key.
- **Add at no or low cost:** App Check, Crashlytics, Firestore TTL on `liveLocations`, budget alerts in Google Cloud.
- **Avoid for now:** dedicated servers, PostgreSQL hosting, a TURN fleet (use a small metered TURN service only if calls stay in scope).

**AI budget (₹3,000/month):** the codebase size is the main cost driver for AI-assisted work. Removing the roughly 145,000 commented-out lines and splitting the largest files will reduce token use more than any tooling choice.

## 18. Prioritised roadmap

**P0 — before any release**
1. Put the project under git; export and review Firestore and Storage rules and indexes.
2. Real application ID, release keystore, consistent brand name.
3. Fix logout: sign out without deleting; add explicit account deletion.
4. Publish privacy policy and terms; fill the links.
5. Make every LIVE reader honour `expiresAt`; fix the Tea Shop box mismatch.
6. Decide iOS scope; if in scope, complete Firebase and permission setup.

**P1 — before scaling beyond a pilot area**
1. Geohash-bounded queries and aggregate counts.
2. Server-side subscription records and a real payment gateway.
3. Heartbeat or TTL for `isOnline`; slower stationary LIVE heartbeat.
4. Shared auth, permission and location services.
5. Crashlytics, App Check, budget alerts.
6. Trim Android permissions and unused packages; add the Maps key or drop Google Maps.

**P2 — maintainability**
1. Remove dead code; split oversized files; one generic provider module.
2. Tests for logout, LIVE on/off, subscription expiry, discovery filters.
3. Localise hard-coded strings; fix the duplicate ARB key.
4. Schema and architecture documentation.

## 19. Questions needing your decision

1. Is deleting the provider's profile on logout intentional?
2. Can a single phone number hold more than one provider role?
3. Is iOS required for the first release?
4. Final brand name and package ID?
5. Is voice/video calling in scope for launch?
6. Which payment provider, and are plans time-based as in `DistancePlan`?
7. Can you export the current rules and indexes from the Firebase console so they can be reviewed?
8. Is there a git repository for this code elsewhere?
9. What is the launch geography: one district, Kerala, or national from day one?

---

## Summary

**Working**
- Android startup, language selection and splash routing.
- Phone OTP sign-in and profile creation per category.
- LIVE foreground service with start/stop guards and expiry stamps.
- Chat with paginated messages.
- 23 ARB files with matching keys.
- Image compression before upload.

**Broken or risky**
- iOS startup; Android release identity and signing.
- Delete-on-logout with detached, time-limited cleanup.
- Tea Shop Hive cleanup; stale LIVE drivers; rental count mismatch.
- Whole-collection reads everywhere.
- Local-only subscription with no payment.
- Empty privacy links; no account deletion; no tests.

**Needs further investigation**
- Firestore and Storage rules, indexes, TTL, App Check.
- The remaining 20 `cleanup*OnLogout` functions.
- Whether `activateSubscription` is reachable without payment.
- Multi-role behaviour for one UID.
- Current Firebase usage and billing.

**Five most important next actions**
1. Export rules and indexes and put the whole project under git.
2. Decide the logout and account-deletion behaviour (question 1).
3. Set the real app ID, signing and brand name.
4. Fix LIVE expiry handling and the Tea Shop box mismatch.
5. Replace whole-collection reads with geohash and count queries.
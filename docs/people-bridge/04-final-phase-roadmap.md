# People Bridge — Final Phase Roadmap

Version 1, 2026-11-14. **Status: PLANNING. Awaiting owner approval. Phase 1 must not start before approval.**

Requirements, architecture and decisions are in [03-master-blueprint.md](03-master-blueprint.md). Evidence for current defects is in [01-audit-report.md](01-audit-report.md); audit finding IDs (F1, H1, A2, L1 …) are cited instead of repeated.

## Rules for every phase

- A phase starts only when the previous phase's gate is met and the owner has signed it off.
- Each phase ends with its tests written and **actually run**, bugs fixed, and a regression run of all earlier tests.
- Evidence is saved in `docs/people-bridge/evidence/phase-N.md`: commands run, their output, device and OS used, and anything not tested. A test is never reported as passed unless it was executed.
- No new dependency without a stated reason. Files are removed only after a search shows nothing uses them.
- After each phase: `flutter analyze` shows no new warnings, the app builds in release mode, and the Graphify graph is rebuilt.

### Mandatory version control (owner rule, 2026-11-14)

A phase is complete only when: implementation complete + tests passed + regression passed + changes reviewed + git commit created + GitHub push verified.

At the end of every phase, in this order:

1. Run all phase tests and acceptance checks; fix failures and rerun the affected tests.
2. Inspect `git status` and review the complete diff.
3. Check the diff for secrets, credentials, generated clutter and unrelated changes.
4. Update the relevant documentation and the evidence file.
5. Create one meaningful commit for the phase and push it to the approved GitHub branch.
6. Verify the remote contains that exact commit.
7. Report commit ID, branch, push status, tests run and remaining issues.

Never:

- Push incomplete or failing work as a completed phase. If tests or the push fail, report and stop.
- Force-push, rewrite shared history or delete remote branches without explicit approval.
- Commit API keys, credentials, signing keys, secrets, `.env` files or private user data.
- Connect to or push over an existing remote without inspecting its history first.
- Make the repository public without explicit approval.

Standard regression set (grows each phase): build and start on Android; sign in; register one mobile and one fixed-business partner; LIVE on and off; search; chat; logout and login.

## Overview

| Phase | Name | Priority | Depends on | Sessions (estimate) |
|---|---|---|---|---|
| 0 | Scope lock (this document) | — | — | done on approval |
| 1 | Foundation | Critical | Decisions 1, 2 | 3 |
| 2 | Accounts, session, roles | Critical | 1 | 3 |
| 3 | Security and privacy baseline | Critical | 2; decision 3 | 3 |
| 4 | Partner profile, LIVE, discovery | High | 3 | 4 |
| 5 | Notifications, job requests, bookings | High | 4 | 4 |
| 6 | Trust: reviews, verification, support | High | 5; decision 5 | 3 |
| 7 | Partner subscriptions and payments | High | 3, 4; decision 4 | 3 |
| 8 | Super Admin web, analytics, regions | High | 5, 6, 7 | 4 |
| 9 | iOS | High | 2–7; decision 6 | 3 |
| 10 | Consolidation | Medium | 4 | 1 per 3–4 categories |
| 11 | Full-system test, release, deployment | Critical | all; decisions 6, 7 | 3 |

Decision numbers refer to "Genuinely blocking decisions" in blueprint section 11. Session counts are estimates for planning AI use, not commitments.

---

## Phase 1 — Foundation

**Scope and deliverables**

- [ ] Git setup, first step of the phase: initialise git; extend `.gitignore` for Flutter, Dart, Firebase, Android, iOS and local tools (build output, `.gradle`, keystores, `key.properties`, `.env*`, `local.properties`, service-account files, `graphify-out/cache`, tool caches); scan for secrets; baseline commit of the code as it is today; connect the owner-approved **private** GitHub repository; verify remote, branch and push. A repository is created only with the owner's approval.
- [ ] Final app name, Android package ID and iOS bundle ID; one brand name everywhere.
- [ ] Release keystore outside the repo; release build no longer uses the debug key.
- [ ] Firestore rules, Storage rules and indexes exported from the console into the repo, unchanged.
- [ ] Full Firestore export taken and stored before any later data change.
- [ ] Commented-out code removed (about 47% of lines); no behaviour change.
- [ ] Calls removed: call screen, call entry points, `flutter_webrtc`, after a usage search.
- [ ] Unused packages and the unused overlay service declaration removed (audit section 2).
- [ ] Crashlytics added; coordinates and UIDs removed from release logs.
- [ ] Failing default test replaced by a smoke test; a single check script runs analyse, test and build.

**Files likely affected:** `pubspec.yaml`, `lib/main.dart`, every file under `lib/` (comment removal only), `lib/jober_indiaScreens.dart/Message/screen_call.dart` and its callers, `android/app/build.gradle.kts`, `AndroidManifest.xml`, `ios/Runner/Info.plist`, `firebase.json`, `test/`; new `firestore.rules`, `storage.rules`, `firestore.indexes.json`.

| Test type | Checks |
|---|---|
| Functional | Standard regression set on a real Android phone, before and after comment removal |
| Edge | Fresh install and upgrade-over-old-install both start |
| Error handling | A forced test crash appears in Crashlytics |
| Security | No keystore, password or key file in git; release log contains no coordinates or UIDs |
| Performance | Record cold-start time and app size as the baseline for later phases |
| Regression | Line-level diff of comment removal shows only comment lines deleted |

**Gate:** signed release build installs under the final ID; `flutter analyze` warnings no higher than before; smoke test passes; rules in repo equal the console export; baseline numbers recorded.

**Blocking decisions:** 1 (brand and IDs), 2 (console access and whether live data exists).

---

## Phase 2 — Accounts, session, roles

**Scope and deliverables**

- [ ] One Auth service replacing the 24 copied OTP flows (A4).
- [ ] `users/{uid}` account record with roles held and active role; multi-role supported, one active at a time.
- [ ] One canonical list of role and category identifiers; old spellings mapped (F7).
- [ ] Session service; Hive reduced to `session` and `prefs` with a one-time migration from the 17 old boxes (H1–H7).
- [ ] Logout in the confirmed order: stop LIVE, mark offline, cancel listeners, clear session, sign out. Profiles are no longer deleted (A2, A3).
- [ ] All `cleanup*OnLogout` functions removed after each is read and its non-delete side effects accounted for.

**Files likely affected:** new `lib/services/auth_service.dart`, `session_service.dart`, `lib/core/roles.dart`; `common_profile_services.dart`; all 24 `*_login.dart`; `screen_home.dart` (logout and cleanup block); `screens/splash/screen_splash.dart`; `main.dart` (box opening).

| Test type | Checks |
|---|---|
| Functional | Register, logout, login restores the same profile for each role with no re-registration; role switch works |
| Edge | Two roles on one number; upgrade from an old install with each old Hive box populated; Tea Shop keys (H1) are gone after migration |
| Error handling | Logout with no network completes locally and the partner goes offline by expiry; wrong and expired OTP; SMS quota error |
| Security | Session box holds no data after logout; one user cannot read another's `users` document |
| Performance | Start-up opens two boxes, not eleven; cold start no slower than the baseline |
| Regression | Standard set; unit tests for session, role mapping and the logout sequence |

**Gate:** zero `verifyPhoneNumber` calls outside the Auth service; zero profile deletes on logout; migration test passes for every old box; all unit tests pass.

**Blocking decisions:** none. Defaults apply.

---

## Phase 3 — Security and privacy baseline

**Scope and deliverables**

- [ ] Rules rewritten: owners write only their own documents; chat limited to participants; shared category documents and counters not writable by clients (F1, F2).
- [ ] Phone numbers and exact coordinates moved out of publicly readable fields.
- [ ] Storage rules: owner-only paths, size and type limits.
- [ ] App Check in monitor mode, then enforced.
- [ ] First Cloud Functions project; account deletion Function removing profiles, LIVE record, files and the Auth user (A1).
- [ ] In-app "Delete account" with OTP re-check, and a public web deletion page.
- [ ] Privacy policy and terms published and linked; consent recorded at registration.
- [ ] Scheduled Firestore backup and one tested restore into a test project.

**Files likely affected:** `firestore.rules`, `storage.rules`; new `functions/`; `Privacy&Terms/web_liknks.dart`; settings screen; partner profile models (field moves); new `test/rules/`.

| Test type | Checks |
|---|---|
| Functional | Delete account removes every trace; policy links open |
| Edge | Deletion with two roles; deletion while LIVE; deletion retried after a partial failure |
| Error handling | Function failure leaves the account usable and reports the error |
| Security | Emulator rules tests for every collection: second user cannot read private fields or write anything not theirs; unauthenticated access denied; App Check rejects an unattested client |
| Performance | No extra reads on normal screens from the field move |
| Regression | Standard set against the new rules; all earlier tests |

**Gate:** rules test suite passes with a case for every collection; a restore from backup is demonstrated; App Check enforced; deletion verified by inspecting the database after the test.

**Blocking decisions:** 3 (policy text and legal entity). Requires the Blaze plan.

---

## Phase 4 — Partner profile, LIVE, discovery

**Scope and deliverables**

- [ ] Generic partner registration and profile, driven by category configuration, proven on three categories: one mobile, one fixed business, one listing.
- [ ] One Location and Permission service replacing 46 separate permission requests (L6).
- [ ] LIVE: heartbeat on 30 m movement or 60–90 s when stationary; offline mark on service stop; every reader checks expiry; `isOnline` derived from LIVE; TTL policy (L1–L5).
- [ ] Floating bubble and overlay permission removed (L7); unused exact-alarm and boot permissions removed.
- [ ] Discovery service: geohash queries, exact distance on device, pagination; counts from aggregate queries; one radius rule (F3–F5, F8).
- [ ] Licensed map tiles; the single Google Maps screen moved to `flutter_map`.
- [ ] Background location requested only when LIVE is switched on, after a disclosure screen.

**Files likely affected:** `location_backgrnd_servce.dart`; all `*_nearby.dart`; `screen_home.dart` (count listeners, LIVE toggle); `screen_more.dart`; `other_business_categories.dart`; `AndroidManifest.xml`; new `lib/services/discovery_service.dart`, `location_service.dart`, `lib/features/partner/`; `firestore.indexes.json`.

| Test type | Checks |
|---|---|
| Functional | Partner goes LIVE and appears to a nearby customer; goes off and disappears; counts equal list lengths (rental mismatch fixed) |
| Edge | App killed while LIVE disappears within the expiry time; search at a geohash cell boundary; partner exactly at the radius limit; no results |
| Error handling | Location denied, denied forever, GPS off, no network — each shows a clear message and no crash |
| Security | Customers cannot read exact coordinates of partners; a client cannot write another partner's LIVE record |
| Performance | Document reads per search are bounded and logged; Home opens no whole-collection listener; LIVE writes per hour measured against the old 180 |
| Regression | Standard set; unit tests for geohash bounds, expiry filter and radius rule |

**Gate:** a search for "whole collection" reads returns none; reads per search and LIVE writes per hour recorded and below agreed limits; scrolling a 200-item list drops no frames in profile mode.

**Blocking decisions:** none. Defaults: bubble dropped, `flutter_map` kept.

---

## Phase 5 — Notifications, job requests, bookings

**Scope and deliverables**

- [ ] Push notifications: device tokens per user, a sending Function, an in-app notification list.
- [ ] Job requests: create, fan-out Function to eligible nearby partners, partner responses, expiry by schedule, persistence until closed.
- [ ] Bookings: quotation (optional), confirmation in a transaction so only one partner is confirmed, schedule, cancel, rebook, history.
- [ ] Existing `rideRequests` and `driverRequests` flows moved onto the general request flow.
- [ ] Phone number and exact location revealed only to the matched pair.

**Files likely affected:** new `lib/features/requests/`, `lib/features/bookings/`, `lib/services/notification_service.dart`; `functions/` (fan-out, expiry, booking state, push); `firestore.rules`; taxi and driver request screens; `AndroidManifest.xml` (notification permission).

| Test type | Checks |
|---|---|
| Functional | Request reaches several partners at once; customer confirms one; booking runs through every state; rebook creates a new request |
| Edge | Two partners accept at the same moment; customer cancels while a partner is responding; request expires unanswered; partner goes offline mid-request; duplicate taps |
| Error handling | Fan-out failure is retried and reported; push permission denied still shows in-app notifications; offline actions queue or fail clearly |
| Security | A partner not in the recipient list cannot read or answer a request; clients cannot set booking status directly; contact details hidden until match |
| Performance | Fan-out completes within an agreed time for the capped number of partners; reads and Function invocations per request recorded |
| Regression | Standard set plus Phase 4 discovery tests; Function unit tests |

**Gate:** concurrency test shows exactly one confirmed booking; every state change produces one notification; rules tests cover requests and bookings.

**Blocking decisions:** none. Defaults apply for cap, expiry and customer-chooses.

---

## Phase 6 — Trust: reviews, verification, support

**Scope and deliverables**

- [ ] Reviews: one per completed booking; rating aggregates written by a Function.
- [ ] Verification: partner uploads documents; admin approves; verified badge.
- [ ] Support tickets; disputes linked to a booking.
- [ ] Minimal admin tool (verification queue, suspend account) so partners can be approved before the full dashboard exists.
- [ ] Report and block a user.

**Files likely affected:** new `lib/features/reviews/`, `verification/`, `support/`; `functions/`; `firestore.rules`, `storage.rules`; partner profile screens; new `admin/` (first screens).

| Test type | Checks |
|---|---|
| Functional | Review after completion appears on the profile; verification approve and reject; ticket lifecycle |
| Edge | Second review attempt; review on a cancelled booking; re-submission after rejection; suspended partner mid-booking |
| Error handling | Upload failure and oversized file; ticket submitted offline |
| Security | Partner cannot set own `verified` flag or rating; documents readable only by owner and admins; only admins can suspend |
| Performance | Profile shows rating from an aggregate, not by reading all reviews |
| Regression | Standard set; booking tests from Phase 5 |

**Gate:** rules tests prove self-verification and rating tampering are impossible; a suspended partner is absent from search within one refresh.

**Blocking decisions:** 5 (verification documents per category).

---

## Phase 7 — Partner subscriptions and payments

**Scope and deliverables**

- [ ] Plans stored in Firestore configuration.
- [ ] Payment: order Function, checkout, webhook verification, `subscriptions/{uid}` written only by the server.
- [ ] Expiry applied by the server; renewal reminders.
- [ ] Old local subscription code and Hive keys removed (audit section 9).
- [ ] Radius rule in Discovery reads the partner's plan.

**Files likely affected:** `screen_home.dart` (subscription block removed); new `lib/features/subscription/`; `functions/` (order, webhook, expiry); `firestore.rules`; `discovery_service.dart`.

| Test type | Checks |
|---|---|
| Functional | Buy, renew and expire a plan in the gateway's test mode; radius changes accordingly |
| Edge | Payment succeeds but app is closed; duplicate webhook; refund; plan change mid-term; reinstall keeps the plan |
| Error handling | Failed and abandoned payments unlock nothing and show a clear state |
| Security | Forged webhook rejected; client cannot write `subscriptions`; device clock change has no effect; no gateway secret in the app |
| Performance | Subscription read once per session and cached |
| Regression | Standard set; discovery tests with free and paid partners |

**Gate:** tamper tests (clock, forged webhook, direct write) all fail safely; test-mode payment evidence saved; no subscription key left in Hive.

**Blocking decisions:** 4 (plans, prices, gateway, store-billing position, radius meaning).

---

## Phase 8 — Super Admin web, analytics, regions

**Scope and deliverables**

- [ ] Flutter web admin app on Firebase Hosting, sharing models with the mobile app.
- [ ] Admin roles as custom claims: super admin, admin, support, read-only; second sign-in factor.
- [ ] Screens: users and partners, verification, categories, plans and subscriptions, requests and bookings, tickets and disputes, policy links, region switches, audit log.
- [ ] All privileged writes through Functions, each recorded in the audit log.
- [ ] Analytics events for the registration, search, request, booking and payment funnels; BigQuery export only if dashboard reports need it.
- [ ] Regions enabled per state and district from configuration.

**Files likely affected:** `admin/` (new app), shared `lib/models/`, `functions/` (admin actions, claims), `firestore.rules`, `firebase.json` (hosting).

| Test type | Checks |
|---|---|
| Functional | Each screen performs its actions; region switched off hides registration and search there |
| Edge | Admin demoted while signed in; two admins editing the same record; very large lists paginate |
| Error handling | Function denial shown clearly; partial failures do not leave half-applied changes |
| Security | Each role limited to its permissions, tested per role; non-admin token rejected by every admin Function; every action in the audit log; mobile app cannot call admin Functions |
| Performance | Admin lists paginated; no whole-collection reads |
| Regression | Standard set; mobile app unaffected by admin rules |

**Gate:** permission matrix test passes for all four roles; audit log entry exists for every admin action in the test run.

**Blocking decisions:** none blocking; the screen list above is the default scope.

---

## Phase 9 — iOS

**Scope and deliverables**

- [ ] Firebase configured for iOS; start-up crash fixed (audit section 12).
- [ ] Permission texts, background location mode, push through APNs, OTP on a real device.
- [ ] LIVE designed for iOS background location rules, with no bubble or Android service.
- [ ] Every screen checked on small and large iPhones.

**Files likely affected:** `lib/main.dart` (platform gate), `ios/Runner/Info.plist`, `ios/Podfile`, `ios/Runner/GoogleService-Info.plist`, `location_service.dart` and LIVE service (platform branch), Xcode project settings.

| Test type | Checks |
|---|---|
| Functional | Full standard set on a physical iPhone, plus requests, bookings and payment |
| Edge | App backgrounded and killed while LIVE; permission changed in Settings while running; low-power mode |
| Error handling | Push not authorised; location "While Using" only |
| Security | Same rules and App Check (App Attest) as Android |
| Performance | Cold start and scrolling against the same targets as Android |
| Regression | Android standard set unchanged after platform branches |

**Gate:** end-to-end run on a physical iPhone recorded; TestFlight build accepted.

**Blocking decisions:** 6 (Apple Developer account). Needs a Mac for builds.

---

## Phase 10 — Consolidation

**Scope and deliverables**

- [ ] Remaining categories moved onto the generic partner module, three or four per session; old per-category files removed once unused.
- [ ] Hard-coded strings moved to the language files; duplicate ARB key fixed.
- [ ] `screen_home.dart` reduced to composition of shared services.

**Files likely affected:** remaining `*_login.dart`, `*_nearby.dart`, profile screens per category; `lib/l10n/*.arb`; `screen_home.dart`.

| Test type | Checks |
|---|---|
| Functional | Each migrated category passes the same registration, LIVE, discovery and booking checks |
| Edge | Existing partners of each category still load their old profile documents |
| Error handling | Same shared error paths as Phase 4 |
| Security | Rules tests extended to each migrated collection |
| Performance | App size and cold start compared with baseline |
| Regression | Full suite after each batch |

**Gate:** no category-specific copy of auth, permission, upload or discovery code remains; line count and file sizes recorded.

**Blocking decisions:** none. Can run alongside Phases 5–9.

---

## Phase 11 — Full-system test, release, deployment

**Scope and deliverables**

- [ ] Full regression on Android 10–15 and supported iOS versions, on low- and mid-range devices.
- [ ] End-to-end scenarios with separate customer, partner and admin accounts.
- [ ] Load check of discovery, fan-out and LIVE at the expected launch-state volume; cost per active user measured.
- [ ] Security review: rules, Functions, admin roles, key restrictions, dependency audit.
- [ ] Accessibility pass: text scaling, contrast, screen reader labels, touch targets.
- [ ] Store listings, Data Safety form, privacy labels, background-location declaration and video, subscription disclosures.
- [ ] Closed test on Play and TestFlight; staged rollout; rollback plan; monitoring and budget alerts confirmed.
- [ ] Launch state enabled in region configuration; production deployment of rules, indexes and Functions from the repo.

| Test type | Checks |
|---|---|
| Functional | Every flow in the blueprint, on both platforms |
| Edge | Poor network, airplane mode, low storage, time-zone and language changes, upgrade from the current production build if one exists |
| Error handling | Each backend service made unavailable in turn |
| Security | Penetration-style checks with a non-owner account and a tampered client |
| Performance | Targets in blueprint section 8 measured and recorded |
| Regression | Whole automated suite on the release build |

**Gate:** zero open critical or high defects; both stores accept the closed-test builds; rollback rehearsed; owner approves release.

**Blocking decisions:** 6 (store accounts), 7 (launch state).

---

## Work that can safely be combined

| Combine in one session | Why it is safe |
|---|---|
| Phase 1: git, IDs, signing, package and manifest clean-up | All configuration, no logic |
| Phase 1: comment removal across all files | Mechanical; verified by diff, no reading of logic needed |
| Phase 2: Auth service plus all 24 login screens | Same replacement repeated; one test covers all |
| Phase 2: Hive consolidation plus logout rewrite | Both touch the same session code |
| Phase 3: rules rewrite plus rules tests | Tests are written against the rules in the same context |
| Phase 4: expiry filter, heartbeat and offline mark | One file, one service |
| Phase 4: Discovery service plus all nearby screens of one workflow type | Same query shape |
| Phase 5: request fan-out, expiry and push Functions | One Functions module |
| Phase 10: three or four categories per session | Configuration only once the generic module exists |

Keep separate: rules changes and data migrations; payment work; iOS work; anything touching `screen_home.dart` together with another large file.

## Token and cost practice

- One session per row above; start each from `CLAUDE.md` and the relevant phase section only.
- Use `graphify query` to locate code before reading files; rebuild the graph at the end of each phase.
- Phase 1 comment removal comes first because it roughly halves the size of every later read.

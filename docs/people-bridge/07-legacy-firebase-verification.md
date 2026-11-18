# People Bridge — Legacy Firebase Verification

Version 3, 2026-11-18 (remote checks 21:50–21:55 IST; owner clarification on D16 added). Read-only, except one unintended API enablement recorded in §3.
Scope: Firebase project `citizen-india` and the old app at commit `1ca3e2e`.
Status labels: **VERIFIED** · **PARTIAL** · **NOT VERIFIED** · **N/A**.

## 1. Executive summary

The Firebase project `citizen-india` is **almost empty**. It holds no Firestore database, no Realtime Database, no Storage bucket, no deployed rules, no Cloud Functions, no extensions, no Cloud Run services, no Pub/Sub topics, no Remote Config parameters and no Hosting releases. Its only live assets are:

- **Authentication:** phone sign-in enabled; **one** user; 2 test phone numbers; SMS restricted to India (`allowedRegions: ["IN"]`).
- **Three app registrations** (Android, iOS, web) under `com.example` identifiers.
- **One unintended remote change during this verification:** `firebase ext:list` enabled the Firebase Extensions API (§3). No intentional write was performed. The API stays enabled, unchanged, pending D17 and your explicit approval.
- **Google Analytics:** linked, with 3 data streams.
- **A default Hosting site** with nothing deployed.

**Consequences:**

1. The old app cannot have worked end to end against this project. Every Firestore and Storage call it makes has no database or bucket to reach. **No Firestore or Storage user data exists here to preserve**; the 45 legacy collections and 5 Storage paths in the code exist only in the code.
2. The old app's logout deletions (`screen_home.dart:5010`, `:5051`, `:5551`, `:5668`) **cannot destroy data in this project today**, because there is nothing to delete. They become dangerous only if a database is created under permissive rules while old installs exist.
3. **The Firestore location has never been chosen.** No resource location is set (`locationId: (none)`; `projects:list` shows `[Not specified]`). The rebuild can pick the region, and it is permanent once set.
4. Data preservation reduces to: the one Auth user, the Auth configuration, the app registrations and Analytics.
5. **Owner confirmed (D16, 2026-11-18):** the old app never had real production users or production data, and no historical Firebase project with real user data is known. No production-data migration is planned; this conclusion is revisited only if contrary evidence appears. `citizen-india` stays the intended backend project.

## 2. Identity and access

| Item | Result | Source and time (IST) |
|---|---|---|
| CLI account | signed in (owner's Google account; address not recorded here) | `firebase login:list` 21:50:07 |
| Project match | `citizen-india`, number `897017107721`, display name "Citizen India", state `ACTIVE` | `firebase projects:list` 21:50:08; Firebase Management API `GET projects/citizen-india` 21:52:45 |
| Projects visible to this account | 1 | `projects:list` |
| Access level | the signed-in user is the single `roles/owner` member, so full write power exists. **No intentional write was performed.** However, `firebase ext:list`, run with this access, **unexpectedly enabled the Firebase Extensions API** at 21:50:56 IST. That is an unintended remote configuration change, disclosed in §3 | `getIamPolicy` (read-only); `ext:list` output |
| Firebase MCP | not used for remote reads (its environment showed no active project; setting one changes local configuration) | `firebase_get_environment` |
| Method | Firebase CLI read commands, plus read-only REST calls (GET, and the read-only `accounts:query` count and `getIamPolicy`) made with the CLI's existing sign-in. No tokens, keys or user records were printed | scratchpad scripts `fbread/*.cjs` |

## 3. Access limitations and one unintended change

- **Not readable, because their APIs are disabled in the project.** Reading them would require enabling the API, which is a configuration change, so they were not read:
  - **Billing** (Cloud Billing API);
  - **App Check** (App Check API);
  - **API-key restrictions** (API Keys API);
  - **Cloud Run** (Admin API).

  You can see all of these in the Firebase and Google Cloud consoles.
- **Not inspected:**
  - Crashlytics and Performance: no admin API; neither SDK is in the code.
  - FCM topics: no metadata API.
- **Unintended change:** at 21:50:56 `firebase ext:list` printed "missing required API firebaseextensions.googleapis.com. Enabling now..." and enabled the **Firebase Extensions API** in `citizen-india`.
  - It creates no resources and costs nothing on its own.
  - No other remote change was made.
  - It stays **unchanged** until its dependencies and a safe reversal are assessed and you explicitly approve (D17). After this, only plain GET or read-only REST calls were used.

## 4. Resource inventory (verified)

| Resource | Remote state | Evidence |
|---|---|---|
| Firestore | **none**: no databases | `firestore:databases:list` "No databases found"; `GET .../databases` returned `[]`; `databases:get (default)` and `firestore:indexes` returned HTTP 404 |
| Firestore location, indexes, TTL | **none / not set** | as above; `adminSdkConfig.locationId` absent |
| Realtime Database | **none** | `database:instances:list` |
| Security rules (any service) | **none released** | `GET firebaserules .../releases` returned `[]` |
| Cloud Storage | **no buckets**: default `citizen-india.firebasestorage.app` and `citizen-india.appspot.com` do not exist | `GET storage/v1/b?project=` returned `[]`; bucket GETs returned 404 |
| App Engine (legacy location) | **none** | `GET appengine/v1/apps/citizen-india` returned 404 |
| Authentication | phone **enabled**; email, anonymous and federated IdPs off; MFA off; no blocking functions; plain Firebase Auth (not Identity Platform); sign-up quota configured | `GET identitytoolkit admin/v2 .../config`; `defaultSupportedIdpConfigs` returned `[]` |
| Auth users | **1** | read-only `accounts:query` with `returnUserInfo:false`; no user data returned |
| Phone settings | 2 test phone numbers; SMS region policy **allowlist only: IN** | Auth config |
| Authorized domains | `localhost`, `citizen-india.firebaseapp.com`, `citizen-india.web.app` | Auth config |
| Cloud Functions | **none** | `functions:list` |
| Extensions | **none** | `ext:list` |
| Cloud Run | NOT VERIFIED (API disabled, so effectively none) | 403 `SERVICE_DISABLED` |
| Pub/Sub | 0 topics | `GET pubsub .../topics` |
| Remote Config | template with 0 parameters | `GET remoteConfig` |
| Hosting | site `citizen-india` (`https://citizen-india.web.app`), **0 releases** | `hosting:sites:list`; `GET .../releases` |
| Analytics | **linked**, 3 streams | `GET .../analyticsDetails` |
| App registrations | Android `1:…:android:5b7a…` ("jober_india (android)"); iOS `1:…:ios:e340…`; web `1:…:web:d774…`. **No SHA certificates** on the Android app | `apps:list`; `apps:android:sha:list` |
| App Check | NOT VERIFIED (API disabled, so not configured) | 403 `SERVICE_DISABLED` |
| FCM | `fcm` and `fcmregistrations` APIs enabled (Firebase default); not used by the old app | enabled-API list |
| Enabled APIs | 43, including Firestore, Datastore, Storage, Cloud Functions, Pub/Sub, Logging, Monitoring, BigQuery family, Firebase Extensions (enabled at 21:50:56, §3) | `GET serviceusage .../services?filter=state:ENABLED` |
| IAM | `roles/owner`: 1 user; `roles/editor`: 2 service accounts; 6 Google service-agent roles. Identities not recorded | `getIamPolicy` |
| Billing plan | NOT VERIFIED (API disabled) | — |

## 5. Old app versus remote resources

| Old app dependency (code) | Exists remotely? | Implication |
|---|---|---|
| 45 Firestore collections (list in v1 of this report and the audit) | **No**: there is no database | old installs fail on every Firestore call; nothing to preserve |
| Storage roots `profilePhotos/`, `profile/`, `chat_media/`, `other_business_profiles/`, `taxiVehicleCategories/` | **No**: there is no bucket | uploads fail; nothing to preserve |
| Phone OTP (`verifyPhoneNumber` in 24 files) | **Yes**, phone enabled, India only | the one Auth user may come from this flow or from a test |
| Android app `com.example.jober_india` | registered, **without SHA certificates** | real-device phone auth depends on Play Integrity or reCAPTCHA verification; SHA fingerprints are normally added for the final app ID |
| iOS `com.example.joberIndia` | registered | no iOS config file in the repo |
| Analytics measurement ID in the `windows` options | linked property | no analytics code in the app |

**Remote resources an installed old app still needs:** effectively none. It cannot function without Firestore. **Obsolete:** every legacy collection and path name. **Cannot safely be retired:** the one Auth user (until you say otherwise), the app registrations (the Analytics streams are attached), and the Auth phone configuration.

## 6. Risks (updated)

| # | Risk | Evidence | Severity now |
|---|---|---|---|
| S1 | Old-app logout deletes profiles | code | **Low in `citizen-india`** (no data). It becomes high if a database is created with permissive rules while old installs exist; deny-by-default rules and App Check prevent that |
| S2 | Permissive legacy rules | none deployed | **N/A**: there is no legacy ruleset to stay compatible with |
| S3 | Catch-all rules opening new collections | — | still a design rule: the new ruleset is deny-by-default, with no catch-all allow |
| S4 | The Firestore location is chosen once and is permanent | no location set | **High, a decision**: it must be chosen deliberately (D2) |
| S5 | No App Check | API disabled | must be set up before launch |
| S6 | Broad `roles/editor` on 2 service accounts (Google's default) | IAM | review least privilege before production |
| S7 | `localhost` in Auth authorized domains | Auth config | keep for development; review before launch |
| S8 | Another Firebase project may hold the real legacy data | old app shipped with Firestore code; only one project visible | **Unknown, owner question** |
| S9 | SMS cost and abuse | India-only allowlist already set (good); no App Check | add App Check plus rate limits before launch |

## 7. Identity and data preservation

- **Identity:** existing Auth users keep their UIDs in the rebuilt app, because it uses the same Auth project. There is only one user, so continuity can be confirmed directly, with your own number, on a real device after the new app is registered.
- **Number recycling and change-number policy** are still needed before any future migration (D14). There is no legacy profile data to import from this project.
- **Coexistence:** there is no legacy data, rules or backend to coexist with. The rebuild owns the project from the start. The protections that still matter:
  - deny-by-default rules, including the legacy collection names;
  - App Check enforced before launch (old builds have no App Check, so they are locked out);
  - no database created until the new rules are ready to deploy with it.

## 8. Backup and restore requirements

| Asset | Today | Backup action |
|---|---|---|
| Auth (1 user plus configuration) | exists | record the configuration (§4) in the repo; optionally `auth:export` of 1 user (personal data; needs your approval, encrypted storage) |
| App registrations and Analytics link | exist | record IDs (§4); nothing to export |
| Firestore, Storage, rules, indexes, TTL, Functions | do not exist | from the first deployment: everything kept in the repo; scheduled Firestore backups or managed exports, plus PITR once the database exists (Blaze, to verify); Storage bucket copy policy |
| IAM | exists | record roles (§4) |

A restore demonstration (export, then import into staging, then reconcile counts) becomes a gate before the first production launch, not before Phase 2.

## 9. Staging and region

- **Region:** none is set yet. Choosing it is decision D2.
  - Options in India are `asia-south1` (Mumbai) and `asia-south2` (Delhi).
  - Firestore, the default Storage bucket, Functions, Scheduler and backups should all use the same region.
  - The Firestore location cannot be changed after the database is created.
- **Storage:** creating the default `*.firebasestorage.app` bucket is believed to require the Blaze plan (to verify in the console).
- **Staging:** a separate project is still recommended (D3), so test data never mixes with the one real user and future production data. The emulator is used for all rules and Functions tests.

## 10. Cost and billing

- **Plan:** NOT VERIFIED (Billing API disabled). Check it in the console under Usage and billing.
- **Current exposure is near zero:** no database, no bucket, no Functions. Active cost drivers today are phone-auth SMS (India only) and Analytics (free).
- **Every growth driver begins with the rebuild** (Firestore, Storage, Functions, SMS, backups, logging). Hence the measurable budget controls in the amendment (§4.7).

## 11. Store implications

Unchanged from version 1 of this report: phone OTP, account deletion, background location, subscription billing, privacy forms. One addition: register **SHA-1/SHA-256** for the final Android app ID (debug, upload and Play signing keys) so phone auth and Play Integrity work.

## 12. Owner questions

1. ~~Did the old app ever have real users or data elsewhere?~~ **Answered (D16, owner, 2026-11-18): no historical production users or data.** Revisit only if contrary evidence appears.
2. **OPEN (D15):** identity and purpose of the one Auth user. It stays untouched until established.
3. **OPEN:** billing plan of `citizen-india` (console).
4. **OPEN (D2):** Firestore and Storage region, `asia-south1` or `asia-south2`.
5. **OPEN (D3):** separate staging project. Nothing is created without approval.
6. ~~Is the old app installed anywhere?~~ Covered by D16: no real users.
7. **OPEN:** least-privilege review of the `roles/editor` service accounts (before production).
8. **OPEN (D17):** the Firebase Extensions API stays unchanged until its dependencies and a safe reversal are assessed and you explicitly approve.

## 13. Prioritised actions

1. ~~Answer Q1 and Q6~~: done (D16 confirmed).
2. Check billing, App Check and API-key restrictions in the console, and record them here.
3. Decide D2 (region) and D3 (staging) before any database or bucket is created.
4. Keep `citizen-india` free of databases and buckets until the Phase 3 rules are ready (prevents S1).
5. Re-run this inventory immediately before the first production deployment.

## 14. Verification matrix

| Item | Status | Evidence / source | Risk / implication | Next action |
|---|---|---|---|---|
| CLI authenticated | VERIFIED | `login:list` 21:50:07 | — | — |
| Project ID, number, state | VERIFIED | `projects:list`; Management API | — | — |
| Access level | VERIFIED: owner | `getIamPolicy` | full write power. No intentional write, but **one unintended configuration change**: the Extensions API was enabled by `ext:list` (§3) | stays enabled pending D17 and your explicit approval |
| Billing plan | NOT VERIFIED | Billing API disabled | Blaze needed for Storage, Functions, backups | console |
| Firestore databases | VERIFIED: none | CLI and REST | nothing to preserve; region free to choose | D2 |
| Firestore rules, indexes, TTL | VERIFIED: none | rules releases `[]`; indexes 404 | — | new rules in Phase 3 |
| Realtime Database | VERIFIED: none | CLI | — | — |
| Storage buckets and rules | VERIFIED: none | REST list `[]`; 404s | — | create with the region decision |
| Auth providers | VERIFIED: phone only | Auth config | — | — |
| Auth SMS policy | VERIFIED: allowlist IN | Auth config | limits abuse cost | keep |
| Auth user count | VERIFIED: 1 | `accounts:query` count | trivial continuity | keep untouched until identity known (D15) |
| Auth authorized domains | VERIFIED | Auth config | `localhost` present | review before launch |
| Functions | VERIFIED: none | CLI | — | — |
| Extensions | VERIFIED: none (API now enabled) | CLI | §3 incident | unchanged until assessed and approved (D17) |
| Cloud Run | PARTIAL: API disabled | 403 | none possible | — |
| Pub/Sub | VERIFIED: 0 topics | REST | — | — |
| Remote Config | VERIFIED: empty | REST | — | — |
| Hosting | VERIFIED: site, 0 releases | CLI and REST | usable for the admin web | Phase 9 |
| Analytics | VERIFIED: linked, 3 streams | REST | preserve the link | keep registrations |
| App registrations | VERIFIED: 3, `com.example` IDs | `apps:list` | final IDs need new registrations | D5 |
| Android SHA fingerprints | VERIFIED: none | `apps:android:sha:list` | phone auth and Play Integrity setup | add for the final app |
| App Check | PARTIAL: API disabled (not configured) | 403 | none yet | Phase 2 |
| API-key restrictions | NOT VERIFIED | API Keys API disabled | key misuse | console |
| IAM | VERIFIED | `getIamPolicy` | broad editor service accounts | review (Q7) |
| Legacy data elsewhere | OWNER CONFIRMED: none (D16) | owner statement 2026-11-18; one visible project | no migration planned | revisit only on contrary evidence |
| Old-app logout deletes | VERIFIED in code; no target data | code plus no database | low unless a database is created permissively | deny-by-default |
| Remote state change during audit | VERIFIED: 1 (Extensions API enabled) | `ext:list` output 21:50:56 | none functional | unchanged until assessed and approved (D17) |

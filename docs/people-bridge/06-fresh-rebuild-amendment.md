# People Bridge — Fresh Rebuild Roadmap Amendment

Version 0.5, 2026-11-18. **Status: APPROVED by the owner on 2026-11-18 (D1).** Nothing here is implemented. Phase 1 was signed off by the owner on 2026-11-19; Phase 2 starts only on the owner's explicit instruction.

Approval record (2026-11-18, owner):
- **D1:** amendment 06 v0.5 approved. It replaces roadmap Phases 2–11 and revises Phase 1.
- **D9:** built-in Flutter state management approved for the initial build.
- **D11:** the drafted documentation corrections approved, and committed in `5a5cadd`.
- Every other decision keeps its status in §11. **This is not Phase 1 sign-off.**
- **D5 clarification (owner, 2026-11-18; not an approval of D5):**
  - Working app name: **People Bridge (provisional)**. The final app and brand name may change and will be confirmed at the final branding and release stage.
  - Still undecided: Android package ID, iOS bundle ID, legal entity, owned domain.
  - D5 stays OPEN.
- **Phase 1 closure rulings (owner, 2026-11-18):**
  - Keystore, Crashlytics and the CI check script belong to **Phase 2**.
  - Old-app manual regression (M1–M10): **not applicable**.
  - Release-mode build: **not required for Phase 1**; verified in Phase 2.
  - 07 v3 (2026-11-18) is accepted as the Phase 1 Firebase inventory.
  - D2, D3 and D4 are **deferred to Phase 3**, before any database or resource is created; any billing change still needs explicit owner approval.
  - D15: the Auth user stays untouched; identification is deferred.
  - D17: the Extensions API stays enabled and unchanged; it is assessed before Phase 3.
  - Billing, App Check and API-key console checks: **OWNER-APPROVED DEFERRED / NOT VERIFIED**. No API is enabled to inspect them.
  - None of these is Phase 1 sign-off.
- **Amendments A and B (owner-approved 2026-11-18, applied to §8 and §11):**
  - **A:** the D5 ID approach, (a) or (b), is due **before any Phase 2 app registration** and is not a Phase 1 closure criterion. The D5 identifiers stay OPEN.
  - **B:** the billing, App Check and API-key console checks are OWNER-APPROVED DEFERRED (not verified). They are to be recorded in 07 before Phase 3 creates any resource, and are not a Phase 1 closure criterion.

Changes in v0.5 (documentation consistency pass, 2026-11-18; recorded so every difference from v0.4 is traceable):
- §11 is now the authoritative decision register, with alias and status columns. References elsewhere in 06 now use those IDs, aligned with 07 v3 and 08.
- **Changed from v0.4. These are proposal changes, not owner approvals:**
  - **D4:** "Needed by" moved from "Phase 3 (staging can start earlier)" to **Phase 1, before any resource is created**. The reason: Storage, Functions, SMS and backups all need billing (08 §3 D4).
  - **D10:** scope **expanded** from "SMS fallback for critical notifications (adds cost)" to **OTP delivery and SMS fallback** (Firebase Phone Auth, a possible DLT route, voice or WhatsApp fallback). Phase moved from **7 to 4**, to match 08 D10.
- **Reworded only (meaning unchanged):**
  - **D13** now lists its OPEN points (late-eligible partners; who may close a request and whether a time limit exists; quotations under first-accept-wins; request caps).
  - **D14** drops "before legacy profile import", because import is contingency-only (D16).
- Statuses unchanged: D1 not approved; D15 and D17 OPEN; D16 OWNER CONFIRMED; D6 and D8 contingency only. No owner approval is implied by any change above.

Changes in v0.3, from the authenticated verification ([07](07-legacy-firebase-verification.md) v2, 2026-11-18):
- `citizen-india` has **no Firestore database, no Storage bucket, no rules, no Functions** and **1 Auth user**.
- Legacy coexistence (§5) is therefore simplified: there is no legacy data in this project to preserve, import or stay rules-compatible with, unless another project holds it (D16).
- The region is not yet chosen and becomes a decision (D2).
- D6, D8, D12 and D15 are adjusted below.
- The v0.2 text on combined rules and legacy import stays as the plan **only** for the case where D16 finds legacy data elsewhere.

Changes in v0.4 (owner clarification, 2026-11-18):
- **D16 is OWNER CONFIRMED:** the old app never had real production users or production data, and no historical Firebase project with real user data is known.
- Production-data migration is removed from the plan. Legacy import, back-fill and legacy-compatible rules are kept **only as a contingency**, to be reopened if contrary evidence appears.
- `citizen-india` stays the intended backend project.
- The existing Auth user stays untouched (D15), and the Extensions API stays unchanged (D17).
- The region (D2) and the staging project (D3) remain OPEN.

Changes in v0.2, from [07-legacy-firebase-verification.md](07-legacy-firebase-verification.md) and the owner's review list:
- Customer search radius separated from partner subscription eligibility (§4.6).
- Exact request broadcast, acceptance, expansion and lifecycle rules (§4.6).
- Unpublishing the old app does not stop installed copies (§5).
- Combined rules design (§4.4, §5).
- Backup scope widened to Auth and configuration (§6).
- Account deletion versus legacy retention (§4.6).
- Staging and Blaze implications (§4.2).
- Measurable budget controls (§4.7).
- App-registration and production-deployment approval gates (§6).
- Evidence rule for acceptance criteria (§8).

*(At v0.2)* Remote facts about `citizen-india` were still unverified, because there was no authenticated access. *(Superseded at v0.3: verified in 07.)*

On approval this document amends [04-final-phase-roadmap.md](04-final-phase-roadmap.md): it keeps that roadmap's rules (phase gates, evidence files, version control) and replaces its Phases 2–11 with the phases below. Requirements stay in [03-master-blueprint.md](03-master-blueprint.md); defects of the old app stay in [01-audit-report.md](01-audit-report.md) (cited by ID, not repeated). Labels: **[Confirmed]** owner decision or verified evidence · **[Required]** owner requirement without agreed detail · **[Recommended]** proposal needing approval · **[Open]** owner decision needed.

## 1. Decisions this amendment rests on **[Confirmed]** (owner, 2026-11-18)

1. The Flutter Android and iOS apps are rebuilt from scratch.
2. A separate Super Admin web dashboard is built.
3. The existing Firebase project `citizen-india` stays the production project.
4. All existing Firebase data is preserved: no deletion and no destructive migration.
5. The backend is redesigned to be clean, secure and scalable, and budget-conscious for nationwide use in India.
6. Every previously confirmed and locked feature is retained (section 3).

## 2. Reconciliation with the approved roadmap

| Old roadmap item | Under this amendment |
|---|---|
| Rules for every phase; mandatory version control; evidence files | **Kept unchanged** |
| Phase 1 done so far: git, baseline, private repo, comment and calls removal, build repair, environment recovery | **Kept as history.** The old app is frozen at `1ca3e2e` as the legacy reference |
| Phase 1 open: brand and IDs, keystore, rules/indexes export, full export, Crashlytics, check script | Brand and IDs stay in Phase 1 (D5). Keystore, Crashlytics and the check script **move to Phase 2** (owner ruling, 2026-11-18), matching section 8. The **rules/indexes export and full export are obsolete**: no Firestore database, rules, indexes or Storage bucket exist (07 §4; D16). They are replaced by recording the existing Auth and app-registration configuration (07 §8) |
| Phase 1 "regression on the old app" and "comment removal" | **Dropped**: the old code is not shipped again |
| Phase 2 (accounts) to Phase 7 (payments) | **Replaced** by new Phases 3–8, designed fresh with the same requirements |
| Phase 8 (Super Admin) | **Replaced** by new Phase 9, a separate web app from the start |
| Phase 9 (iOS) | **Replaced**: iOS is built in every phase, and each gate checks both platforms; iOS store work moves to Phase 11 |
| Phase 10 (consolidation of categories) | **Dropped**: the generic category design is built in from the start |
| Phase 11 (release) | **Kept** as new Phase 11. Migration and coexistence are **not routine work** (D16). Their gates apply only as a contingency, if contrary evidence reopens D6 or D8 (§5) |
| Blueprint "Firebase and Hive stay until a migration decision" | Firebase stays. Hive is used only as a local cache in the new app **[Recommended]** |
| Blueprint status line "PLANNING. Not approved" | Inconsistent with the approved roadmap. A correction was **drafted** in 03 on 2026-11-18 on the owner's instruction, and approved by the owner on 2026-11-18 (D11) |

## 3. Locked requirements carried forward

Retained in full; the new design must satisfy each one, and each has an acceptance check in section 9.

| ID | Requirement | Source |
|---|---|---|
| R1 | Android and iOS, one Flutter code base | Confirmed |
| R2 | Phone OTP sign-in | Confirmed |
| R3 | Customer and partner registration; multi-role accounts on one phone number | Confirmed |
| R4 | Logout keeps partner profiles; stops LIVE, marks offline, clears local session data, signs out | Confirmed |
| R5 | Permanent account deletion as a separate feature | Confirmed |
| R6 | No in-app voice or video calls; chat and phone dialler instead | Confirmed |
| R7 | All existing categories (blueprint §2.3), with category-specific workflows | Confirmed list; workflows Required |
| R8 | Location-based discovery; radius set by the partner's subscription | Required; partner-pays Confirmed |
| R9 | Subscriptions paid by partners | Confirmed |
| R10 | Persistent job requests with simultaneous partner matching | Required |
| R11 | Bookings: scheduling, quotations, cancellation, rebooking | Required |
| R12 | Partner availability, LIVE, location privacy | Required |
| R13 | Reviews, verification, support, disputes | Required |
| R14 | Super Admin dashboard with permissions (now a separate web app) | Required |
| R15 | Notifications, analytics, regional expansion (one state first, then India) | Required / Confirmed |
| R16 | Text chat | Recommended to keep |
| R17 | Existing 23 languages | Present in the old app |
| R18 | AI spend at most ₹3,000 a month; infrastructure budget separate | Confirmed |

**Missing specifications.** These are not invented here: each phase starts only after its items are answered or the stated default is accepted.

| Phase | Missing specification | Default if not answered |
|---|---|---|
| 4 | Category-to-workflow assignment (mobile, fixed business, listing) | Blueprint §7 grouping |
| 4 | Fields per category | Old app's fields, reviewed per category |
| 5 | Phone-number visibility; floating bubble; working hours | Hidden until a booking; no bubble; LIVE only |
| 6 | How a request closes (time limit or not); quotations under first-accept-wins; offline-partner notification | none: OPEN (D13); delivery to all eligible partners and first server-side acceptance are stated owner requirements (§4.6) |
| 6 | Quotation categories; cancellation rules; whether the app handles job payment | Optional quotes; free cancellation before start; no job payment |
| 7 | Verification documents per category; dispute owner and response time | Blocking (B5) |
| 8 | Plans, prices, durations; gateway; Google/Apple billing position; subscription per partner profile or per account | Blocking (B4) |
| 9 | Admin feature list, admin count, actions needing a second approver | Blueprint §2.9 list; no second approver |
| 11 | Launch state; launch languages; SMS fallback | Blocking for release |

## 4. Architecture **[Recommended]**

### 4.1 Repository and apps

```
apps/mobile      Flutter app (Android, iOS); flavors: dev (emulator), staging, prod
apps/admin       Flutter web Super Admin, on Firebase Hosting
packages/core    shared models, category catalogue, validation, API client for Functions
firebase/        firestore.rules, storage.rules, firestore.indexes.json, functions/ (TypeScript), rules tests
legacy/          not used: the old app stays in git history at 1ca3e2e
```

- **Mobile app layers:** screens, services, repositories. Only repositories touch Firebase.
- **State:** `ChangeNotifier`/`ValueNotifier` in services, as the blueprint proposed. No new state framework unless decision D9 says otherwise.
- **Dependencies:** each new package is justified and passes the onboarding standard in `05-development-environment.md`.

### 4.2 Environments

| Environment | Project | Purpose |
|---|---|---|
| Local | Firebase Emulator Suite | Development and all rules/Functions tests; free |
| Staging | New project, for example `citizen-india-staging` (decision D3) | Device testing with test users and test payments; never real user data |
| Production | `citizen-india` (existing) | Real users only after the Phase 11 gate |

Nothing from the rebuild is deployed to production before Phase 11, except read-only inspection and the Phase 1 export.

**Billing (to verify against current Firebase pricing):**
- Cloud Functions, Cloud Scheduler, Secret Manager and managed Firestore export/backup are believed to need the Blaze plan, in staging as well as production.
- Phone-auth SMS may also need billing; staging uses Firebase test phone numbers, so no SMS is sent.
- Each project gets its own budget and alerts (D4).

**Staging data:** synthetic data only, unless you approve a masked copy (OPEN).

### 4.3 Data model

New collections use names the old app never uses, so old and new data cannot collide. Reserved legacy names (45 in code, from the audit): every provider collection, the category collections, `liveLocations`, `conversations`, `messages`, `rideRequests`, `driverRequests`, `users`, `clinicUsernames`.

| Collection | Contents | Written by |
|---|---|---|
| `accounts/{uid}` | roles held, active role, region, language, consent record, status | owner (limited fields), Functions |
| `accounts/{uid}/devices/{id}` | push tokens | owner |
| `partnerProfiles/{profileId}` | public profile: category, workflow type, name, photos, geohash and approximate position, rating summary, verified flag, visibility | owner (public fields), Functions (rating, verified, visibility) |
| `partnerPrivate/{profileId}` | phone, exact address and position, documents | owner; read by owner, matched customer through Functions, admins |
| `presence/{profileId}` | LIVE: geohash, approximate position, `expiresAt` (TTL) | owner while LIVE; Functions |
| `catalog/{categoryId}` | category configuration, workflow type, fields, emergency radius | admin through Functions |
| `plans/{id}`, `subscriptions/{profileId}`, `paymentOrders/{id}` | plans, paid state and radius, payment records | Functions only |
| `jobRequests/{id}` with `recipients/{profileId}` | request and fan-out list | customer creates; Functions fan out and expire |
| `bookings/{id}` with `events/{id}` | booking state machine and history | Functions (state), parties (messages) |
| `chats/{id}/messages/{id}` | text chat between booking parties | participants only |
| `reviews/{bookingId}` | one review per completed booking | customer once; aggregates by Functions |
| `verifications/{id}`, `tickets/{id}`, `reports/{id}` | verification, support, disputes, report/block | owner creates; admins decide through Functions |
| `notifications/{uid}/items/{id}` | in-app notification list | Functions |
| `config/{id}`, `auditLog/{id}`, `legacyLinks/{uid}` | regions and flags, admin audit trail, old-to-new mapping (`legacyLinks`: contingency only, D16) | Functions only |

Same Firebase project means the same Auth users, so a phone number keeps its UID in the new app.

### 4.4 Security

- **Combined ruleset:** one rules file serves the whole database, and rules combine with OR. So:
  - Legacy collections keep explicit per-collection `match` blocks that reproduce today's behaviour (copied from the console, unchanged).
  - Any catch-all `match /{document=**}` is replaced by those explicit blocks, because it would also open the new collections.
  - Emulator tests prove both legacy compatibility and new-collection denial.
  - Alternative: a separate named database (D12).
- **Firestore rules:** deny by default, with server-only collections closed to clients. Owners write only their own allowed fields; private data is in separate documents, never in public ones.
- **Rules tests:** every collection has emulator tests, including cross-user denial.
- **Storage:** owner-only paths per profile, with type and size limits; files are deleted with the profile or account.
- **App Check:** Play Integrity on Android, App Attest on iOS, reCAPTCHA Enterprise for admin. Monitor first, then enforce.
- **Admin:** roles as custom claims (super admin, admin, support, read-only), a second sign-in factor, and every privileged write through Functions with an audit-log entry.
- **Secrets:** the payment secret and webhook key in Secret Manager. API keys restricted by app. No coordinates, UIDs or phone numbers in release logs.

### 4.5 Cloud Functions and APIs

Region: the same as the Firestore database. No location is set yet (verified, 07 §4), so the region is a choice (D2, OPEN; 08 recommends `asia-south1`). Functions in `asia-south1` and `asia-south2` are 2nd gen only (verified, 08 §13). Functions need the Blaze plan (D4).

| Kind | Functions |
|---|---|
| Callable | `completeRegistration`, `switchActiveRole`, `submitProfile`, `goLive`/`goOffline`, `createJobRequest`, `respondToRequest`, `confirmBooking`, `cancelBooking`, `rebook`, `revealContact`, `submitReview`, `submitVerification`, `openTicket`, `createPaymentOrder`, `requestAccountDeletion`, admin actions (`importLegacyProfile` only as a contingency, D16) |
| HTTP | payment webhook (signature verified); public account-deletion page backend |
| Triggers | fan-out on new request; booking state notifications; rating aggregates; Storage clean-up |
| Scheduled | expire requests and subscriptions; clear stale presence; daily Firestore export; usage and cost report |

### 4.6 Domain designs (summary)

- **Account lifecycle**
  - Sign-in is OTP, followed by an account record and then roles.
  - Logout follows R4 exactly: LIVE off, offline, local cache cleared, sign out. Nothing is deleted.
  - Deletion follows R5: OTP re-check, then a Function deletes or anonymises the account's new-model data, files and Auth user.
  - No legacy documents or files exist (verified in 07; D16 owner-confirmed). Retention obligations under the DPDP Act and store rules still apply to new-model data (D7, legal input needed). If legacy data were ever found, it would follow a separately approved retention policy.
- **LIVE:** a foreground service on Android and background location on iOS. Uploads on movement of 30 m or every 60–90 seconds, with expiry at three heartbeats. A TTL policy removes old records, and every reader checks expiry. Customers see an approximate position until a booking.
- **Discovery:** two separate radii.
  - The **customer search radius** is chosen by the customer within limits set in `config`.
  - The **partner eligibility radius** comes from the partner's server-side subscription entitlement.
  - A partner is shown, or receives a request, only if the distance is within **both** (OPEN, D13). Emergency categories use a fixed radius.
  - Queries: geohash ranges on `presence` and `partnerProfiles`, paginated, with exact distance computed on the device. Reads per search are capped and measured.
- **Request lifecycle** (requirements as stated in the owner's review, 2026-11-18). These replace blueprint §11's "cap" and "customer chooses" defaults, pending your confirmation (D13):
  1. **Broadcast:** a Function delivers the request to **all** eligible partners. Each recipient is recorded in `recipients/{profileId}`, which makes delivery idempotent.
  2. **Acceptance:** the **first valid acceptance processed by the server wins**. A transaction sets the accepted partner and closes the request; later acceptances are rejected with a clear message.
  3. **Expansion:** if the customer widens the radius, only partners newly within range are added and notified. Partners already recorded are never notified twice.
  4. **States:** `open` until `accepted`, `cancelled` by the customer, or `closed`. Who may close, and whether a time-based close exists, is OPEN (D13).
  5. **Quotations** combined with first-accept-wins is OPEN (D13).
- **Bookings:** created by the accepting transaction. Contacts are revealed only to the matched pair.
- **Notifications and chat:** FCM through Functions, each state change also recorded in the in-app list. Payloads and chat never carry a phone number, an exact address or document data; those come only from `revealContact`. SMS is used only for OTP unless D10 adds a fallback.
- **Subscriptions and payments:**
  - An order is created on the server, then checkout, then the webhook signature is verified, and only Functions write `subscriptions`.
  - Entitlements are enforced on the server: discovery and fan-out read `subscriptions`, never the client.
  - Each subscription stores a snapshot of its plan (price, radius, duration), so later plan or price changes never alter an active entitlement.
  - Store-billing rules decide the payment path (B4).
- **Admin:** section 4.4, plus a verification queue, suspensions, categories, plans, regions, tickets and disputes, users and partners, the audit log, and analytics.

### 4.7 Cost controls (nationwide India)

- **No unbounded reads:** no whole-collection reads or unbounded listeners. Listeners only on single documents.
- **Counts:** aggregate count queries, or counters written by Functions.
- **LIVE:** the write rate set in 4.6, plus TTL.
- **SMS:** the region policy limited to India, and abuse limits on OTP.
- **Images:** resized before upload and cached on the device.
- **Budget:** alerts from day one, a monthly cost report, and cost per active user measured before launch.
- **Measurable controls:**
  - AI spend stays at or below ₹3,000 a month, recorded monthly in the evidence file.
  - Each Firebase project has a budget with alerts at 50%, 90% and 100% of a ceiling you set (OPEN).
  - Reads per search, LIVE writes per hour and SMS per day have limits you approve before Phase 6, measured on staging.
  - A staged cost estimate (pilot district, one state, national) is produced from current pricing and your volume figures before Phase 3 (OPEN: volumes).

## 5. Coexistence with old installs and old data **[Recommended]**

**Verified 2026-11-18 (07 §4):** `citizen-india` holds no Firestore, Storage, rules or backend; old installs cannot work against it. The plan for `citizen-india` is therefore:
- (a) create no database or bucket until the Phase 3 deny-by-default rules (which also deny every legacy collection name) are deployed with it;
- (b) enforce App Check before launch, which locks out old builds;
- (c) keep the one Auth user and the app registrations.

D16 is OWNER CONFIRMED (2026-11-18): there are no historical production users or data. Items 1–5 below are therefore **not planned work**. They are kept only as a contingency, to be reopened through a separately approved migration plan if contrary evidence appears.

1. **Old collections are never written or deleted by the new app.** The new rules leave every legacy collection's rules unchanged until the old app is retired, because tightening them would break old installs.
2. **Legacy hotfix (decision D6).** If old installs exist, the old app's logout deletes profiles (audit A2; 07 §6 S1) and its rules are probably permissive (F2).
   - Unpublishing the store listing does **not** stop installed copies; they keep running against production.
   - Option A: a minimal hotfix release that removes the deletions. It only reaches users who update.
   - Option B: unpublish and accept the remaining installs.
   - Option C: a server-side change to legacy rules that blocks the deletes. It stops data loss even for non-updated installs, but may break their logout; test in the emulator first.
   - Whatever the choice, a full backup (§6) is taken first.
3. **Profile import is a copy, chosen by the user.**
   - When a phone number signs in to the new app and owns old provider documents, `importLegacyProfile` offers to copy each one into the new model.
   - Copied data is checked and normalised, and the link is recorded in `legacyLinks`.
   - The originals are left untouched.
4. **Batch back-fill** of non-claimed profiles happens only if you approve it, after a fresh export, on staging first, with a documented rollback.
5. **Retiring the old app:** once the new app is in production, the old app is unpublished. The old app has no remote kill switch, so installed copies stop only when they update to a final legacy release that shows "please install the new app" (it reaches only updated installs), or when legacy rules are tightened (this breaks non-updated installs) (part of decision D6).
   - Legacy rules are tightened to read-only only after you approve it.
   - Legacy data is archived, never deleted, until you decide otherwise.

## 6. Gates that apply across phases **[Recommended]**

| Gate | Condition |
|---|---|
| Staging | Every feature runs on staging, on real Android and iOS devices, before its phase closes |
| Backup | Before any production change, a backup exists covering: Firestore documents (managed export); indexes, TTL and rules (in the repo); Auth users (approved, encrypted `auth:export`) and Auth configuration; Storage objects (bucket copy), rules and bucket settings; app registrations and SDK configuration; IAM metadata. One restore into staging has been demonstrated with reconciled counts (07 §8) |
| App registration | New Android, iOS and web apps are registered in production only with your written approval, recorded in the evidence file |
| Production deployment | Every deployment of rules, indexes, Functions or Hosting to `citizen-india` needs your written approval per release, a backup taken that day, and a rollback plan |
| Testing | Unit, widget, rules and Functions tests pass in CI, alongside analyze and format checks; the regression set from earlier phases passes |
| Security | Rules tests cover every collection; no secrets in git; release logs clean |
| Migration | Not expected (D16). If a migration is ever approved, it is tested in staging on a copy, counts reconcile and originals stay unchanged |
| Production | Deployment to `citizen-india` only from the repository, only after your sign-off, with a rollback plan |

## 7. Store readiness

**Android:**
- Final application ID and a release keystore outside the repo, with Play App Signing.
- Target API at Play's current requirement.
- Data Safety form; background-location declaration with a demo video; foreground-service type declared.
- Only the permissions that are needed, each justified.
- In-app and web account deletion.
- Policy and terms links.
- Closed test, then staged rollout.

**iOS:**
- Bundle ID (D5) and an Apple Developer account (B6).
- APNs key; App Attest; usage descriptions for location, camera and photos; the background location mode justified.
- Privacy manifest and nutrition labels.
- Account deletion.
- Store-billing review for subscriptions (B4).
- TestFlight, then App Review.

**Both:** an accessibility pass; supported OS versions recorded; crash-free sessions measured in closed testing.

## 8. Phases, modules and acceptance criteria

Each phase follows the roadmap rules: tests actually run, evidence saved, commit pushed and verified, and your sign-off. Every acceptance criterion is met only when `docs/people-bridge/evidence/phase-N.md` holds the command or test run, its output, and the device or project it ran on. "Not run" is recorded as not run.

| Phase | Name (modules) | Depends on | Priority |
|---|---|---|---|
| 1 | Foundation and data safety (revised) | D5 (working name only; D2, D3, D4, D15 and D17 deferred by the owner on 2026-11-18; see §11) | Critical |
| 2 | New project skeleton and platform | 1; D5 (ID approach and IDs) | Critical |
| 3 | Backend core: rules, Functions, accounts, backup | 2; D2, D3, D4, D17 (deferred to here) | Critical |
| 4 | Auth, roles, account lifecycle | 3 | Critical |
| 5 | Categories, partner profiles, media | 4 | High |
| 6 | LIVE, presence, discovery | 5 | High |
| 7 | Requests, bookings, chat, notifications | 6 | High |
| 8 | Trust: reviews, verification, support, disputes | 7; B5 | High |
| 9 | Super Admin web | 3; grows with 5–8 | High |
| 10 | Subscriptions and payments | 6, 9; B4 | High |
| 11 | Full-system test and release (legacy coexistence: contingency only, D16) | all; B6, B7 | Critical |

**Phase 1: Foundation and data safety (revised)**
- Deliverables:
  - D5:
    - Working app name recorded: People Bridge (provisional). The final brand is confirmed at the final branding and release stage.
    - The Android package ID and iOS bundle ID must be decided **before any app registration or store/production release**.
    - **OPEN, owner approval required before any Phase 2 app registration:** whether (a) brand-independent final IDs are chosen, or (b) provisional IDs are used and finalised before store or production registration. Not a Phase 1 closure criterion.
  - Read-only inspection of the Firebase project completed with authenticated access (done 2026-11-18, 07 v2). Billing, App Check and API-key restrictions: OWNER-APPROVED DEFERRED (2026-11-18), not verified; to be checked by the owner in the console and recorded in 07 before Phase 3 creates any resource. Not a Phase 1 closure criterion.
  - D16 answered: no historical production users or data (owner, 2026-11-18).
  - The existing Auth configuration and Firebase app registrations recorded in the repository, as documented in 07 §4 and §8: sign-in providers, SMS region policy, test-number count, authorized domains, the three app IDs, Analytics link, Hosting site and IAM roles. No user data or secrets; the one Auth user stays untouched (D15).
  - Staging project created, **only if D3 and D4 are approved**. *(Deferred to Phase 3 by the owner, 2026-11-18.)*
  - This amendment approved (D1). *Done 2026-11-18.*
- Acceptance: the configuration record matches a fresh read-only inventory taken the same day, saved in the evidence file; inspection results recorded in the evidence file.
- *Contingency only, not Phase 1 deliverables:*
  - legacy rules export, full legacy export and a legacy hotfix decision;
  - these apply only if contrary evidence reopens D16, D6 or D8 (§5).

**Phase 2: New project skeleton and platform**
- Deliverables:
  - The section 4.1 layout and flavors.
  - Final app IDs registered in the staging and production Firebase apps (production: register only; no data change).
  - Release signing.
  - CI running analyze, format, test and build.
  - Crashlytics, App Check in monitor mode, the design system, and the 23 languages ported.
- Acceptance: release builds for both platforms install on real devices; CI is green; cold start under 3 seconds on a mid-range Android phone; analyze shows 0 warnings.

**Phase 3: Backend core**
- Deliverables:
  - Rules framework with a test harness.
  - Functions project in the chosen region.
  - `accounts`, `config` and `auditLog`.
  - Daily export with a demonstrated restore into staging.
- Acceptance: rules tests are 100% passing with a cross-user denial case per collection; a restore is demonstrated; Functions deploy to staging from CI.

**Phase 4: Auth, roles, account lifecycle**
- Deliverables: OTP sign-in, multi-role with one active role, the R4 logout, R5 deletion (in-app and web), and consent recording.
- Acceptance:
  - OTP works on Android and iOS real devices.
  - After logout the profile still exists.
  - After deletion the account's new-model documents, files and Auth user are gone.
  - Old collections are untouched (counts identical before and after).

**Phase 5: Categories, partner profiles, media**
- Deliverables:
  - A catalog-driven generic partner module covering all categories in the three workflow types.
  - Public/private split.
  - Media upload with limits.
  - Verification submission.
- Acceptance: every category in R7 can register on staging; a second user cannot read private fields (rules test plus a manual check); images under the agreed size.

**Phase 6: LIVE, presence, discovery**
- Deliverables: LIVE on Android and iOS, presence with TTL, geohash discovery with pagination, and the subscription radius stub (plan-driven in Phase 10).
- Acceptance:
  - Zero whole-collection reads (code search plus measured reads).
  - Reads per search and writes per LIVE hour recorded and within limits you approve.
  - Expired partners never shown.
  - No dropped frames on a 200-item list.

**Phase 7: Requests, bookings, chat, notifications**
- Deliverables: the section 4.6 flows, push plus the in-app list, chat limited to booking parties, and contact reveal.
- Acceptance: a concurrency test yields exactly one confirmed booking; each state change produces exactly one notification per party; the contact is revealed only to the matched pair (rules test).

**Phase 8: Trust**
- Deliverables: reviews with server aggregates, the verification workflow, tickets and disputes, report and block.
- Acceptance: self-verification and rating tampering fail in rules tests; a suspended partner is absent from search within one refresh.

**Phase 9: Super Admin web**
- Deliverables: the section 4.6 admin scope, custom-claim roles, a second factor, and the audit log.
- Acceptance: permission-matrix tests pass for all four roles; every admin action in the test run has an audit-log entry.

**Phase 10: Subscriptions and payments**
- Deliverables: plans, server orders, the verified webhook, server-side expiry, plan-driven radius, and renewal reminders.
- Acceptance: tamper tests (clock change, forged webhook, direct client write) all fail; test-mode payment evidence saved; the store-billing position documented.

**Phase 11: Full-system test and release** *(legacy coexistence and migration: contingency only, D16)*
- Deliverables:
  - Legacy import not required (D16). If contrary evidence appears, a separately approved migration plan is added here.
  - The legacy retirement plan.
  - Full regression on Android 10 to current and supported iOS versions.
  - A load and cost check at launch-state volume.
  - A security review and an accessibility pass.
  - Store listings and declarations; closed tests; staged rollout.
  - Production deployment from the repo, after your sign-off.
- Acceptance:
  - Zero open critical or high defects.
  - No legacy migration was run (D16); `citizen-india` was inventoried before and after deployment, and only the approved resources were added.
  - Both stores accept the builds.
  - Rollback rehearsed.
  - You approve the release.

## 9. Requirement-to-acceptance map

R1 → every gate on both platforms · R2, R3, R4, R5 → Phase 4 · R6 → no call code or call permissions (Phase 2 review) · R7 → Phase 5 · R8 → Phases 6 and 10 · R9 → Phase 10 · R10, R11, R16 → Phase 7 · R12 → Phase 6 · R13 → Phase 8 · R14 → Phase 9 · R15 → Phases 7, 9 and 11 · R17 → Phase 2 · R18 → one module per session, as in section 10.

## 10. Effort and AI budget

One module per session. The old code is used only as a reference for behaviour and field lists, never copied wholesale. Graphify is rebuilt after each module. Session estimates come after Phase 2, once the skeleton exists.

## 11. Decision register (authoritative IDs)

This table is the **single authoritative list** of People Bridge decision IDs (since 2026-11-18).
- Old numbers in the roadmap and blueprint ("decision 1–7") are aliases, shown in the second column.
- Recommendations for each decision are in [08](08-consolidated-decision-report.md) §3 and §10.
- **No decision here is owner-approved unless its status says OWNER CONFIRMED, OWNER APPROVED or OWNER DECISION.** "Deferred by the owner" means the decision is still OPEN, with a later deadline.

| ID | Alias | Decision | Status | Needed by |
|---|---|---|---|---|
| D1 | — | Approve this amendment (replaces roadmap Phases 2–11; revises Phase 1) | **OWNER APPROVED 2026-11-18** (v0.5) | done |
| D2 | old 2 (part) | Firestore and Storage region (none set; permanent once chosen; `asia-south1` or `asia-south2`); console checks of billing, App Check and API keys | OPEN, **deferred by the owner (2026-11-18) to Phase 3, before database creation** (08 recommends `asia-south1`). The console checks are OWNER-APPROVED DEFERRED / NOT VERIFIED | Phase 3 |
| D3 | — | Separate staging Firebase project (Blaze likely needed; §4.2). Nothing is created until you approve | OPEN, **deferred by the owner (2026-11-18) to Phase 3** (08 recommends yes) | Phase 3 |
| D4 | — | Blaze on `citizen-india` (and staging) with a budget ceiling and alerts (alerts do not cap spending) | OPEN, **deferred by the owner (2026-11-18) to Phase 3**; any billing change needs explicit owner approval | Phase 3, before any resource is created |
| D5 | old 1 | Brand name, Android package ID, iOS bundle ID.<br>Working name **People Bridge (provisional)** (owner, 2026-11-18); the final brand is confirmed at the final branding and release stage.<br>Undecided: package ID, bundle ID, legal entity, owned domain.<br>Sub-question OPEN: (a) brand-independent final IDs in Phase 1, or (b) provisional IDs finalised before store or production registration | OPEN (partly clarified 2026-11-18) | before Phase 2 app registration for the ID approach; IDs before any app registration or release; brand at the release stage |
| D6 | — | Legacy app hotfix: **not needed** (D16; deny-by-default rules plus App Check lock old builds out). Reopen only on contrary evidence | closed unless reopened | — |
| D7 | — | Data retention and deletion policy (DPDP Act, store rules; legal input). Legacy data: none (D16) | OPEN (08 proposes defaults) | Phase 4 |
| D8 | — | Legacy profile import: **not required** (D16). Contingency only | closed unless reopened | — |
| D9 | — | State management (built-in `ChangeNotifier`/`ValueNotifier` by default, or a named framework) | **OWNER APPROVED 2026-11-18:** built-in Flutter state management for the initial build; a framework only by a later owner decision | Phase 2 |
| D10 | — | OTP delivery and SMS fallback (Firebase Phone Auth; possible DLT route; voice or WhatsApp fallback) | OPEN (08 recommends Firebase now, DLT route before a state launch) | Phase 4 |
| D11 | — | Documentation consistency (blueprint status; superseded sections; CLAUDE.md; numbering) | **OWNER APPROVED 2026-11-18** (corrections drafted on the owner's instruction and committed in `5a5cadd`) | done |
| D12 | — | Default database or a named database | OPEN (08 recommends default) | Phase 3 |
| D13 | — | Request rules in §4.6 (OPEN points: late-eligible partners; who may close a request and whether a time limit exists; quotations under first-accept-wins; request caps) | OPEN | Phase 6 |
| D14 | — | Number recycling and change-number policy (07 §7.1; 08 D14) | OPEN | Phase 4 |
| D15 | — | The one existing Auth user. Metadata verified read-only (08 D15): phone provider, a configured **test** number, no email or name, created 2026-08-10. It stays untouched (no export, edit or deletion) until you decide | **OWNER DECISION 2026-11-18:** leave untouched; identification deferred until a justified review | at a justified review |
| D16 | old 2 (part) | Historical production users or data | **OWNER CONFIRMED 2026-11-18:** none. Revisit only on contrary evidence | closed |
| D17 | — | Firebase Extensions API enabled during the read-only check (07 §3): keep (option A) or disable (option B, 08 D17). It stays unchanged until you explicitly approve | **OWNER DECISION 2026-11-18:** leave enabled and unchanged; assessment (option A or B) before Phase 3 | before Phase 3 |
| B3 | old 3 | Privacy policy and terms text; the publishing legal entity | OPEN | Phase 3 of the old roadmap / Phase 4 here |
| B4 | old 4 | Plans, prices, durations; payment path (Play Billing / Apple IAP or a gateway); per-profile or per-account subscription; radius meaning | OPEN | Phase 10 |
| B5 | old 5 | Verification documents per category | OPEN | Phase 8 |
| B6 | old 6 | Google Play and Apple Developer accounts and their holder | OPEN | Phase 11 (Apple earlier for TestFlight) |
| B7 | old 7 | Launch state, and the pilot district | OPEN | Phase 11 |

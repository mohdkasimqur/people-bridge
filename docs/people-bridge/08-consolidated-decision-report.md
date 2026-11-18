# People Bridge — Consolidated Architecture, Firebase, Budget and Product Decision Report

Version 1.3, 2026-11-18. **Status: RECOMMENDATIONS for owner review.** Only D1, D9 and D11 have been approved by the owner (2026-11-18; §10). Nothing is implemented. Phase 1 is OPEN; Phase 2 is NOT approved.

Change history:
- **v1.1:** the §9 D11 corrections were drafted in the documents, awaiting owner review; decision IDs follow the authoritative register in 06 v0.5 §11. The recommendations in this report did not change. *(Clarified in v1.2: v1.1's "no recommendation changed" refers only to this report. 06 v0.5 did change two decision rows from v0.4; see below.)*
- **v1.2:**
  - Records that 06 v0.5 changed **D4** ("Needed by": Phase 3 → Phase 1, before any resource is created) and **D10** (scope: SMS fallback for critical notifications → OTP delivery and SMS fallback; Phase 7 → 4), and reworded D13 and D14 without changing their meaning (06, "Changes in v0.5"). These changes align 06 with this report's §3 recommendations; none is an owner approval.
  - Current references to 06 now point to v0.5.
- **v1.3 (2026-11-18):** records the owner's approvals of **D1** (06 v0.5), **D9** (built-in Flutter state management, initially) and **D11** (documentation corrections). Every other status is unchanged. This is not Phase 1 sign-off; Phase 2 stays blocked.
Inputs: `CLAUDE.md`, documents 01, 03, 04, 05, 06 (v0.4) and 07 (v3), one read-only Auth metadata query, and the official sources in §13.
Labels: **VERIFIED** (official source or live read) · **ESTIMATE** · **RECOMMENDED** · **OPEN** · **OWNER APPROVAL REQUIRED**.

## 1. Executive recommendation

1. **Keep `citizen-india` as production and put it on Blaze.**
   - Cloud Storage, Cloud Functions, phone-auth SMS, Firestore backups and PITR, and any second database all need billing (VERIFIED, §13).
   - Budget alerts **do not stop spending** (VERIFIED).
   - Spend caps exist only for Cloud Functions for Firebase, Extensions, App Hosting and AI Logic (VERIFIED). Firestore, Storage and SMS have no cap, so App Check, quotas and bounded queries are the real protection.
2. **Firestore and Storage in `asia-south1` (Mumbai); Functions 2nd gen in the same region.** Both Indian regions are supported. The choice is permanent.
3. **A separate staging project on Blaze**, plus the Emulator Suite for most tests.
4. **The default Firestore database** (one free-quota database per project; nothing exists yet).
5. **Budget reality (ESTIMATE, §6):**
   - Infrastructure other than SMS fits ₹2,000–5,000 a month through the pilot.
   - **Phone OTP SMS dominates cost.** The official India rate is **US$0.07 per SMS** after 10 free a day (VERIFIED through Google's localized pricing pages; confirm in the console).
   - A one-state launch is likely ₹1 lakh or more a month, mostly SMS, unless OTP volume is kept low or a cheaper DLT SMS route is adopted (D10).
6. **Stores:** partner subscriptions sell an in-app digital benefit (visibility and request eligibility). That most likely requires **Google Play Billing and Apple in-app purchase**. Customer-to-partner job payments are physical services and stay outside the app. Needs your approval and a store-policy check (§4).
7. **Owner decisions needed now:** listed in §11 (eight items).

## 2. Verified baseline (from 07 v3 and today's read)

- **Project:** `citizen-india` (897017107721), ACTIVE. There is no Firestore, Storage, rules, Functions, Realtime Database or extension, and no resource location is set.
- **Auth:** phone only; SMS allowlist India; 2 test numbers; **1 user** (D15). Analytics is linked with 3 streams. Hosting has a site and no releases. 3 app registrations under `com.example` IDs, with no Android SHA fingerprints.
- **APIs:** the Firebase Extensions API is enabled (unintentionally, 2026-11-18). Billing, App Check, API Keys and Cloud Run APIs are disabled, so those settings were not read.
- **Owner-confirmed (D16):** there were never real production users or data.

## 3. Decisions D2–D17

### D2 — Region: RECOMMENDED `asia-south1` (Mumbai)

| Factor | `asia-south1` Mumbai | `asia-south2` Delhi | Evidence |
|---|---|---|---|
| Firestore | regional, supported | regional, supported | VERIFIED (Firestore locations) |
| Cloud Functions | 2nd gen only, Tier 2 | 2nd gen only, Tier 2 | VERIFIED (Functions locations) |
| Location change later | impossible | impossible | VERIFIED |
| Latency across India | no published comparison | no published comparison | **No evidence either way**; not claimed |
| Price | regional price; check in the console SKU list | same | OPEN: regional rates not retrieved |
| Data residency | in India | in India | both meet any India-residency preference |
| DR pairing | Delhi as the backup and export region | Mumbai as the backup region | RECOMMENDED |

- **Why Mumbai:** it is Google's longer-established Indian region. Choosing it keeps Delhi free as an independent region for backup and export copies.
- **Gaps:** this is a judgement, not a measured latency or price advantage. Before you approve, two checks are recommended:
  - compare asia-south1 and asia-south2 prices in the Cloud console SKU list;
  - confirm Cloud Scheduler is available in the chosen region.
- **Must match the Firestore region:** Storage bucket, Functions, Scheduler.
- **Cannot be changed in place:** the Firestore location, and the default bucket location.

### D3 — Staging: RECOMMENDED a separate Blaze project plus the emulator

- **Emulator Suite (free):** rules tests, Functions unit and integration tests, Firestore data logic, CI.
- **Real staging project** (for example `citizen-india-staging`), needed for anything the emulator cannot prove:
  - App Check with Play Integrity and App Attest;
  - real-device phone auth with test numbers;
  - FCM delivery;
  - store test builds;
  - Storage with real devices;
  - scheduled Functions;
  - backup and restore drills.
- **Isolation:**
  - separate project and separate billing budget;
  - separate app registrations (`…staging` app IDs);
  - separate service accounts and CI deploy targets;
  - synthetic data only;
  - production deploys only from tagged releases, with your approval.
- **Cost:** ESTIMATE ₹0–500 a month (mostly within free tiers; SMS avoided with test numbers).

### D4 — Billing: RECOMMENDED Blaze on both projects, with budgets and controls

- **Spark cannot run the planned app** (VERIFIED): Storage (required since 3 Feb 2026), Functions, phone-auth SMS, Secret Manager, Firestore backups, PITR and restore all need billing.
- **Controls, because alerts don't stop spending:**
  - budgets with alerts at 50%, 90% and 100%;
  - a spend cap on Functions;
  - App Check enforced;
  - per-user rate limits in Functions;
  - bounded queries;
  - the SMS region allowlist (already India-only);
  - a monthly cost report.
- **Optional:** a programmatic billing-disable switch for staging only.

### D12 — Database: RECOMMENDED the default database

- **Cost:** exactly one database per project gets the free quota, and extra databases need billing (VERIFIED).
- **Simplicity:** the default database has the simplest tooling. Rules, indexes, Functions triggers, backups and emulator all default to it.
- **No legacy to isolate:** there is nothing to separate from (D16).
- **Scale:** a single database scales to national use; a named database adds no benefit here.

### D15 — Existing Auth user: RECOMMENDED retain as is

- **Read-only metadata** (no identifiers displayed):
  - provider `phone`; India number; **matches one of the 2 configured test phone numbers**;
  - no email, name, custom claims or MFA; not disabled;
  - created 2026-08-10; last sign-in 2026-11-13.
- **Assessment:** a **developer test account** created by test-number sign-in. It holds no data, because no database exists.
- **Recommendation:** keep it unchanged and label it "test" in internal records. Your confirmation is needed only to *use* it. Nothing is deleted or modified.

### D17 — Firebase Extensions API: RECOMMENDED leave enabled until Phase 3, then decide

- **Evidence:** `ext:list` shows no extensions installed. Enabling the API created no resources and has no cost.
- **Disabling it:** no known dependants. Any later `firebase ext:*` command would re-enable it automatically (observed behaviour).
- **Option A (recommended):** leave it enabled and document it. Zero cost, zero risk.
- **Option B:** restore the original state. You would do this in the Google Cloud console:
  1. Open **APIs & Services → Enabled APIs**.
  2. Choose **Firebase Extensions API → Disable**.
  3. Confirm no dependent services are listed.
  4. Re-run `firebase ext:list` only if you accept that it re-enables the API.
- **OWNER APPROVAL REQUIRED** for either option. No action has been taken.

### D5 — Brand and identifiers: OPEN (inputs needed), pattern RECOMMENDED

- **Brand:** "People Bridge" is used in the project documents. "Citizen India" (Firebase display name) and "Jober India" (current app label) also appear.
- **Recommendation:** one brand everywhere. If it is "People Bridge":
  - Android package and iOS bundle ID: `<reverse-domain-you-own>.peoplebridge`, identical on both platforms, all lowercase. For example, `in.<yourcompany>.peoplebridge` if you own `<yourcompany>.in`.
  - Staging: the same ID with `.staging` appended.
  - Admin web: a Hosting site with a custom domain.
- **Rules:**
  - Both IDs are permanent once published.
  - Avoid `com.example` (Play rejects it).
  - Use a domain you control.
  - Check availability in Play Console and App Store Connect before committing.
- **Needed from you:** brand name, legal entity, and an owned domain. Nothing is registered.

### D7 — Data retention: RECOMMENDED defaults, legal review REQUIRED

- **Law:** DPDP Act 2023 and DPDP Rules 2025 (notified 13–14 Nov 2025, with substantive obligations from 14 May 2027, per legal commentary).
  - Erase data once its purpose is served, unless a law requires keeping it.
  - Keep processing and traffic logs for at least 1 year (Rules, per commentary; **verify the Gazette text**).
- **Stores:** Play and Apple require full account deletion, including user-generated content. Retention is allowed only where legally required, and must be disclosed (VERIFIED).

| Data | Proposed default | Basis |
|---|---|---|
| Account and partner profile | until deletion request; deleted within 30 days of the request | operational; stores |
| Inactive accounts | after 24 months of no sign-in: notify, then delete 30 days later | proposal; legal check |
| Requests and bookings | 3 years after closure, then delete or anonymise | disputes; legal check |
| Chat text | 12 months after the booking closes | operational |
| Chat attachments | 90 days | cost and privacy |
| Payment and subscription records | as tax law requires (commonly cited as 8 years) | **legal advice required** |
| Reviews | deleted with the author's account (Apple expects deletion of user content) | stores |
| Reports and disputes | 3 years after resolution | operational; legal check |
| Verification documents | deleted 90 days after the decision; the decision record is kept | minimisation; legal check |
| Audit logs (admin and security) | 2 years (at least 1 year per the DPDP Rules commentary) | legal |
| Location (LIVE) | expires within minutes (TTL); none kept | minimisation |

Aadhaar numbers must not be stored. Masking and verification options need legal advice.

### D9 — State management: RECOMMENDED built-in `ChangeNotifier`/`ValueNotifier` with constructor injection (OWNER APPROVED 2026-11-18, initially)

| Option | Fit |
|---|---|
| Built-in (`ChangeNotifier`, `ValueNotifier`, `InheritedWidget`) | no dependency; easiest onboarding; testable through constructor injection; matches blueprint §3.2 |
| `provider` | thin wrapper over the built-ins; acceptable if wiring grows |
| Riverpod | strong testability and dependency injection; more concepts to learn |
| Bloc | most boilerplate; best for large teams |

Start with the built-ins and adopt Riverpod only if a measured need appears (approval needed then).

### D10 — OTP and SMS: RECOMMENDED Firebase Phone Auth now; cheaper route as an OPEN decision before a one-state launch

- **Firebase Phone Auth:**
  - US$0.07 per India SMS, with the first 10 SMS a day free (VERIFIED, localized official pages; confirm in the console).
  - Built-in verification and abuse protection (Play Integrity or reCAPTCHA).
  - Region allowlist already set; no DLT work for you.
- **Cost levers:**
  - long-lived sessions, so no OTP on every launch;
  - OTP only at sign-in, re-verification and deletion;
  - test numbers in staging;
  - App Check;
  - per-device and per-number rate limits.
- **Alternative** (OPEN, ESTIMATE ₹0.15–0.30 per SMS, unverified market rate): an Indian SMS provider under TRAI DLT plus a Cloud Function that verifies the OTP and issues a Firebase custom token.
  - Requires: a registered business entity, DLT registration of entity, header and templates, provider contracts, and your own abuse protection.
  - Saves roughly 90% of SMS cost at scale.
- **Fallback:** an automatic retry, then a "call me" voice OTP or WhatsApp OTP via the provider. Both are OPEN and both add cost and contracts.

### D13 — Request and discovery semantics: RECOMMENDED (owner requirements; confirm the OPEN points)

**Data:**
- `jobRequests/{id}` holds: customer UID, category, geohash, approximate point, `searchRadiusKm`, status (`open | accepted | cancelled | closed`), `acceptedProfileId`, `bookingId`, timestamps and `closeReason`.
- The exact location is in `jobRequestsPrivate/{id}`.
- Recipients are `jobRequests/{id}/recipients/{profileId}`, holding `deliveredAt`, `distanceKm` and `response`.

**Eligibility.** All of these must hold, checked by Functions:
- category matches;
- profile active and not suspended;
- availability (mobile: LIVE and not expired; fixed: open);
- subscription active, from server data;
- distance ≤ the partner's entitled radius **and** ≤ the customer's search radius;
- not blocked by the customer;
- the verification policy is met.

**Behaviour:**

| Step | Rule |
|---|---|
| Broadcast | `createJobRequest` stores the request; a trigger queries `presence` and `partnerProfiles` by geohash ranges covering the radius, filters by eligibility, and **creates** a recipient document per partner (a create fails if it already exists, so delivery is idempotent). It notifies each newly created recipient |
| Expansion | `expandRadius(id, newRadius)`: customer only; status `open`; the new radius must be larger. It re-runs the broadcast, and existing recipients are skipped by the failed create, so there is no duplicate push |
| Acceptance | `acceptRequest(id)` is a transaction. It requires status `open`, a recipient document for the caller, and eligibility re-checked. It sets `accepted` and creates the booking atomically. A repeat call by the same partner returns the same result; any other caller gets a "no longer open" error |
| Cancel | customer only, while `open` |
| Close | OPEN: who may close (customer and admin), and whether a time-based close exists |
| Rules | clients cannot write status or recipients. A partner reads a request only if their recipient document exists (`exists()` in rules). Customers read their own |
| Abuse | App Check; a cap on open requests per customer and on requests per day (OPEN numbers); payload size limits; audit of admin closes |

**OPEN:**
- whether partners who become eligible after creation (going LIVE later) also receive open requests;
- how quotations combine with first-accept-wins.

**Acceptance tests:**
- 50 parallel `acceptRequest` calls produce exactly 1 success;
- expanding the radius twice sends no duplicate notifications;
- an ineligible or expired-subscription partner cannot accept;
- a non-recipient cannot read the request (rules test);
- a cancelled or accepted request cannot be accepted.

### D14 — Number recycling and change: RECOMMENDED policy

- **The risk:** a recycled number signs in to the old UID (VERIFIED: phone auth maps one number to one user). Possession of the number alone never unlocks old data after long inactivity.
- **Rules:**
  1. **Dormancy guard:** after 6 months without sign-in (OPEN period), a sign-in lands on a fresh-start screen.
     - Old profiles, chats and bookings stay hidden until a second factor is passed: a recovery email set earlier, or support-verified identity (OPEN).
     - Otherwise the user may start fresh. An admin Function moves the old data to a quarantined account, unlinks the number, and the old data follows the retention rules.
  2. **Number change** while signed in: verify the new number by OTP, then update the phone on the same UID. All roles and data stay.
  3. **Lost old number:** support-assisted recovery with identity proof. An audited admin Function moves the number. Never automatic.
  4. Partner payout and subscription changes need a fresh OTP.
  5. Every recovery action is in the audit log.

## 4. Remaining product and business decisions (all OPEN, OWNER APPROVAL REQUIRED)

| Topic | Recommended default | Needed from you |
|---|---|---|
| Privacy policy and terms | DPDP-aligned notice (purposes, data, retention per D7, rights, grievance officer); hosted on Firebase Hosting; lawyer review | legal entity; grievance contact; lawyer |
| Subscription plans and pricing | plans by visibility and request radius, plus a free basic tier (OPEN); plan snapshot per subscription (06 §4.6) | prices, tiers, durations |
| Payment architecture | partner subscriptions sold in-app through **Play Billing / Apple IAP** (digital feature); job payment between customer and partner outside the app in v1 | approval after a store-policy check; a gateway only if web sales are added |
| Store billing policy | treat subscriptions as digital (Play §2 "service upgrades"; Apple 3.1.1). Physical-service exemptions (Play §3; Apple 3.1.3(e)) cover customers' purchases of real-world services, not partners' visibility | confirmation (optionally a policy consult) |
| Partner verification | per category: driving licence and vehicle registration (mobile and taxi); medical council registration (doctors); drug licence (medical shops); FSSAI (food); otherwise ID plus business proof. Documents in private Storage, admin review, deleted after 90 days | per-category list; who reviews |
| Store accounts | Play Console and Apple Developer as an **organisation** owned by your legal entity (D-U-N-S needed); developers added as users | entity; D-U-N-S; account holders |
| Launch | staging, then a closed test, then one district (pilot), then one state, then national, switched on per region in `config` | pilot district and state |

## 5. Recommended architecture

| Component | Purpose | Cost note | Alternative |
|---|---|---|---|
| Flutter mobile (Android, iOS) | customer and partner app; flavors dev/staging/prod | build only | — |
| Flutter web admin on Firebase Hosting | Super Admin; privileged actions through Functions | Hosting free tier | separate web stack (more code) |
| Firebase Auth (phone) | sign-in; custom claims for admins | SMS per message (D10) | DLT OTP plus custom token |
| Firestore (default, `asia-south1`) | all app data; public and private split | reads, writes, storage; bounded queries | PostgreSQL (rejected; blueprint §3.1) |
| Cloud Storage (same region) | photos, chat media, verification documents | storage plus egress; resize images | — |
| Cloud Functions 2nd gen (same region) | fan-out, acceptance, payments, deletion, admin, schedules | free tier first; spend cap available | — |
| App Check | blocks non-genuine clients (and old builds) | Play Integrity / App Attest | — |
| Security rules plus emulator tests | deny by default; owner fields; server-only collections | free | — |
| FCM | push for requests, bookings, chat | free | SMS fallback (paid) |
| Analytics, Crashlytics, Cloud Monitoring | funnels, crashes, alerts | free tiers; logging volume to watch | — |
| Backups | daily scheduled backups (7 days) plus weekly copy to an `asia-south2` bucket; restore drill | billed per GiB | PITR only |
| Staging and production | separate projects (D3) | small | emulator only (insufficient) |
| CI/CD | GitHub Actions: analyze, format, unit, widget, rules and Functions tests, build; deploy staging on merge; production manually with approval | free minutes for a private repo, limited (verify) | local scripts |

## 6. Budget and cost model (ESTIMATE, INR per month)

**Assumptions:**
- ₹88 per US$ (assumption).
- Firestore at us-central1 list prices: $0.03 per 100k reads, $0.09 per 100k writes. Mumbai rates are not retrieved, so +30% uncertainty is added.
- LIVE heartbeat about 50 writes per LIVE hour.
- A search costs about 60 reads.
- OTP sign-ins counted per month, with 300 free a month (10 a day).
- Excludes payment fees, the map-tile provider (OPEN) and store fees.

| Stage | Users (assumed) | OTP SMS | Firestore | Storage and egress | Functions, backups, logs | **Total excluding SMS** | **Total including Firebase SMS** |
|---|---|---|---|---|---|---|---|
| Development (staging plus production idle) | testers | ₹0 (test numbers) | ₹0–100 | ₹0–100 | ₹0–200 | **₹0–400** | **₹0–400** |
| Pilot district | 300 partners, 3k customers, 1.5k OTP | ₹7,000–8,000 | ₹300–800 | ₹300–1,000 | ₹0–500 | **₹600–2,300** | **₹7,600–10,300** |
| One state | 5k partners, 50k customers, 15k OTP | ₹90,000 | ₹4,000–12,000 | ₹2,000–6,000 | ₹1,000–5,000 | **₹7,000–23,000** | **₹97,000–1,13,000** |
| National growth | 50k partners, 500k customers, 120k OTP | ₹7.4 lakh | ₹40,000–1.2 lakh | ₹15,000–60,000 | ₹10,000–40,000 | **₹65,000–2.2 lakh** | **₹8–9.6 lakh** |

**What follows:**
- The ₹2,000–5,000 budget holds for development and the pilot **excluding SMS**.
- SMS needs either low OTP volume or the D10 DLT route. At ₹0.15–0.30 per SMS (ESTIMATE), one-state SMS would be about ₹2,250–4,500.
- All figures are ±50%. Measure on staging before Phase 6 (06 §4.7).
- AI subscription: at most ₹3,000 a month, tracked monthly. It is separate from infrastructure.

## 7. Security and privacy requirements (summary; detail in 06 §4.4)

- **Rules:** deny by default, with emulator tests for every collection; public and private documents split; contact revealed only to the matched pair.
- **Admin:** custom claims; second factor; audited Functions for every privileged write.
- **App Check:** monitor mode, then enforced before launch.
- **Abuse limits:** OTP and request rate limits.
- **Storage:** owner-only paths; type and size limits.
- **Data handling:** no personal data in logs or notifications; deletion within 30 days (D7); retention disclosed; DPDP notice and consent; grievance officer.
- **Keys:** API keys restricted (verify in the console); secrets in Secret Manager.

## 8. Store compliance (VERIFIED requirements; approval never guaranteed)

- **Account deletion:**
  - Play: in-app path **and** a web deletion link; Data Safety answers.
  - Apple: in-app initiation; full account and content deletion; disclose retained data; warn about active subscriptions.
- **Phone OTP:** no extra Apple login option needed while login is phone-only (4.8 covers third-party or social login).
- **Location:** background location needs a Play declaration and video, and Apple justification. Request it only at LIVE start, after a disclosure.
- **Subscriptions:** Play Billing / Apple IAP for digital features (§4).
- **Privacy:** Data Safety form; Apple privacy labels and privacy manifest; working policy links.

## 9. Dependency and risk register

| Risk | Impact | Mitigation | Owner input |
|---|---|---|---|
| SMS cost at scale | budget overrun | D10 levers; DLT route; alerts | D10 |
| Wrong region (permanent) | latency, cost | D2 checks before creating the database | D2 |
| No spend cap on Firestore, Storage, SMS | bill shock | App Check, rate limits, bounded queries, budget alerts, monitoring | D4 |
| Store billing classification | rejection or redesign | treat as digital; policy check | §4 |
| DPDP obligations from May 2027 | legal exposure | D7, consent, grievance officer, lawyer | legal |
| Number recycling | account takeover | D14 | D14 |
| Brand and IDs undecided | blocks Phase 2 | D5 | D5 |
| Documentation inconsistencies | wrong guidance to sessions | D11 corrections | D11 |
| Extensions API enabled | none functional | D17 | D17 |

**D11 — inconsistencies found.** Corrections were **drafted on 2026-11-18 on the owner's instruction** in 03, 04, 05, 06 and `CLAUDE.md`, and were **approved by the owner on 2026-11-18** (committed `5a5cadd`). Numbering is unified in 06 §11.
1. **Blueprint status:** it says "PLANNING. Not approved", but the roadmap was approved on 2026-11-15. Set it to "Approved; amended by 06 when approved".
2. **Blueprint content now superseded:**
   - §4.2 migration and §11 "existing data" (D16: none).
   - §11 request defaults ("cap" and "customer chooses"), now replaced by D13.
   - §3.6 "admin in the same repository" (keep; consistent).
3. **Roadmap Phase 1:** "rules/indexes export from console" and "full Firestore export" are moot (nothing exists). Replace them with the 06 v0.5 Phase 1 list (06 §8; unchanged from v0.4). *(Drafted in 04 on 2026-11-18; approved by the owner on 2026-11-18, D11.)*
4. **CLAUDE.md:**
   - "Phase 1 items still blocked on … Firebase console access" is resolved (access verified 2026-11-18).
   - "Ponytail … not restored, source unknown" is wrong: the `ponytail@ponytail` 5.3.3 plugin is now installed from `github.com/DietrichGebert/ponytail`.
   - Documents 06, 07 and 08 are not listed.
5. **05 doc:**
   - The Ponytail row (BLOCKED) is out of date.
   - Add the Firebase plugin (MCP), whose write tools must not be used without approval.
   - Add a Firebase CLI login row.
6. **Numbering:** the roadmap's "decisions 1–7" and the amendment's D1–D17 overlap. Use one D-number list (06 §11) and mark old numbers as aliases.

## 10. Consolidated decision matrix

| ID | Topic | Recommended choice | Reason | Cost impact | Risk if deferred | Owner approval | Depends on | Acceptance criteria | Status |
|---|---|---|---|---|---|---|---|---|---|
| D1 | Amendment 06 | approve v0.5 (v0.4 content plus the register; D4 and D10 changed and D13/D14 reworded, per 06 "Changes in v0.5") with this report | basis for Phase 2 | — | no rebuild start | YES | this report | approval recorded | OWNER APPROVED 2026-11-18 |
| D2 | Region | `asia-south1`; backups to `asia-south2` | supported; established; DR pair | regional prices TBC | blocks database creation | YES | D4 | price and Scheduler check recorded; database created there | RECOMMENDED |
| D3 | Staging | separate Blaze project plus emulator | real-device and App Check tests | ₹0–500 a month | untested production | YES | D4, D5 | staging project exists; CI deploys there | RECOMMENDED |
| D4 | Billing | Blaze on both projects; alerts at 50/90/100%; Functions spend cap | required services (verified) | variable; §6 | nothing runs | YES | — | budgets active; ceiling recorded | OWNER APPROVAL REQUIRED |
| D5 | Brand and IDs | one brand; `<owned-domain>.peoplebridge`; `.staging` | store-permanent IDs | — | blocks Phase 2 | YES | entity, domain | IDs registered in both projects | OPEN |
| D6 | Old app hotfix | none (D16) | no data | — | — | NO | D16 | — | VERIFIED (closed) |
| D7 | Retention | §3 D7 table | DPDP and stores | small | non-compliance | YES | legal | policy published; TTL and deletion jobs tested | RECOMMENDED |
| D8 | Legacy import | none (D16) | no data | — | — | NO | D16 | — | VERIFIED (closed) |
| D9 | State management | built-in notifiers plus constructor injection | no dependency; simple | none | inconsistent code | YES | — | architecture note; tests use injected services | OWNER APPROVED 2026-11-18 (initially) |
| D10 | OTP | Firebase Phone Auth now; DLT route before a state launch | security now, cost later | SMS dominates (§6) | budget overrun | YES | D5 entity | OTP cost per sign-in measured; limits enforced | RECOMMENDED |
| D11 | Documentation | §9 corrections | consistency | none | conflicting guidance | YES | — | documents consistent | OWNER APPROVED 2026-11-18 (committed `5a5cadd`) |
| D12 | Database | default database | free quota; simplest | lowest | — | YES | D2 | database `(default)` in the chosen region | RECOMMENDED |
| D13 | Requests | §3 D13 semantics | owner requirements; race-free | Functions minor | wrong matching | YES (OPEN points) | D12 | the 5 tests in §3 D13 pass | RECOMMENDED |
| D14 | Number recycling | dormancy guard plus audited recovery | prevents takeover | none | takeover | YES | D7 | recycled-number test cannot see old data | RECOMMENDED |
| D15 | Auth user | retain as a test account | test-number user | none | — | YES (confirm) | — | unchanged | VERIFIED (metadata) / RECOMMENDED |
| D16 | Legacy data | none | owner-confirmed | — | — | — | — | — | VERIFIED (owner) |
| D17 | Extensions API | leave enabled (A) or disable (B) | no extensions; no cost | none | none | YES | — | state recorded in 07 | OWNER APPROVAL REQUIRED |
| B3 | Policy and terms | DPDP notice, lawyer | stores and law | lawyer fee | store rejection | YES | entity | links live | OPEN |
| B4 | Plans and billing | in-app subscription via Play/Apple | store rules | store fee share | redesign | YES | policy check | test purchase evidence | OPEN |
| B5 | Verification documents | per-category list (§4) | trust | review effort | unverified partners | YES | — | list approved | OPEN |
| B6 | Store accounts | organisation accounts | ownership | Play one-time fee; Apple yearly (verify amounts) | release blocked | YES | entity | accounts active | OPEN |
| B7 | Launch | district, then state, then national | risk and cost | staged | — | YES | B6 | region switch tested | OPEN |

## 11. Questions that genuinely need your approval

1. ~~**D1, D11:** approve the amendment (v0.5) and review the drafted documentation corrections (§9).~~ **Done:** approved 2026-11-18 (together with D9).
2. **D4:** approve Blaze on `citizen-india` and a staging project, plus a monthly ceiling for alerts.
3. **D2, D12:** approve `asia-south1` and the default database, after the price and Scheduler check.
4. **D5, B6:** brand name, legal entity, owned domain, and who holds the store accounts.
5. **D10:** start on Firebase SMS; approve preparing a DLT route before a one-state launch (needs the entity).
6. **D13:** answer the OPEN points: late-eligible partners, closing rule, quotations, request caps.
7. **D7, D14, B3:** approve the retention defaults and recovery policy for legal review.
8. **D15, D17:** confirm the test user is kept; choose option A or B for the Extensions API.

## 12. Sequence to finish Phase 1

1. Answer §11 items 1–4 (blocking).
2. Check regional prices and Scheduler availability in the console; record them in 07.
3. Correct the documents per D11 (with your approval); record the decisions in 06. *Done 2026-11-18 (`5a5cadd`, plus the approval record in 06).*
4. Upgrade to Blaze, set budgets, create the staging project. **Only after approval;** each step recorded as evidence.
5. Register the final app IDs (staging, then production) with SHA fingerprints, after approval.
6. Phase 1 evidence file, then commit, push and verify, then your sign-off. Only then may Phase 2 be approved.

## 13. Sources (accessed 2026-11-18)

| Fact | Source |
|---|---|
| Blaze-only products; Spark quotas; phone auth billed per SMS | https://firebase.google.com/pricing |
| India Firestore locations; location permanent; SLA | https://firebase.google.com/docs/firestore/locations |
| Functions in `asia-south1` and `asia-south2`: 2nd gen only, Tier 2 | https://firebase.google.com/docs/functions/locations |
| Storage needs Blaze (from 3 Feb 2026); free tier only in US regions for new buckets | https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024 |
| One free database per project; backups, PITR and restore need billing | https://firebase.google.com/docs/firestore/pricing |
| Budget alerts do not pause services; spend caps limited to certain products | https://firebase.google.com/docs/projects/billing/avoid-surprise-bills |
| India SMS US$0.07; 10 SMS a day free (localized official pages; English page not machine-readable) | https://cloud.google.com/identity-platform/pricing |
| Play account deletion (in-app plus web link; Data Safety) | https://support.google.com/googleplay/android-developer/answer/13327111 |
| Play Billing scope and physical-services exemption | https://support.google.com/googleplay/android-developer/answer/9858738 |
| Apple account deletion | https://developer.apple.com/support/offering-account-deletion-in-your-app/ |
| Apple 3.1.1, 3.1.3(d)(e), 4.8, 5.1.1(v) | https://developer.apple.com/app-store/review/guidelines/ |
| DPDP Rules 2025 notification, phases and retention (secondary legal commentary; verify the Gazette) | https://www.mondaq.com/india/data-protection/1708434/ , https://www.scconline.com/blog/post/2025/12/26/digital-personal-data-protection-rules-2025-key-highlights/ |

**Not verified:**
- Firestore and Storage prices for `asia-south1` and `asia-south2`;
- Cloud Scheduler regional availability;
- Play Integrity and App Check quotas;
- Indian DLT SMS rates;
- Play and Apple fee amounts and small-business rates;
- Play testing requirements for new personal accounts;
- the exact DPDP Gazette text.

> Preserved verbatim from the planning session of 2026-11-14. Do not edit; corrections go in 03-master-blueprint.md.

# People Bridge — Technical Architecture and Roadmap (for approval)

Nothing was changed. This builds on the audit and your confirmed decisions. Items marked **Unknown** need your input before the phase that depends on them.

## 1. Target architecture

**Flutter app**
- Three layers: screens → services → data sources. Screens stop calling Firebase and Hive directly.
- Shared services, each written once: Auth, Session, Provider Profile, Category, Location/Permission, LIVE, Discovery, Subscription, Media Upload.
- One generic provider module (registration, profile, nearby list) driven by a category configuration, replacing the 23 near-identical copies. Migrate category by category, not all at once.
- State management: keep `setState` inside screens; use `ValueNotifier`/`ChangeNotifier` in the services. No new framework.
- One canonical role list (constants) used by registration, LIVE, logout and discovery.

**Firebase (stays primary backend)**
- Auth: phone OTP only.
- Firestore: source of truth for profiles, categories, LIVE, subscriptions.
- Storage: profile photos and chat media, under per-user paths.
- Cloud Functions: a small set only (payment verification, account deletion, category counters). Requires the Blaze plan. **Unknown:** current plan.
- Add App Check, Crashlytics, TTL policy, budget alerts.
- Rules and indexes live in the repository and are deployed from it.

**Hive (stays as cache only)**
- Two boxes: `session` (uid, role, cached own profile) and `prefs` (language, onboarding flags). Cleared boxes replace today's 17.
- Hive never decides registration or subscription status; Firestore does.
- One-time migration on first launch of the new version reads the old boxes, then removes them.

## 2. Data model

| Collection | Purpose | Notes |
|---|---|---|
| `users/{uid}` | Account record: phone, roles held, active role, timestamps | New single owner record |
| Existing provider collections | Provider profiles, one doc per uid | Kept as they are; no migration. Add `geohash`, `isActive`, canonical `role` |
| `categories/{type}/items/{id}` | Category catalogue with a `providerCount` | Replaces UID arrays in category docs |
| `liveLocations/{uid}` | LIVE position, geohash, role, `expiresAt` | Already exists; add TTL policy |
| `subscriptions/{uid}` | Plan, radius, expiry, payment reference | Written only by Cloud Function |
| `conversations`, `calls`, `rideRequests` | Unchanged | Rules tightened to participants |

**Decisions needed:**
- Whether one phone number may hold several provider roles. The model above supports both; LIVE would use the "active role".
- Whether phone numbers are publicly readable or shown only to signed-in users.

## 3. Authentication, logout and deletion

- **Login:** OTP → load `users/{uid}` → if a profile exists for the role, go to Home; otherwise registration. Existing providers are never asked to re-register.
- **Logout (confirmed behaviour), in this order, all awaited before navigating:**
  1. Stop the LIVE service and close the bubble.
  2. Mark `liveLocations/{uid}` offline and set `isOnline: false` on the profile.
  3. Cancel listeners.
  4. Clear the `session` box and session prefs.
  5. Sign out.
  
  Profile and category data stay untouched. If step 2 fails offline, `expiresAt` covers it.
- **Account deletion (separate, in Settings):** re-verify by OTP, then a Cloud Function deletes profiles, LIVE doc, Storage files, category counts and the Auth user. A public web page for deletion requests is also required by Google Play.

## 4. LIVE location and discovery

**LIVE**
- Keep the foreground service. Upload on 30 m movement, or every 60–90 s when stationary. `expiresAt` = 3 × the heartbeat.
- `isOnline` on profiles is derived from LIVE or given the same expiry, so it cannot go stale.
- Firestore TTL deletes expired LIVE docs. TTL can lag by hours, so every reader still filters on `expiresAt`.
- Background-location permission is requested only when a provider turns LIVE on, with a disclosure screen first.
- **Decision needed:** keep the floating bubble (needs the "display over apps" permission and Play justification) or rely on the ongoing notification only. The notification-only option is simpler and lower risk.

**Discovery**
- One Discovery service: geohash range queries around the user, filtered by role/category, `isActive`, and `expiresAt`, then exact distance on device, paginated.
- Static businesses (shops, clinics) are queried by geohash on the profile; mobile providers by geohash on `liveLocations`.
- Home badge counts come from aggregate count queries or category counters, refreshed on open, not from live listeners.
- One radius rule for every module, supplied by the Subscription service.

## 5. Subscriptions and payments

- Plans are stored in Firestore config so prices change without an app update.
- Flow: app creates an order via Cloud Function → gateway checkout → gateway webhook → Function verifies and writes `subscriptions/{uid}` → app reads it. The app never writes subscription data.
- Expiry is evaluated against server time.
- Gateway: Razorpay is the assumption in the code. **Unknown:** your choice and merchant account status.
- **Store-policy risk:** unlocking a search radius is a digital feature. Apple normally requires in-app purchase for this, and Google Play Billing may apply as well. This must be confirmed before building the payment phase; it may mean store billing on iOS and a gateway on Android.

## 6. Security, privacy and store readiness

- **Rules:** users write only their own documents; `subscriptions` and category counts are write-protected from clients; chat and calls restricted to participants; Storage writes restricted to the owner's path with size and type limits.
- **App Check** enforced after a monitoring period.
- **Privacy:** published privacy policy and terms; consent recorded at registration; Data Safety form (Play) and privacy labels (Apple); logs stripped of coordinates and UIDs in release builds.
- **Android:** final application ID, release keystore with Play App Signing, remove unused permissions and packages, Maps key or drop Google Maps, background-location declaration and video.
- **iOS:** Firebase initialisation, plist, permission strings, background location mode, APNs for OTP, a LIVE design without the bubble. **Decision needed:** is iOS in the first release?
- **Maps:** replace the public OpenStreetMap tile server with a licensed low-cost provider.
- **Calls:** out of scope until a TURN service is budgeted. **Decision needed.**

## 7. Cost and scale

Order-of-magnitude only; current Google prices were not looked up.

| Stage | Expected infrastructure spend | Main drivers |
|---|---|---|
| Pilot (one district, low thousands of users) | Near free tier, plus SMS | OTP messages |
| State-level | Low thousands of rupees a month | LIVE writes, discovery reads, SMS |
| National | Scales with active providers and searches | Same, plus map tiles and Storage egress |

- After the changes, reads scale with results shown, and LIVE writes drop by roughly two-thirds.
- Firestore scales nationally without redesign under this model. No PostgreSQL, no servers.
- Budget alerts at fixed thresholds from day one. **Unknown:** your monthly infrastructure ceiling.
- **AI budget (₹3,000/month):** achievable if work is done one phase and one module at a time, and dead code is removed early (Phase 0) to cut context size.

## 8. Implementation phases

| Phase | Scope | Depends on | Acceptance criteria |
|---|---|---|---|
| **0. Foundation** | Git repository; remove commented-out code; export rules and indexes into the repo; final app ID, name, signing; Crashlytics; budget alerts | Decisions: brand, package ID; console access | Clean release build installs; rules in repo match the console; crashes visible in the dashboard |
| **1. Session and logout** | Auth and Session services; `users/{uid}`; new logout sequence; Hive consolidation and migration; canonical roles | Phase 0 | Logging out and back in restores the same profile with no re-registration; no old Hive keys remain; LIVE is off and the provider is offline within the expiry window after logout |
| **2. Security** | Rules rewrite with emulator tests; Storage rules; App Check; privacy policy and terms; account deletion | Phase 1; policy text from you | A second test user cannot edit or delete another user's data; deletion removes all data and the Auth user; policy links open |
| **3. LIVE and discovery** | Location/Permission service; heartbeat change; TTL; Discovery service with geohash queries and counts; single radius rule | Phases 1–2; required indexes | No screen reads a whole collection; an app killed while LIVE disappears from results within the expiry window; counts match lists; reads per search are bounded |
| **4. Subscriptions** | Plans config; Cloud Functions; gateway or store billing; server-side expiry | Phases 2–3; Blaze plan; gateway account; store-billing decision | Plan survives reinstall; changing the device clock has no effect; a failed or forged payment unlocks nothing |
| **5. Store release (Android)** | Permission trim; Maps decision; Data Safety; background-location declaration; closed testing | Phases 0–4 (Phase 4 can follow launch if radius is free initially) | Play pre-launch report clean; closed test passes on Android 10–15 |
| **6. iOS** (if in scope) | Firebase setup; permissions; LIVE without bubble; App Store review items | Phases 1–4 | App runs end-to-end on a physical iPhone; TestFlight build accepted |
| **7. Consolidation** | Migrate remaining categories to the generic module; localise hard-coded strings; test suite | Ongoing after Phase 3 | Each migrated category passes the same registration, LIVE and discovery checks |

Phases 0–2 are sequential. Phase 7 can run alongside 4–6.

## 9. Decisions and unknowns blocking approval

1. Brand name and package ID (blocks Phase 0).
2. Multiple roles per phone number: yes or no (blocks Phase 1).
3. Phone number visibility (blocks Phase 2).
4. Floating bubble: keep or drop (blocks Phase 3).
5. Payment gateway, and store-billing position (blocks Phase 4).
6. iOS in first release; calls in scope (blocks Phases 5–6).
7. Launch geography and monthly infrastructure ceiling.
8. Console access or exports for rules, indexes, billing plan and region.
9. Whether live production data already exists that must be preserved.

Awaiting your approval or changes before any implementation.
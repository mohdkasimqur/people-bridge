# People Bridge — Master Blueprint

Version 3, 2026-11-14. ~~Status: PLANNING. Not approved.~~ **Status (corrected 2026-11-18): requirements baseline for the roadmap the owner approved on 2026-11-15.**
- The fresh-rebuild amendment [06-fresh-rebuild-amendment.md](06-fresh-rebuild-amendment.md) (v0.5, approved by the owner on 2026-11-18, decision D1) amends the architecture and phases.
- Where 06 or the decision report [08-consolidated-decision-report.md](08-consolidated-decision-report.md) marks a section here as superseded, that marking is noted in place.
- Requirements, labels and history stay as written.
- Decision numbers in §11 now carry their authoritative IDs (B3–B7, D2, D5, D16; see 06 §11).

Changes in version 3 (scope lock):

- In-app voice and video calls will **not** be implemented. **[Confirmed]**
- Android and iOS are both required; multi-role accounts are required; subscriptions are paid by partners. These were wrongly listed as open and are now **[Confirmed]**.
- The roadmap and acceptance criteria moved to [04-final-phase-roadmap.md](04-final-phase-roadmap.md), which renumbers the phases. Sections 10 and 12 here now point to it.
- The decision list in section 11 is reduced to genuine blockers; everything else has a stated default.

Every item carries one of these labels:

- **[Confirmed]** — decided by the owner, or verified in the code.
- **[Required]** — stated by the owner as a requirement; the detail has not been specified.
- **[Recommended]** — the architect's proposal; needs owner approval.
- **[Open]** — a question only the owner can answer.

Related documents: [01-audit-report.md](01-audit-report.md) (full audit, verbatim), [02-architecture-roadmap-v1.md](02-architecture-roadmap-v1.md) (first blueprint, superseded by this one).

---

## 1. Final project assessment

- **[Confirmed]** The Android app has 23 provider modules, phone OTP login, LIVE location, chat, calls and 23 languages. It is not ready for either store or for India-wide load. Details are in the audit.
- **[Confirmed]** The code base is 125 Dart files, about 310,000 lines, about 47% commented-out code. No git, no CI, no working tests, no backend code, no rules or indexes in the repo.
- **[Confirmed]** Three brand names appear in code: "People Bridge", "Citizen India" and "Jober India".
- **[Confirmed]** The only planning records are this session's documents. No earlier requirement document, chat or backup exists in the project folder or the Claude project history. Requirements in section 2 marked **[Required]** therefore have no agreed detail yet.

### What exists in code for each required area

Checked on 2026-11-14 by searching non-comment code and the 46 Firestore collections in use.

| Area | State in code |
|---|---|
| Partner registration | Exists, duplicated per category (24 OTP flows, 29 different role strings) |
| Customer accounts | No "customer" or "partner" role string exists. A `users` collection is referenced once |
| Multi-role accounts | Not designed. One UID can own several provider documents, but LIVE and local storage hold one role |
| Discovery and radius | Exists, but reads whole collections; radius rules differ by module |
| Job requests | Only `rideRequests` and `driverRequests` (taxi and driver flows). No general job request |
| Bookings, scheduling | One file mentions booking, four mention scheduling. No bookings collection |
| Quotations, rebooking | Nothing found |
| Cancellation | One file (ride flow) |
| LIVE and location privacy | LIVE exists; exact coordinates and phone numbers are stored on public-readable profiles |
| Reviews and ratings | No reviews or ratings collection. Keyword matches are too broad to confirm any feature |
| Verification | Licence and "verified" fields appear in 25 files; no verification workflow or admin approval found |
| Support and disputes | No tickets, reports or disputes collection |
| Super Admin | No admin collection, role or app. Keyword matches are geocoding fields (`administrativeArea`) |
| Push notifications | `firebase_messaging` is declared but never imported |
| Analytics | None |
| Subscriptions and payments | Local Hive state only; payment is a placeholder |

---

## 2. Product requirements

### 2.1 Platforms and rollout

- **[Confirmed]** Flutter/Dart app for Android and iOS. Both platforms are in scope.
- **[Confirmed]** Launch in one state, then expand nationwide across India.
- **[Recommended]** Android is released first and iOS follows from the same code, because iOS needs a separate LIVE design and Apple review.
- **[Open]** Which state. Not blocking until release, since regions are configuration.

### 2.2 Accounts and roles

- **[Confirmed]** Customer and partner registration, and multi-role accounts: one phone number may hold several roles.
- **[Confirmed]** Sign-in is by phone OTP.
- **[Confirmed]** Partner profiles are kept on logout. Logout stops LIVE, marks the partner offline, clears local session data and signs out. Permanent account deletion is a separate feature.
- **[Recommended]** "Partner" means any account holding at least one of the existing provider profiles. "Customer" means any signed-in account; every partner can also act as a customer. One account record (`users/{uid}`) lists the roles held and the active partner role.
- **[Recommended]** Only one partner role is active and LIVE at a time; the user switches role in the app. This is the default unless the owner asks for simultaneous roles.
- **[Recommended]** `student`, `houseOwner` and `company` are treated as partner profile types of the "listing" kind (section 7). Default unless the owner says otherwise.

### 2.3 Service categories

- **[Confirmed]** Existing modules: Ambulance, Broker, Clinic, Companies, Courier, Doctors, Fish/Fruit Delivery, Food Delivery, Freelancers, Garage, Groceries, Individual Sellers, Laboratory, Medical Shop, Other Business, Recovery, Rentals, Self Employed, Spare Parts, Taxi/Commercial, Tea Shops, Workers.
- **[Required]** Category-specific workflows for all categories.
- **[Recommended]** Three workflow types cover them (section 7): mobile partners, fixed-location businesses, and listings.
- **[Open]** Which categories launch first, and any category to drop or add.

### 2.4 Discovery and subscription radius

- **[Required]** Location-based discovery, with the search radius set by subscription.
- **[Confirmed]** Current code: 1 km free and 5 km paid on Home, 1 km free and 50 km cap in rentals, fixed 50 km for ambulances.
- **[Recommended]** One radius rule for every module, supplied by the subscription record; emergency categories (ambulance) keep a fixed wide radius for everyone.
- **[Confirmed]** Subscriptions are paid by partners.
- **[Recommended]** The partner's plan sets the radius within which that partner is shown to customers and receives job requests. Customers search for free. This reverses the current code, which sells radius to the person searching, and needs the owner's confirmation before the subscription phase.
- **[Open]** Plans, prices and durations. Blocking only for the subscription phase.

### 2.5 Job requests and matching

- **[Required]** Persistent job requests and simultaneous partner matching.
- **[Recommended]** A customer posts a request (category, location, description, optional time). It is sent at once to eligible nearby partners and stays open until it is accepted, cancelled or expires. Detail in section 5.
- **[Open]** How many partners receive a request; how long it stays open; whether the first partner to accept wins or the customer chooses; whether offline partners are notified.

### 2.6 Bookings

- **[Required]** Bookings, scheduling, quotations, cancellations and rebooking.
- **[Recommended]** A booking is created when a customer accepts a partner's response. States: requested, quoted, confirmed, in progress, completed, cancelled. Rebooking copies a past booking into a new request to the same partner.
- **[Open]** Which categories need quotations; cancellation rules and any penalties; whether the app handles payment for the job itself or only connects the two sides.

### 2.7 Partner availability, LIVE and privacy

- **[Required]** Partner availability, LIVE functionality and location privacy.
- **[Confirmed]** LIVE is a foreground service on Android writing `liveLocations/{uid}` with an expiry stamp.
- **[Recommended]** Customers see distance and an approximate position until a booking is confirmed; exact position and phone number are revealed only to the matched customer.
- **[Open]** Phone number visibility; floating bubble keep or drop; working-hours schedule in addition to LIVE.

### 2.8 Trust and support

- **[Required]** Reviews, verification, support and dispute management.
- **[Recommended]** Reviews only after a completed booking, one per booking. Verification as an admin-approved document check with a badge. Support as tickets; a dispute is a ticket linked to a booking.
- **[Open]** Which documents per category; whether unverified partners are visible; who resolves disputes and within what time.

### 2.9 Super Admin

- **[Required]** Complete Super Admin dashboard and permissions.
- **[Recommended]** A web dashboard with roles (super admin, admin, support, read-only). Functions: users and partners, verification queue, categories, plans and subscriptions, bookings and requests, disputes and tickets, content and policy links, regional rollout switches, analytics, audit log.
- **[Open]** The full feature list, number of admin users, and which actions need a second approver.

### 2.10 Notifications, analytics, expansion

- **[Required]** Notifications, analytics and regional expansion.
- **[Recommended]** Push notifications for requests, booking changes, chat, subscription expiry and verification results. Analytics events for registration, search, request, booking and payment funnels. Regions enabled per state and district from the dashboard.
- **[Open]** SMS fallback for critical notifications (adds cost); which languages are required at launch.

### 2.11 Existing features with no stated decision

- **[Confirmed]** In-app voice and video calls are not implemented. The existing call screen, the `calls` collection and the `flutter_webrtc` dependency are taken out of the app in the Foundation phase, after checking nothing else uses them. Customers reach partners by chat or the phone dialler.
- **[Recommended]** Text chat stays as it is, with rules restricted to participants.

---

## 3. System architecture

### 3.1 Backend choice: Firebase versus PostgreSQL/PostGIS

| Factor | Firebase (current) | PostgreSQL/PostGIS |
|---|---|---|
| Existing work | 46 collections, Auth, Storage already wired | Full rewrite of data access plus a new API server |
| Radius search | Geohash range queries; adequate for "nearest partners" | Best in class |
| Bookings, disputes, admin reports | Workable with Cloud Functions and transactions; ad-hoc reporting is weak | Natural fit |
| Real-time updates | Built in | Must be built |
| Operations and cost | No servers; pay per use | A database and API to host, secure, back up and monitor |
| Team capacity | Fits a small team | Needs backend operations skill |

- **[Recommended]** Stay on Firebase for launch and the first state. Use Cloud Functions for everything that must not be trusted to the phone.
- **[Recommended]** For admin reporting and analytics, export Firestore to BigQuery when the dashboard needs queries Firestore cannot express. This adds reporting without moving the live database.
- **[Recommended]** Reconsider PostgreSQL only on measured evidence: search needing ranking or many combined filters, reporting that BigQuery export cannot serve, or Firestore cost per active user rising above an agreed limit.
- **[Confirmed]** Existing systems stay until a verified migration plan is approved.

### 3.2 Flutter app

- **[Recommended]** Three layers: screens, services, data sources. Screens stop calling Firebase and Hive directly.
- **[Recommended]** Shared services written once: Auth, Session, Profile, Category, Location and Permission, LIVE, Discovery, Requests and Bookings, Subscription, Notification, Media Upload.
- **[Recommended]** State: keep `setState` in screens and use `ValueNotifier`/`ChangeNotifier` in services. No new state framework.
- **[Recommended]** One canonical list of role and category identifiers used everywhere.
- **[Recommended]** One generic partner module (registration, profile, nearby list) driven by category configuration, migrated category by category.
- **[Recommended]** Hive stays as a cache only, reduced to two boxes (`session`, `prefs`). Firestore decides registration and subscription state.

### 3.3 Backend services (Cloud Functions)

- **[Recommended]** Payment order creation and webhook verification.
- **[Recommended]** Job request fan-out and matching, booking state changes.
- **[Recommended]** Notification sending.
- **[Recommended]** Account deletion and data clean-up.
- **[Recommended]** Admin actions (verification, suspension, refunds, plan changes) with an audit log.
- **[Recommended]** Scheduled jobs: expire requests and subscriptions, clean stale LIVE records.
- **[Confirmed]** Cloud Functions need the Blaze (pay-as-you-go) plan. **[Open]** Current billing plan.

### 3.4 Authentication and authorisation

- **[Confirmed]** Phone OTP through Firebase Auth.
- **[Recommended]** Admin roles as custom claims, set only by a Cloud Function. Firestore rules: users write only their own documents; subscriptions, bookings status, reviews aggregates, counters and admin data are written only by Functions.
- **[Recommended]** App Check on Firestore, Storage and Functions.

### 3.5 Real-time, location, storage, notifications

- **[Recommended]** Real-time listeners only on small, specific documents (a booking, a request, a chat). Lists use paginated queries.
- **[Recommended]** LIVE: keep the foreground service; upload on 30 m movement or every 60–90 seconds when stationary; expiry three times the heartbeat; every reader checks expiry; Firestore TTL removes old records.
- **[Recommended]** Discovery: geohash range queries on `liveLocations` for mobile partners and on the profile for fixed businesses, then exact distance on the device, paginated.
- **[Recommended]** Maps: a licensed low-cost tile provider replaces the public OpenStreetMap server. **[Open]** Provider and whether Google Maps stays.
- **[Recommended]** Storage: per-user paths, size and type limits, deletion when a profile or account is deleted.
- **[Recommended]** Notifications: Firebase Cloud Messaging, with device tokens stored per user.

### 3.6 Super Admin web

- **[Recommended]** A separate Flutter web app in the same repository, hosted on Firebase Hosting, sharing the data models with the mobile app. All privileged writes go through Cloud Functions. Admin sign-in requires a second factor.

### 3.7 Backup, monitoring, disaster recovery

- **[Recommended]** Scheduled Firestore exports to a storage bucket, with a tested restore.
- **[Recommended]** Crashlytics for the app, Cloud Monitoring alerts for Functions errors, and budget alerts.
- **[Recommended]** Rules, indexes and Functions deployed only from the repository.

---

## 4. Database and data migration plan

### 4.1 Collections

| Collection | Purpose | Status |
|---|---|---|
| Existing provider collections (22 types) | Partner profiles, one document per UID | Keep. Add `geohash`, `isActive`, canonical `role`, `verified` |
| `liveLocations/{uid}` | LIVE position and expiry | Keep. Add TTL |
| `conversations`, `messages` | Chat | Keep. Restrict to participants |
| `calls` | Old call signalling | No longer written by the app; existing data removed only with owner approval |
| `rideRequests`, `driverRequests` | Existing taxi and driver flows | Keep until the general request flow replaces them |
| `users/{uid}` | Account, roles, active role, device tokens, region | New |
| `categories/{type}/items/{id}` | Category catalogue with counts | New; replaces UID arrays inside category documents |
| `jobRequests/{id}` and `recipients` subcollection | Requests and the partners they were sent to | New |
| `bookings/{id}` | Booking, quotation, schedule, state history | New |
| `reviews/{id}` | One review per completed booking | New |
| `tickets/{id}` | Support and disputes | New |
| `subscriptions/{uid}`, `plans/{id}` | Plans and paid state | New; written only by Functions |
| `admin/…`, `auditLog/{id}`, `config/{id}` | Admin data, audit trail, regional switches | New |

All new collections are **[Recommended]**. Field-level schemas are written per module before that module is built.

### 4.2 Migration

> **Superseded (2026-11-18), kept for history.** The verified Firebase inventory ([07](07-legacy-firebase-verification.md)) found no Firestore database or Storage bucket in `citizen-india`, and the owner confirmed there were never real production users or data (D16). No migration or back-fill is planned; the items below apply only as a contingency if contrary evidence appears ([06](06-fresh-rebuild-amendment.md) §5).

- **[Recommended]** No bulk migration. Existing profile documents stay where they are; new fields are added by a one-time back-fill script run from a Cloud Function or admin tool, after a full export.
- **[Recommended]** Category ownership arrays are replaced by counters, back-filled once.
- **[Recommended]** On first launch of the new app version, old Hive boxes are read, mapped to the two new boxes and removed.
- **[Open]** Whether production data exists today that must be preserved. If none, the back-fill steps are not needed.
- **[Confirmed]** No database change happens before the owner approves a written migration step.

---

## 5. API and module breakdown

Each module is one unit of development with its own tests and acceptance check.

| # | Module | Contents |
|---|---|---|
| M1 | Foundation | Git, app identity, signing, rules and indexes in repo, crash reporting, dead-code removal |
| M2 | Auth and Session | One OTP flow, `users/{uid}`, logout sequence, Hive consolidation |
| M3 | Roles and Categories | Canonical identifiers, category catalogue, counters |
| M4 | Partner Profile | Generic registration and profile, media upload |
| M5 | Location and LIVE | Permission service, foreground service changes, expiry handling |
| M6 | Discovery | Geohash queries, counts, one radius rule |
| M7 | Notifications | Device tokens, push sending, in-app list |
| M8 | Job Requests | Create, fan-out, respond, expire |
| M9 | Bookings | Quote, confirm, schedule, cancel, rebook, history |
| M10 | Reviews and Verification | Reviews after completion; document check and badge |
| M11 | Support and Disputes | Tickets linked to bookings |
| M12 | Subscriptions and Payments | Plans, order, webhook verification, expiry |
| M13 | Super Admin web | Dashboard, roles, audit log |
| M14 | Account Deletion and Privacy | In-app and web deletion, data export on request |
| M15 | Analytics and Regions | Event tracking, per-region switches |
| M16 | Release | Android and iOS store preparation |

### Job request flow **[Recommended]**

1. The customer creates a request with category, location and details.
2. A Function finds eligible partners within the radius (LIVE first), caps the number, records them as recipients and sends push notifications.
3. Partners accept or send a quotation. The request stays open until its expiry time.
4. The customer confirms one response; a transaction creates the booking and closes the request so no second partner can be confirmed.
5. Unanswered requests expire by schedule and the customer is told.

---

## 6. Security and compliance plan

### Release blockers **[Confirmed]** (from the audit)

1. Android application ID is `com.example.jober_india`; release builds use the debug key.
2. iOS crashes at startup; no Firebase configuration file, no permission texts, no background mode.
3. Firestore and Storage rules are not in the repository and have not been reviewed.
4. No account deletion, in the app or on the web.
5. Privacy policy and terms links are empty.
6. Background location, overlay, exact-alarm and boot permissions are declared; each needs justification or removal.
7. Subscription state is stored only on the device.
8. No Maps API key for the one Google Maps screen; public OpenStreetMap tiles are used against their usage policy.
9. Coordinates and UIDs are printed to logs.

### Plan **[Recommended]**

- **Rules:** written and tested in the emulator before any release; a second test user must not be able to read private fields or change another user's data.
- **Data exposure:** phone numbers and exact coordinates move out of publicly readable documents.
- **Admin security:** custom claims, second factor, audit log, least privilege per admin role.
- **Location:** background permission requested only when a partner turns LIVE on, after an in-app disclosure; Play declaration form and demo video.
- **Privacy:** published policy and terms, consent recorded at registration, Play Data Safety form and Apple privacy labels, data retention periods per collection. **[Open]** Retention periods and the legal entity publishing the policy.
- **Payments:** see section 3.3. **[Open]** Apple normally requires in-app purchase for digital features, and Google Play Billing may apply; this must be confirmed before M12.
- **Accessibility:** text scaling, contrast, screen-reader labels and touch target sizes checked on each new screen.
- **Signing:** release keystore held outside the repository, Play App Signing, Apple distribution certificate.

---

## 7. UI/UX and category workflow plan

- **[Recommended]** Three workflow types:
  - **Mobile partners** (workers, taxi, courier, delivery, recovery, ambulance, freelancers, self-employed): LIVE, job requests, bookings.
  - **Fixed businesses** (clinics, doctors, labs, medical shops, groceries, tea shops, garages, spare parts, other business): profile, opening hours, appointment or enquiry booking.
  - **Listings** (rentals, brokers, individual sellers, companies): browse, enquire, chat.
- **[Open]** Confirmation that each category sits in the right type.
- **[Recommended]** One shared set of screens per type; categories differ by configuration, not by copied code.
- **[Recommended]** All user-facing text comes from the language files; hard-coded English strings are moved as each screen is rebuilt.
- **[Recommended]** Lists are paginated and lazily built; images are cached and sized; no screen holds more than one large listener.
- **[Open]** Brand name, colours and whether the current visual design stays.

---

## 8. Testing and performance strategy

- **[Recommended]** Unit tests for every service (auth, session, discovery filters, subscription expiry, request and booking state changes).
- **[Recommended]** Rules tests in the Firebase emulator for every collection.
- **[Recommended]** Function tests for payment verification, matching and account deletion.
- **[Recommended]** Widget tests for the shared screens; a small set of end-to-end tests for register, go LIVE, search, request, book, cancel, logout.
- **[Recommended]** Every bug fix adds a test that fails before the fix.
- **[Recommended]** Performance targets, to be confirmed by the owner: cold start under 3 seconds on a mid-range Android phone, no dropped frames while scrolling lists, search results within 2 seconds on 4G, a bounded number of document reads per search.
- **[Recommended]** A check on every change (analyse, test, build) once the project is in git.

---

## 9. Infrastructure and cost estimate

Order of magnitude only. Current Google prices were not looked up, and present usage is unknown.

| Stage | Expected monthly infrastructure spend | Main drivers |
|---|---|---|
| Pilot, one district | Near the free tier, plus SMS | OTP messages |
| One state | Low thousands of rupees | LIVE writes, discovery reads, push, SMS |
| National | Grows with active partners and searches | The same, plus map tiles, Storage and Functions |

- **[Confirmed]** Today's design reads whole collections, so cost grows with total partners times app opens. The discovery and LIVE changes make cost grow with results shown.
- **[Recommended]** Budget alerts from the first day. **[Open]** Monthly infrastructure ceiling.
- **[Open]** Payment gateway fees and map tile provider. No TURN or call infrastructure is needed.

### AI budget and tools

- **[Confirmed]** AI subscription budget: at most ₹3,000 a month.
- **[Recommended]** One module per session; start a new session per module; remove dead code first, since file size is the main token cost.
- Tool status is recorded in `CLAUDE.md`. **[Recommended]** Keep Ponytail in `full`; keep Graphify without strict mode and rebuild the graph after each module; reduce the 25 Agent Skills to the few that match the current module; use OmniRoute only if the owner decides to route some work to other models.

---

## 10. Prioritised implementation roadmap

Moved to [04-final-phase-roadmap.md](04-final-phase-roadmap.md). That document is the only roadmap; phase numbers used elsewhere in earlier versions are superseded.

---

## 11. Dependencies, risks and unresolved decisions

### Risks

| Risk | Effect | Mitigation |
|---|---|---|
| Rules are permissive today | Personal data exposed | Security phase before any wider release |
| Scope has grown well beyond the current app | Long delivery time | Build module by module; release gates in the roadmap |
| Store billing rules for subscriptions | Rejection or forced redesign | Decide before the subscription phase |
| Background location review | Play rejection | Disclosure, declaration, minimal permissions |
| iOS has no equivalent of the Android bubble and service | Separate LIVE design | iOS phase designs it explicitly |
| Large files and dead code | High AI cost, slow changes | Dead-code removal in the Foundation phase |
| No knowledge of production data | Migration surprises | ~~Export and inspect in the Foundation phase~~ **Resolved 2026-11-18:** inspected (07); none exists (D16) |
| Reversing who pays for radius | Existing subscription screens are discarded | Confirm before the subscription phase |

### Confirmed (no longer open)

- Android and iOS both in scope.
- Multi-role accounts.
- Partners pay for subscriptions.
- No in-app voice or video calls.
- Firebase and Hive stay until a migration decision is approved.
- Profiles kept on logout; account deletion is separate.

### Genuinely blocking decisions

Authoritative IDs (2026-11-18) are listed in [06](06-fresh-rebuild-amendment.md) §11. The old numbers 1–7 remain valid aliases.

| # (alias) | ID | Decision | Blocks | State (2026-11-18) |
|---|---|---|---|---|
| 1 | D5 | Brand name, Android package ID, iOS bundle ID | Foundation | OPEN |
| 2 | D2 + D16 | Firebase console access or exports: rules, indexes, billing plan, region, usage; whether live user data exists | Foundation | Access **verified** (07). D16 **owner-confirmed**: no data. Region (D2), billing, App Check and keys OPEN |
| 3 | B3 | Privacy policy and terms text, and the legal entity publishing them | Security and privacy | OPEN |
| 4 | B4 | Plans, prices, durations; payment gateway; position on Apple and Google billing; confirmation that the plan sets the partner's visibility radius | Subscriptions | OPEN |
| 5 | B5 | Verification documents required per category | Trust | OPEN |
| 6 | B6 | Apple Developer and Google Play accounts | iOS and release | OPEN |
| 7 | B7 | Launch state | Release | OPEN |

### Non-blocking decisions with defaults

These proceed on the default unless the owner changes it before the phase starts.

| Decision | Default |
|---|---|
| Several partner roles active at once | One active role at a time |
| `student`, `houseOwner`, `company` | Treated as listing-type partner profiles |
| Floating bubble | Dropped; the ongoing notification is used |
| Phone number and exact location | Hidden from the public; shown to signed-in users after a confirmed booking or accepted request |
| Job request rules | ~~Sent to the nearest eligible partners up to a configurable cap; open for a configurable time; the customer chooses among responses~~ **Superseded (2026-11-18)** by the owner-stated rules in 06 §4.6 and 08 D13: all eligible partners; the first server-side acceptance wins; radius expansion without duplicates; open until accepted, cancelled or closed. The remaining details are OPEN under D13 |
| Quotations | Optional on every category |
| Cancellation | Either side may cancel before the job starts; no penalties in the first version |
| Job payment | Not handled by the app in the first version |
| Unverified partners | Visible without a badge |
| Disputes | Handled by support staff in the admin dashboard |
| Map provider | Keep `flutter_map` with a licensed tile provider; remove the single Google Maps screen |
| Launch categories | All existing categories |
| Performance targets | As listed in section 8 |
| Infrastructure ceiling | Budget alerts set at the first billing review |

---

## 12. Acceptance criteria by phase

Moved to [04-final-phase-roadmap.md](04-final-phase-roadmap.md), where each phase has its tests, acceptance criteria and completion gate.

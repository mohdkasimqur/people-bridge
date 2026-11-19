# Phase 1 (Foundation) — closing report

Date: 2026-11-18 (updated 2026-11-19). **Phase 1 SIGNED OFF by the owner on 2026-11-19 (§7).** This report does not approve any other decision or start Phase 2.
Repository state reviewed: `main` at `5740fe9` (in sync with `origin/main`), plus the uncommitted documentation updates of 2026-11-18/19.
Criteria source: [06 §8 Phase 1](../06-fresh-rebuild-amendment.md) (approved v0.5, D1, with owner-approved amendments A and B of 2026-11-18) and the roadmap's "Rules for every phase" ([04](../04-final-phase-roadmap.md)), which 06 keeps.
Status labels: **VERIFIED** · **INCOMPLETE** · **NOT VERIFIED** · **NOT APPLICABLE** · **OWNER-APPROVED DEFERRED** (accepted by explicit owner ruling; the work happens later).

## 1. Executive summary

**Verdict: SIGNED OFF (owner, 2026-11-19).** Evidence committed and pushed in `f2585f7`; remote hash verified. The text below is the review record as it stood before sign-off.

*Pre-sign-off verdict: READY FOR OWNER SIGN-OFF.*
- Under 06 §8 as amended by A and B, every Phase 1 deliverable and acceptance criterion is VERIFIED, NOT APPLICABLE, or accepted by an explicit owner ruling (§2, §4).
- Two procedural gates remain, and both are yours:
  1. Authorise the commit and push of these documents (R6, R7).
  2. Sign §7 (R8).
- Carried forward, and **not** Phase 1 criteria:
  - D5 identifiers (OPEN; due before any Phase 2 app registration);
  - the billing, App Check and API-key console checks (OWNER-APPROVED DEFERRED / NOT VERIFIED; due in 07 before Phase 3 creates any resource).

## 2. Acceptance-criteria matrix

### 2.1 06 §8 Phase 1 deliverables and acceptance (as amended)

| # | Requirement | Status | Evidence | Remaining action |
|---|---|---|---|---|
| P1 | D5: working name recorded. IDs decided before any app registration or release; ID approach due before Phase 2 app registration (amendment A) | **VERIFIED** for Phase 1 | Working name **People Bridge (provisional)** recorded (06 approval record, 06 §11). The package ID, bundle ID, legal entity, domain and the (a)/(b) approach stay OPEN and are **not** a Phase 1 closure criterion (amendment A) | Before any Phase 2 app registration |
| P2 | Read-only inspection of Firebase with authenticated access | **VERIFIED** | 07 v3 §2–§4, §14 (2026-11-18, 21:50–21:55 IST) | — |
| P2a | Billing, App Check and API-key restrictions | **OWNER-APPROVED DEFERRED / NOT VERIFIED** | Amendment B: not a Phase 1 closure criterion; no API was enabled to inspect them (07 §3 and §14) | You check them in the console; recorded in 07 before Phase 3 creates any resource |
| P3 | D16 answered | **VERIFIED** | 06 §11 D16 OWNER CONFIRMED 2026-11-18 | — |
| P4 | Auth configuration and app registrations recorded | **VERIFIED** | 07 §4; no user data or secrets; Auth user untouched (D15) | — |
| P5 | Staging project, only if D3 and D4 are approved | **NOT APPLICABLE** in Phase 1 | D3 and D4 deferred to Phase 3 (06 §11) | Phase 3 |
| P6 | Amendment approved (D1) | **VERIFIED** | 06 approval record; `5740fe9` | — |
| A1 | Configuration record matches a same-day inventory, saved as evidence | **VERIFIED by owner ruling** | 07 v3 (2026-11-18) accepted as the Phase 1 inventory | — |
| A2 | Inspection results recorded | **VERIFIED** (by reference) | 07 v3 | — |
| D | Phase 1 dependencies (06 §8 phase table) | **VERIFIED** | Phase 1 now depends on "D5 (working name only)", which is recorded. D2, D3 and D4 are deferred to Phase 3; D15 and D17 are decided as "leave as is" (06 §11) | — |
| C | Contingency items | **NOT APPLICABLE** | D16 confirmed | Reopen only on contrary evidence |

### 2.2 Roadmap rules for every phase (04, kept by 06)

| # | Rule | Status | Evidence | Remaining action |
|---|---|---|---|---|
| R1 | Tests written and actually run | **VERIFIED** | `flutter test` 3 passed ([part 3](phase-1-part-3.md) §2; re-run 2026-11-18, 05 §1) | — |
| R2 | Regression of earlier automated tests | **VERIFIED** | part 3 §9 A1–A4 | — |
| R2a | Manual regression M1–M10 | **NOT APPLICABLE** (owner ruling 2026-11-18) | The old app was never shipped | — |
| R3 | `flutter analyze`: no new warnings | **VERIFIED** | 0 errors, 0 warnings, 114 infos (2026-11-18) | — |
| R4 | App builds in release mode | **OWNER-APPROVED DEFERRED** | Not required for Phase 1 (owner ruling 2026-11-18); only debug builds exist | Verify in Phase 2 |
| R5 | Graphify graph rebuilt | **VERIFIED** | Rebuilt 2026-11-18 01:49, after the last code commit `825a847` | After Phase 2 code |
| R6 | Evidence saved | **VERIFIED** | Parts [1](phase-1-part-1.md), [2](phase-1-part-2.md), [3](phase-1-part-3.md) and this report, committed in `f2585f7` | — |
| R7 | Commit pushed and verified | **VERIFIED** | `f2585f7` pushed to `origin/main`; local and remote hashes match (2026-11-19) | — |
| R8 | Owner sign-off | **VERIFIED** | §7, signed off by the owner on 2026-11-19 | — |

## 3. Completed work (evidence index)

| Work | Evidence |
|---|---|
| Git, private repo, baseline `912d74b` | [part 3 §1](phase-1-part-3.md) |
| Commented-out code, calls and unused packages removed (`50b917e`) | [part 1](phase-1-part-1.md) |
| App compiles (`ee0d33b`) | [part 2](phase-1-part-2.md) |
| Debug build on Flutter 3.50 (`825a847`); verification (`f499e37`) | [part 3 §7](phase-1-part-3.md) |
| Environment recovery (2026-11-17/18) | [04 Phase 1 note](../04-final-phase-roadmap.md); [05](../05-development-environment.md) |
| Authenticated Firebase inventory; D16 | [07 v3](../07-legacy-firebase-verification.md) |
| Amendment approved (D1); D9 and D11; amendments A and B | [06](../06-fresh-rebuild-amendment.md) approval record; `5740fe9` |
| Decision report and cost model | [08 v1.6](../08-consolidated-decision-report.md) |

## 4. Owner rulings recorded (2026-11-18)

| Item | Ruling |
|---|---|
| D5 | Working name People Bridge (provisional). Final brand, package ID, bundle ID, legal entity and domain stay OPEN |
| Amendment A | D5 ID approach due before any Phase 2 app registration; not a Phase 1 closure criterion (applied to 06 §8 and §11) |
| Amendment B | Billing, App Check and API-key console checks OWNER-APPROVED DEFERRED; recorded in 07 before Phase 3 creates resources; not a Phase 1 closure criterion (applied to 06 §8) |
| Keystore, Crashlytics, CI check script | Phase 2 |
| R2a | Not applicable |
| R4 | Not required for Phase 1; verified in Phase 2 |
| A1 | 07 v3 accepted as the Phase 1 inventory |
| D2, D3, D4 | Deferred to Phase 3, before database or resource creation; billing changes need explicit approval |
| D15 | Auth user stays untouched; identification deferred |
| D17 | Extensions API stays enabled and unchanged; assessed before Phase 3 |

Still deferred to later phases (06 §11): D7, D10, D12, D13, D14 and B3–B7.

## 5. Remaining gates checklist

- [x] Every 06 §8 Phase 1 criterion is VERIFIED, NOT APPLICABLE or accepted by ruling (amendments A and B applied)
- [x] Owner authorises the commit and push of the documentation updates and this report (R6, R7): authorised 2026-11-19
- [x] Commit pushed and remote hash verified: `f2585f7`
- [x] Owner signs §7 (R8): signed off 2026-11-19

**Carried forward:**
- **Before Phase 2 app registration:** D5 ID approach, package ID, bundle ID, legal entity and domain.
- **Before Phase 3 resource creation:**
  - P2a console checks recorded in 07;
  - D2, D3, D4;
  - D17 assessment.

## 6. Risks and limitations

- **Legacy app:** never run on any device. Accepted, because it is not shipped (R2a).
- **Billing, App Check and API keys:** unknown until your console check (P2a).
- **Remote state:** last read on 2026-11-18. Re-verify before Phase 3.
- **Extensions API:** still enabled (D17), with no functional impact known.
- **Hardware:** iOS needs a Mac or a macOS CI runner, and Phase 2's device-based acceptance needs an Android device or emulator.
- **App IDs:** permanent once published. They are settled before any Phase 2 app registration (amendment A).

## 7. Owner sign-off

Rulings recorded in §4. The R6 and R7 gates were completed by `f2585f7`.

**Phase 1 sign-off:** ☑ Approved  ☐ Not approved
Signed: the owner, by chat instruction "Sign off Phase 1"  Date: 2026-11-19
Comments: Carried-forward items in §5 stay open:
- D5 identifiers before any Phase 2 app registration;
- P2a console checks, D2, D3, D4 and the D17 assessment before Phase 3 creates resources.

Phase 1 is signed off. Phase 2 starts only on the owner's explicit instruction, under the roadmap rule "a phase starts only when the previous phase's gate is met and the owner has signed it off".

## 8. Acceptance-criteria amendments: APPROVED AND APPLIED (owner, 2026-11-18)

- **Amendment A:**
  - 06 §8, Phase 1: the D5 ID approach is "OPEN, owner approval required before any Phase 2 app registration … Not a Phase 1 closure criterion".
  - 06 §11 D5 "Needed by": "before Phase 2 app registration for the ID approach".
  - Phase table: Phase 1 depends on "D5 (working name only)"; Phase 2 depends on "D5 (ID approach and IDs, before any app registration)".
- **Amendment B:** 06 §8, Phase 1: the billing, App Check and API-key console checks are "OWNER-APPROVED DEFERRED (2026-11-18), not verified; to be checked by the owner in the console and recorded in 07 before Phase 3 creates any resource. Not a Phase 1 closure criterion."

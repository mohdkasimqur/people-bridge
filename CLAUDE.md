# People Bridge — project instructions

## Status

**Roadmap approved by the owner on 2026-11-15. Phase 1 (Foundation) was signed off by the owner on 2026-11-19 (`docs/people-bridge/evidence/phase-1-closing-report.md`). Phase 2 (fresh rebuild) started on the owner's instruction on 2026-11-19; Module 2.1 (workspace skeleton) is implemented and awaiting owner review (`docs/people-bridge/evidence/phase-2.md`).** Work proceeds one phase at a time, in roadmap order; a phase is complete only when its gate is met, its commit is pushed and the owner has signed it off. Do not start a later phase early, and do not change Firebase, the database or production data without the step being in the current phase.

- Git: private repository `mohdkasimqur/people-bridge`, branch `main`; baseline commit `912d74b`.
- Working app name: **People Bridge (provisional)**. The final brand is confirmed at the final branding and release stage.
- Phase 1 signed off 2026-11-19 (evidence committed in `f2585f7`). Items carried forward:
  - D5 identifiers (package ID, bundle ID, legal entity, owned domain, and the ID approach) stay OPEN. They are due **before any Phase 2 app registration** (06 amendment A, owner-approved 2026-11-18).
  - Deferred by the owner (2026-11-18): region, staging and billing (D2–D4) to Phase 3, before any resource is created; the Auth test user stays untouched (D15); the Extensions API stays enabled and unchanged, assessed before Phase 3 (D17).
  - Billing, App Check and API-key console checks: OWNER-APPROVED DEFERRED / NOT VERIFIED. They are recorded in 07 before Phase 3 creates any resource (06 amendment B).
  - Decision IDs are listed in `06` §11; the closing evidence is in `docs/people-bridge/evidence/phase-1-closing-report.md`.
- 2026-11-18: authenticated read-only access to `citizen-india` verified. The project has no Firestore database, Storage bucket, rules or Functions, and 1 Auth user (a test number). The owner confirmed there were never production users or data (D16). The read-only check unintentionally enabled the Firebase Extensions API; it stays unchanged until the owner decides (D17).
- 2026-11-18: the owner approved the fresh-rebuild amendment `06` v0.5 (D1), built-in Flutter state management for the initial build (D9) and the documentation corrections (D11). This is **not** Phase 1 sign-off: Phase 1 stays OPEN; Phase 2 is NOT approved and blocked.
- 2026-11-17: the development environment was rebuilt after a Windows reinstall and the Android debug build verified at `825a847` (results in the roadmap's Phase 1 section). This is environment recovery only: Phase 1 stays open and Phase 2 must not start.

## Documents

- [docs/people-bridge/03-master-blueprint.md](docs/people-bridge/03-master-blueprint.md) — requirements, architecture, data plan, modules, security, roadmap, open decisions, acceptance criteria. The source of truth for planning.
- [docs/people-bridge/04-final-phase-roadmap.md](docs/people-bridge/04-final-phase-roadmap.md) — the only roadmap: phases 1–11 with scope, tests, gates and blocking decisions. Approved.
- [docs/people-bridge/05-development-environment.md](docs/people-bridge/05-development-environment.md) — tool inventory with verified status, Claude configuration map, re-verification steps and a **proposed** onboarding standard for any new tool, agent, skill, plugin or MCP server ([Recommended], awaiting owner approval).
- [docs/people-bridge/06-fresh-rebuild-amendment.md](docs/people-bridge/06-fresh-rebuild-amendment.md) — fresh-rebuild roadmap amendment, v0.5, approved 2026-11-18 (D1); replaces roadmap Phases 2–11 and revises Phase 1; the authoritative decision register (D1–D17, B3–B7).
- [docs/people-bridge/07-legacy-firebase-verification.md](docs/people-bridge/07-legacy-firebase-verification.md) — verified read-only inventory of the `citizen-india` Firebase project.
- [docs/people-bridge/08-consolidated-decision-report.md](docs/people-bridge/08-consolidated-decision-report.md) — recommendations for every open decision, a cost model and official sources; only D1, D9 and D11 approved (2026-11-18).
- [docs/people-bridge/01-audit-report.md](docs/people-bridge/01-audit-report.md) — full read-only audit of the code, preserved verbatim.
- [docs/people-bridge/02-architecture-roadmap-v1.md](docs/people-bridge/02-architecture-roadmap-v1.md) — first blueprint, superseded.

Read only the section needed for the task at hand.

## Project

- Dart pub workspace (root `pubspec.yaml`, one lockfile):
  - `apps/mobile` (`app_mobile`, Android and iOS);
  - `apps/admin` (`app_admin`, web);
  - `packages/core` (`app_core`);
  - `firebase/` (local emulator config, deny-all rules, never deployed in Phase 2).

  App IDs are `com.example.*` placeholders until D5. Firebase project `citizen-india`.
- The old app is retired from `main`. It is recoverable from the tag `legacy-app-final` (`6b5ec4e`). `packages/core/assets/data/india_districts.json` is development-only: reuse rights are OPEN and it is not bundled.
- State management (D9): built-in `ValueNotifier`/`ChangeNotifier` with constructor injection; no state-management package.
- Customers and partners; phone OTP sign-in; launch in one state, then nationwide across India.

## Confirmed decisions

- Partner profiles are kept when a user logs out.
- Logout stops LIVE, marks the partner offline, clears local session data and signs out.
- Permanent account deletion is a separate feature.
- Android and iOS are both in scope; multi-role accounts; subscriptions are paid by partners.
- No in-app voice or video calls.
- Each phase ends with its tests run, bugs fixed, regression checked and evidence saved before the next begins. Never report a test as passed unless it was executed.
- Keep Firebase and Hive unless evidence supports changing them; existing systems stay until a verified migration plan is approved.
- AI budget: at most ₹3,000 a month. Infrastructure budget is separate.

## Engineering rules

- Minimal prompts and token use; one module per session.
- No duplicate code, no unnecessary dependencies, remove only files verified as unused.
- Fast startup, smooth scrolling, low latency, efficient queries.
- Robust error handling; automated tests and regression prevention for every change.
- Never trade away security, testing or reliability to save tokens.
- Version control is mandatory: a phase is complete only after its commit is pushed to the approved private GitHub repository and verified. Never commit secrets, never force-push, never make the repository public without approval. Full rule in the roadmap.
- Never invent findings or decisions; mark each item as confirmed, recommended or open.

## Tooling and environment (verified 2026-11-17 and 2026-11-18, after a Windows reinstall)

- Windows user `welcome`; project `E:\MyWork\jober_india`.
- Flutter 3.50.0 (Dart 3.14.0, commit `ab2912035e160d9cad6306df307576da6128ebdb`) in `C:\dev\flutter`; Temurin JDK 21.0.13+9 in `C:\Users\welcome\jdks` (`JAVA_HOME`).
- Android SDK in `C:\Android\Sdk` (`ANDROID_HOME`, `ANDROID_SDK_ROOT`): platforms 31, 34, 35, 36; build-tools 36.0.0; NDK 28.2.13676358; CMake 3.22.1; licences accepted. Command-line tools only: no Android Studio, emulator or connected device.
- Caches outside `AppData`: `PUB_CACHE` is `C:\dev\pub-cache`; `UV_CACHE_DIR`, `UV_PYTHON_INSTALL_DIR` and `UV_TOOL_DIR` are under `C:\dev\uv\`.
- Claude Desktop is a packaged Windows app: anything it, or a command it runs, writes under `%LOCALAPPDATA%` or `%APPDATA%` is redirected into its private storage and is invisible to other programs. Install tools and caches outside `AppData`, and run interactive steps (licences, sign-ins) in a PowerShell opened from the Start menu.
- If Gradle cannot download its distribution because IPv6 DNS for GitHub fails, set `JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true` in that terminal only; it is not set permanently.
- Agent Skills: 25 from `addyosmani/agent-skills` in `.agents/skills`; copied (not linked) into `.claude/skills`.
- Graphify 0.9.108 (uv tool, Python 3.12.16): skill in `.claude/skills/graphify`, hooks in `.claude/settings.json`, code-only graph in `graphify-out/` (git-ignored; rebuilt 2026-11-18). Hooks verified in a fresh session.
- Also installed and verified 2026-11-18: uv 0.13.6, Node.js 24.22.2 / npm 11.19.1, GitHub CLI 2.103.3 (not signed in), Firebase CLI 15.34.2 (signed in by the owner, the project's sole Owner), FlutterFire CLI 1.4.1 (answer `n` to its update prompt).
- Firebase access: being signed in is **not** permission to write. Any Firebase or Google Cloud command that creates, changes, enables, deploys or deletes anything needs the owner's explicit approval first. Some read commands enable APIs automatically (`firebase ext:list` did), so check before running.
- Claude plugins (user level, `~/.claude/settings.json`): `firebase@firebase` 1.0.0 (Firebase MCP tools; its write tools need the same approval) and `ponytail@ponytail` 5.3.3.
- OmniRoute 3.8.53 runs on `127.0.0.1:20128` only, started by a user-level SessionStart hook; config in `C:\Users\welcome\.omniroute\.env` (never print it); no providers; not used for Claude model routing.
- Ponytail 5.3.3: restored on 2026-11-18 as the Claude plugin `ponytail@ponytail` from `github.com/DietrichGebert/ponytail` (commit `96608e0`); default mode `full` (no override set). Do not install the unrelated npm package `ponytail`.
- The former OmniRoute status panel is not verified as restored. Ponytail ships a band above the prompt (`hooks/band/register.tsx`) that may be it; this is unconfirmed.
- Full inventory, statuses and the onboarding standard: `docs/people-bridge/05-development-environment.md`.
  - **Mandatory now:** every rule already stated in this file, including the Engineering rules, the Firebase write-approval rule above, and the owner's approval for installs, sign-ins and paid services.
  - **Proposed, not yet binding:** the full 9-step onboarding standard in 05 §4 is [Recommended] until the owner approves it. Until then, follow it as best practice and report any step skipped.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.

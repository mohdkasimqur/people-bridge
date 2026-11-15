# People Bridge — project instructions

## Status

**Roadmap approved by the owner on 2026-11-15. Phase 1 (Foundation) is the current phase.** Work proceeds one phase at a time, in roadmap order; a phase is complete only when its gate is met, its commit is pushed and the owner has signed it off. Do not start a later phase early, and do not change Firebase, the database or production data without the step being in the current phase.

- Git: private repository `mohdkasimqur/people-bridge`, branch `main`; baseline commit `912d74b`.
- Phase 1 items still blocked on the owner: brand name and app IDs; Firebase console access or exports; whether live user data exists.

## Documents

- [docs/people-bridge/03-master-blueprint.md](docs/people-bridge/03-master-blueprint.md) — requirements, architecture, data plan, modules, security, roadmap, open decisions, acceptance criteria. The source of truth for planning.
- [docs/people-bridge/04-final-phase-roadmap.md](docs/people-bridge/04-final-phase-roadmap.md) — the only roadmap: phases 1–11 with scope, tests, gates and blocking decisions. Approved.
- [docs/people-bridge/01-audit-report.md](docs/people-bridge/01-audit-report.md) — full read-only audit of the code, preserved verbatim.
- [docs/people-bridge/02-architecture-roadmap-v1.md](docs/people-bridge/02-architecture-roadmap-v1.md) — first blueprint, superseded.

Read only the section needed for the task at hand.

## Project

- Flutter/Dart app for Android and iOS; folder and package are still named `jober_india`; Firebase project `citizen-india`.
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

## Tooling (verified 2026-11-14)

- Ponytail 5.3.3: enabled, default mode `full`, webhook off, status line not configured.
- Agent Skills: 25 from `addyosmani/agent-skills` in `.agents/skills`, linked in `.claude/skills`.
- Graphify 0.9.108: installed as a uv tool (Python 3.12); skill in `.claude/skills/graphify`; hooks in `.claude/settings.json`; code-only graph in `graphify-out/` (Dart supported).
- OmniRoute 3.8.53: installed globally with npm; started once for a test and stopped, not running; no providers or keys configured, not connected to Claude Code; model routing unchanged.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.

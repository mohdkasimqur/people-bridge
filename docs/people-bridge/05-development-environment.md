# People Bridge — development environment and tool onboarding

Living document. Last full verification: **2026-11-18** on Windows 11 Pro (user `welcome`), project `E:\MyWork\jober_india`, branch `main` at `825a847`.
Status key: **PASS** tested and working · **PARTIAL** installed, function or integration not fully verified · **FAIL** broken · **BLOCKED** needs owner sign-in, permission, hardware or information · **N/A** not needed now.

## 1. Inventory and verification

### Build toolchain

| Component | Version | Location | Status | Verification (2026-11-18) |
|---|---|---|---|---|
| Flutter / Dart | 3.50.0 (`ab29120`) / 3.14.0 | `C:\dev\flutter` | PASS | `flutter pub get --enforce-lockfile` exit 0 |
| `flutter analyze` | — | — | PASS | exit 0: 0 errors, 0 warnings, 114 infos (113 `deprecated_member_use`, 1 `use_build_context_synchronously`) |
| `flutter test` | — | `test/` (2 files) | PASS | 3 tests passed |
| `dart format` | — | — | PASS | tool works (check mode only, nothing rewritten). Code finding: 120 of 150 files are not formatted; formatting them needs the owner's approval |
| `dart pub outdated` | — | — | PASS | runs; no security advisories shown in its output; 3 discontinued transitive packages (`build_resolvers`, `build_runner_core`, `js`) |
| JDK (Temurin) | 21.0.13+9 | `C:\Users\welcome\jdks` (`JAVA_HOME`) | PASS | `java`/`javac` 21.0.13 |
| Gradle / AGP / Kotlin | 9.5.0 / 9.3.1 / 2.4.20 | wrapper | PASS | debug APK build exit 0 (up to date, 184,018,169 bytes); daemon stopped afterwards. Needs `JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true` in the build terminal only |
| Android SDK | platforms 31/34/35/36, build-tools 36.0.0, NDK 28.2.13676358, CMake 3.22.1 | `C:\Android\Sdk` | PASS | used by the build; `adb` 1.0.41 |
| Android device / emulator | — | — | BLOCKED | no device connected, no emulator installed; app never run on a device |
| iOS toolchain | — | — | BLOCKED | needs a Mac |

### Supporting CLIs

| Component | Version | Location | Status | Verification |
|---|---|---|---|---|
| Git | 2.56.1.windows.1 | `C:\Program Files\Git` | PASS | `git ls-remote origin` reaches the private repo through Git Credential Manager; `fsck` clean |
| GitHub CLI | 2.103.3 | `C:\dev\gh\bin` | BLOCKED | runs; not signed in (`gh auth login` is the owner's step) |
| Node.js / npm | 24.22.2 / 11.19.1 | `C:\dev\node`; globals `C:\dev\npm-global`, cache `C:\dev\npm-cache` | PASS | script run; `npm ping` OK. npm 11 only *warns* about install scripts; it does not block them |
| Firebase CLI | 15.34.2 | `C:\dev\npm-global` | BLOCKED | `--version`, `--help` and `login:list` work; no account signed in; no `.firebaserc` |
| FlutterFire CLI | 1.4.1 | `C:\dev\pub-cache\bin` | PASS | `--help` works. Every run asks to update to 1.5.0: answer `n` |
| uv | 0.13.6 | `C:\dev\uv\bin` | PASS | `uv run --python 3.12` works |
| Python | 3.12.16 (uv-managed) | `C:\dev\uv\python`; launcher `python3.12.exe` in `C:\Users\welcome\.local\bin` | PASS | `python3.12` with ssl/sqlite. Plain `python` opens the Microsoft Store alias |

### Claude integration

| Component | Status | Verification |
|---|---|---|
| Claude Desktop (Code tab) and the bundled Claude Code | PASS | no `claude` command on PATH; this is expected for the desktop app |
| Agent Skills: 25 from `addyosmani/agent-skills` in `.agents/skills`, copied into `.claude/skills`, plus `graphify` | PASS | every skill has a `SKILL.md`; all are listed in the session; `idea-refine` loaded from `.claude/skills` |
| Subagents (built-in agents only, none custom: e.g. Explore, Plan, general-purpose, claude-code-guide, statusline-setup) | PASS | an Explore agent ran a Graphify query, read `pubspec.yaml` and searched `lib`, with no refusals. No custom agents or slash commands are defined |
| Graphify 0.9.108 (uv tool `graphifyy`) and project hooks (`.claude/settings.json`: PreToolUse Read/Glob and Bash/Grep, SessionStart compact) | PASS | hooks succeed in this session and in a fresh one; `graphify query` works; graph rebuilt with `graphify update .` on 2026-11-18 (10,736 nodes; earlier build recorded the old `D:\` root). Backup in `C:\dev\backups\graphify-out-2026-11-18` |
| OmniRoute 3.8.53 | PASS | runs on `127.0.0.1:20128` (plus internal 20131/20132), loopback only, login required, no providers or keys. Config `C:\Users\welcome\.omniroute\.env` (private ACL; holds the password and the storage encryption key: back it up, never print it) |
| OmniRoute session-start hook (user `~/.claude/settings.json` → `~/.claude/hooks/omniroute-session-start.ps1`) | PASS | fresh session ran it; it starts OmniRoute through WMI only when unhealthy, uses a mutex against duplicates, refuses if the port is taken or the loopback setting is missing, and stays silent when healthy |
| OmniRoute model routing for Claude Code (`omniroute setup-claude`) | N/A | deliberately not configured |
| OmniRoute status panel in Claude | BLOCKED | original component unidentified; not in the official plugin marketplace or local files |
| Ponytail 5.3.3 | BLOCKED | original source unknown; the npm package `ponytail` is unrelated and must not be installed |
| MCP / connectors: Claude Docs, scheduled-tasks | PARTIAL | reported "connected" by the session connector status; no functional test run. No project `.mcp.json` and no user MCP servers. The built-in browser and Chrome extension were not tested |
| Official plugin marketplace (`claude-plugins-official`) | PARTIAL | registered in `~/.claude/settings.json`; no plugins installed |

### Security, audit and performance tooling

| Component | Status | Note |
|---|---|---|
| Dependency advisories (built into pub) | PASS | none shown by `dart pub outdated` |
| Secret scan of tracked files | PARTIAL | manual pattern check only: no private keys or tokens; Firebase client API keys in `android/app/google-services.json` and `lib/firebase_options.dart` are public identifiers by design — protect them with API-key restrictions and security rules |
| Dedicated scanners (OSV-Scanner, gitleaks) | BLOCKED | not installed; needs the owner's approval, then the onboarding standard in section 4 |
| Coverage, load and performance testing (lcov, k6) | N/A now | for the phases that add backend Functions and performance gates |

## 2. Claude configuration map

- User: `~/.claude/settings.json` (official marketplace; OmniRoute SessionStart hook) — backup `settings.json.bak-2026-11-18`; `~/.claude/hooks/omniroute-session-start.ps1`.
- Project: `.claude/settings.json` (Graphify hooks), `.claude/skills/` (26 skills), `.agents/skills/` (25 source copies), `CLAUDE.md`.
- Claude Desktop is a packaged app: anything it (or a command it runs) writes under `%APPDATA%`/`%LOCALAPPDATA%` is redirected to its private storage. Keep tools, caches and data outside `AppData`.

## 3. Re-verification after a restart, update or new tool

Run in a Start-menu PowerShell (no secrets are printed):

```powershell
flutter --version; java -version; node --version; npm --version; uv --version; python3.12 --version; graphify --version; gh --version; firebase --version
Invoke-RestMethod http://127.0.0.1:20128/api/monitoring/health
Get-NetTCPConnection -State Listen -LocalPort 20128 | Select-Object LocalAddress
Set-Location E:\MyWork\jober_india; flutter pub get --enforce-lockfile; flutter analyze --no-fatal-infos; flutter test
```

Expected: the versions in section 1, `healthy`, only `127.0.0.1`, analyze exit 0, all tests pass. Any difference is recorded here with its status.

## 4. Onboarding standard for any new tool, agent, skill, plugin or MCP server

**[Recommended]** — proposed 2026-11-18; becomes confirmed when the owner approves it.

A component is **not ready** because it installed. It is ready only when every step below is done and recorded in section 1.

1. **Source** — official publisher or repository identified; release at least two weeks old **[Recommended]**; checksum or registry integrity verified; licence acceptable. Unknown or look-alike sources: stop.
2. **Security** — review install scripts, network access, data it reads, persistence (services, Run keys, scheduled tasks) and required permissions. No secrets in output, logs or the repository.
3. **Compatibility** — Windows 11, the packaged Claude Desktop (no `AppData` installs), Flutter/Dart, JDK and Node versions in section 1.
4. **Install** — smallest footprint, under `C:\dev` or another non-`AppData` folder; no duplicate copies; existing PATH and settings preserved; configuration backed up before any edit.
5. **Authentication and permissions** — the owner performs sign-ins, licence acceptance and administrator prompts; record what is needed.
6. **Functional test** — a real, non-destructive command or workflow, not just `--version`.
7. **Integration test** — with Claude (fresh session, hooks, skills, agents), Graphify and OmniRoute, plus the project checks in section 3.
8. **Conflicts and cost** — no clash with existing hooks, ports, PATH or settings; any paid usage approved; AI spend within the ₹3,000/month budget.
9. **Document and report** — add a row to section 1 with version, location, configuration and verification, and report it as PASS, PARTIAL, FAIL or BLOCKED.

Never: production Firebase writes, real user data, public repository changes, commits or pushes outside an approved phase step.

# PhoneCall — Documentation Index

## What This Project Does
PhoneCall is a Flutter-based Android replacement dialer application that mirrors the functionality of a default phone app. It provides contacts management, a call history browser, a numeric keypad, a favorites tab, full in-call controls (mute, hold, speaker, DTMF), and an optional server-side call-log sync feature backed by a lightweight Node.js/Express server.

## Tech Stack
| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter (Dart), Material 3, Android SDK |
| Platform bridge | Pigeon (code-generated Dart ↔ Kotlin bindings) |
| Persistence (app) | shared_preferences |
| Server | Node.js 20+, Express 4, plain JSON file store |
| HTTP client | dart:http package |
| Phone number / text utils | intl, url_launcher |

## Quick Start
```bash
# --- Flutter app ---
flutter pub get
flutter run            # attach Android device or emulator first

# --- Sync server ---
cd server
npm install
npm start             # listens on port 6556 by default
```

## Documentation Map
| File | What it covers |
|------|---------------|
| [architecture.md](architecture.md) | System design, component diagram, data flow |
| [file-map.md](file-map.md) | Per-file reference for every source file |
| [api.md](api.md) | Public Dart functions, Pigeon APIs, server REST endpoints |
| [data-models.md](data-models.md) | Pigeon data classes, server JSON schemas |
| [configuration.md](configuration.md) | Env vars, preferences keys, compile-time config |
| [workflows.md](workflows.md) | Build, run, test, deploy runbooks |
| [decisions.md](decisions.md) | Design rationale and trade-offs |
| [ai-agent-guide.md](ai-agent-guide.md) | Operational guide for AI agents |

## For AI Agents
Read `ai-agent-guide.md` before making any changes.

## Last Updated
2026-04-14

---

## Documentation Update Checklist

After **any** code change, update these docs:

- [ ] `file-map.md` — update the entry for every changed/added file
- [ ] `api.md` — update any changed function signatures or new exports
- [ ] `data-models.md` — update any changed or new types/schemas
- [ ] `configuration.md` — add any new env vars or preference keys
- [ ] `architecture.md` — update if a new module, service, or data flow was introduced
- [ ] `workflows.md` — update if build/run/test steps changed
- [ ] `ai-agent-guide.md` — update gotchas or conventions if you discovered something new
- [ ] `docs/README.md` — bump the `Last Updated` date

**Rule**: Docs must be updated in the same commit/session as the code change.

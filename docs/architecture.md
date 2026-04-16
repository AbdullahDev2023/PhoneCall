# Architecture

## High-Level Overview
PhoneCall replaces the system dialer on Android. The Flutter application communicates with Android platform APIs through Pigeon-generated type-safe bindings. An optional companion Node.js server receives call-log uploads from the device and exposes a web admin UI for viewing and renaming devices.

## Component Diagram
```
┌──────────────────────────────────────────────────────────┐
│                    Flutter App (Dart)                    │
│                                                          │
│  PhoneCallApp (UI)                                       │
│     └─ HomeScreen (tabs: Favorites | Recents |           │
│                          Contacts  | Keypad)             │
│     └─ InCallScreen                                      │
│     └─ OnboardingScreen                                  │
│                                                          │
│  PhoneController (ChangeNotifier, state hub)             │
│     ├─ DialerPlatformApi  ──────────────────────────┐   │
│     ├─ ContactsPlatformApi ─────────────────────────┤   │
│     ├─ RecentsPlatformApi ──────────────────────────┤   │
│     └─ PhoneCallServerApi (HTTP)                    │   │
└─────────────────────────────────────────────────────┼───┘
                      Pigeon JNI bridge                │
┌─────────────────────────────────────────────────────┼───┐
│                  Android (Kotlin)                   │   │
│  PlatformApi.g.kt  ◄────────────────────────────────┘   │
│  (DialerPlatformApi, ContactsPlatformApi,                │
│   RecentsPlatformApi, CallStateFlutterApi)               │
└──────────────────────────────────────────────────────────┘
                           │ HTTP (REST)
┌──────────────────────────▼───────────────────────────────┐
│        Node.js / Express Server (server/src/index.js)    │
│  Routes: /api/devices, /api/devices/:id/call-logs        │
│  Admin UI: /admin  (server-rendered HTML)                │
│  Store: JSON file  (server/data/store.json)              │
└──────────────────────────────────────────────────────────┘
```

## Data Flow

### App startup
1. `main()` calls `PhonePlatform.initialize()` — registers `CallStateBridge` as the Flutter-side Pigeon receiver.
2. `PhoneController.initialize()` loads SharedPreferences (device ID, server URL, preferred SIM), subscribes to `CallStateBridge.stream`, then calls `refreshAll()`.
3. `refreshAll()` fetches permissions, default-dialer status, contacts, recents, and the server device profile in parallel.

### Placing a call
1. User taps a call button → `startCallFromNumber()` in `call_actions.dart`.
2. If multiple SIM accounts exist and no preferred is set, a bottom sheet lets the user pick.
3. `PhoneController.placeCall()` calls `DialerPlatformApi.placeCall()` → Kotlin handler.
4. Android fires `onCallStateChanged` back through `CallStateFlutterApi` → `CallStateBridge` → `PhoneController._handleCallStateUpdate()`.
5. `controller.hasActiveCall` becomes `true` → `InCallScreen` overlays the main scaffold.

### Call-log sync
1. After `refreshRecentCalls()`, `syncRecentCallsToServer()` is called automatically if `callLogGranted && hasServerSync`.
2. HTTP POST to `/api/devices/:deviceId/call-logs` with the full local call list.
3. Server upserts each log entry by composite key `(deviceId, id)` into the JSON store and responds with updated device stats.

## Layer Breakdown
- **UI layer** — `lib/app/phone_call_app.dart`, `lib/app/screens/`, `lib/app/widgets/`
- **State / controller layer** — `lib/app/phone_controller.dart`
- **Platform bridge** — `lib/platform/phone_platform.dart`, `lib/platform/generated/platform_api.g.dart`
- **Core utilities** — `lib/core/phone_formatters.dart`
- **Server** — `server/src/index.js` (self-contained, no ORM)

## Key Design Patterns
- **ChangeNotifier + ListenableBuilder** — `PhoneController` is the single state atom; widgets rebuild through `ListenableBuilder`.
- **Pigeon** — All Flutter↔Android calls are strongly typed; no dynamic method channels.
- **Singleton bridge** — `CallStateBridge.instance` is a singleton that converts Pigeon callbacks into a Dart `Stream`, decoupling the UI from the Android callback timing.

## External Dependencies
| Dep | Used for |
|-----|---------|
| `intl` | Date/time formatting in `phone_formatters.dart` |
| `http` | REST calls to PhoneCall sync server |
| `url_launcher` | Launching `sms:` URIs |
| `shared_preferences` | Persisting device ID, server URL, preferred SIM |
| `pigeon` (dev) | Generating type-safe platform channel bindings |
| `express` (server) | HTTP routing for the Node.js sync server |

## Known Limitations / Tech Debt
- The server stores all data in a single JSON file (`store.json`); no pagination or archival, so large call histories will cause the file to grow without bound.
- No authentication on the server — anyone who knows the device ID can read or overwrite its call logs.
- iOS is not supported (Pigeon Kotlin output only; no Swift counterpart generated).
- The `lib/platform/generated/platform_api.g.dart` file is auto-generated — do not edit by hand; re-run pigeon to regenerate.

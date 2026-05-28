# Totalmote — Universal Remote Control (Flutter)

## Project Purpose
A universal TV remote control app targeting **iOS, Android, and Desktop** (primary focus: mobile phones). Supports multiple TV brands by loading YAML config files from `assets/`. Currently supports Samsung (WebSocket/WSS) and LG WebOS.

## Architecture

### YAML-driven Device Configs (`assets/*.yaml`)
Each TV brand has one YAML file that defines:
- `brand`, `model_name`, `protocol`, `description`
- `connection`: protocol, port, path, URI template
- `authentication`: pairing type, client key storage
- `scan`: discovery ports and timeout
- `payloads`: command templates (remote_key, text_input, launch_app)
- `keys`: logical key name → protocol-specific key/URI
- `features`: capability flags
- `custom_buttons` (future): user-defined button → action mappings

### Service Layer (`lib/services/`)
- `GenericTVService` — abstract base for all TV services
- `WSTVService` — WebSocket implementation (Samsung)
- `RestTVService` — REST HTTP implementation
- `GoogleTVService` — Google/Android TV ADB
- `TVServiceFactory` — selects correct service based on YAML `protocol` field

### Models (`lib/models/`)
- `TVConfig` — parsed YAML config with payload generation
- `TVDevice` — discovered TV device on local network

### Widgets (`lib/widgets/`)
- `DPadCard`, `ControlButtonsCard`, `MediaControlsCard`, `AppsCard`
- `ConnectionCard`, `IPAddressTextField`
- `KeyboardWidget`, `RemoteButton`

### Screens (`lib/screens/`)
- `RemoteControlScreen` — main screen with brand selector, connect, and remote layout
- `KeyboardScreen` — text input
- `YamlViewerScreen` — debug view of loaded YAML

### Utils
- `AppPreferences` — shared_preferences for last-used TV
- `AppLogger` — structured logging via `logger` package

## Key Conventions
- Flutter with Material 3, dark/light theme support
- Dart null safety, no `dynamic` where avoidable
- YAML loaded from assets via `rootBundle` at runtime
- Custom buttons stored in `shared_preferences` (future feature)
- New TV brands added by dropping a YAML file into `assets/` and registering in `pubspec.yaml`
- Services are stateless except for the active WebSocket/HTTP connection

## Roadmap Goals
1. **Custom button support**: users can add buttons in the UI and map them to a YAML-defined action
2. **Per-brand YAML hot-reload**: discover and load new YAML files without rebuild
3. **Device discovery/scan**: auto-detect TVs on local network
4. **More TV protocols**: Roku (ECP), Apple TV (MRP), Chromecast, Fire TV
5. **Tablet/Desktop layouts**: responsive layouts adapting to screen size
6. **Favorites / macros**: sequence of commands assigned to one button

# Totalmote - Universal TV Remote

A universal remote control application built with Flutter that supports Samsung, LG WebOS, and Android TV devices.

## Features

- **Multi-brand support**: Samsung, LG WebOS, and Android TV
- **Network discovery**: Automatic TV scanning on local network
- **WebSocket control**: Real-time communication with TVs
- **Text input**: Send text to TV for searches
- **Full remote functionality**: Navigation, media controls, volume, channels
- **Connection memory**: Remembers last connected TV

## Supported TV Brands

- **Samsung Smart TV** (2016+) - WebSocket API
- **LG WebOS TV** - WebOS API
- **Android TV** - ADB (requires developer mode)

## Prerequisites

### Development Environment

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio or VS Code with Flutter extensions
- Git

### Runtime Requirements

- TV and mobile device on the same WiFi network
- For Android TV: ADB debugging enabled on TV

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/totalmote.git
cd totalmote
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Installation

```bash
flutter doctor
```

## Building the Application

### Android APK

#### Debug Build

```bash
flutter build apk --debug
```

**Output**: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release Build

```bash
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

#### Split APK per ABI (smaller size)

```bash
flutter build apk --split-per-abi --release
```

**Output**: Multiple APKs in `build/app/outputs/flutter-apk/`
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit Intel)

### Android App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

### iOS Build

```bash
flutter build ios --release
```

**Note**: iOS builds require a Mac with Xcode installed.

## Running the Application

### Development Mode

```bash
flutter run
```

### Install APK on Device

```bash
flutter install
```

Or manually:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

```
totalmote/
├── lib/
│   ├── config/
│   │   └── tv_config_loader.dart       # YAML config loader
│   ├── models/
│   │   ├── tv_config_model.dart        # TV configuration model
│   │   └── tv_device.dart              # TV device model
│   ├── screens/
│   │   └── remote_control_screen.dart  # Main remote UI
│   ├── services/
│   │   ├── generic_tv_service.dart     # WebSocket TV service
│   │   └── tv_service_factory.dart     # Service factory
│   ├── utils/
│   │   ├── app_logger.dart             # Logging utility
│   │   └── app_preferences.dart        # Shared preferences
│   ├── widgets/
│   │   ├── connection_card.dart        # Connection UI
│   │   ├── control_buttons_card.dart   # Control buttons
│   │   ├── dpad_card.dart              # D-Pad navigation
│   │   ├── media_controls_card.dart    # Media controls
│   │   ├── remote_button.dart          # Reusable button
│   │   └── text_input_card.dart        # Text input UI
│   └── main.dart                       # App entry point
├── assets/
│   ├── samsung.yaml                    # Samsung TV config
│   ├── lg_webos.yaml                   # LG WebOS config
│   └── android_tv.yaml                 # Android TV config
├── android/                            # Android-specific files
├── ios/                                # iOS-specific files
└── pubspec.yaml                        # Dependencies
```

## Configuration

TV configurations are stored in YAML files in the `assets/` directory. Each configuration defines:

- Connection protocol (WebSocket/ADB)
- Authentication method
- Key mappings
- Command payloads

### Adding a New TV Brand

1. Create `assets/yourbrand.yaml`
2. Define connection, keys, and payloads
3. Add brand to `assets/` in `pubspec.yaml`
4. Restart the app

## Dependencies

Key packages:

- `web_socket_channel`: WebSocket communication
- `yaml`: YAML configuration parsing
- `shared_preferences`: Local storage
- `logger`: Logging
- `network_info_plus`: Network information

See `pubspec.yaml` for complete list.

## Troubleshooting

### TV Not Found During Scan

- Ensure TV and phone are on the same WiFi network
- Check TV is powered on and WebSocket API is enabled
- Try manual IP entry

### Connection Fails

**Samsung TV:**
- Enable "External Device Manager" in TV settings
- Allow connection prompt on TV screen

**LG WebOS:**
- Accept pairing request on TV screen

**Android TV:**
- Enable Developer Mode
- Enable ADB debugging in Developer Options
- Connect to TV IP once via `adb connect <TV_IP>:5555`

### "SSL Certificate Error"

Samsung TVs use self-signed certificates. The app ignores SSL validation for Samsung connections.

## Development

### Run Tests

```bash
flutter test
```

### Run with Logging

```bash
flutter run --verbose
```

### Hot Reload During Development

Press `r` in terminal after making changes.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Samsung Smart TV API documentation
- LG WebOS TV API documentation
- Flutter community

## Support

For issues and questions:

- Open an issue on GitHub
- Check existing issues for solutions

## Roadmap

- [ ] iOS support
- [ ] Voice control integration
- [ ] Custom button layouts
- [ ] Multi-TV management
- [ ] IR blaster support
- [ ] Widget support
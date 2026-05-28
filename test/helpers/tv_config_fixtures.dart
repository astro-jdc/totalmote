import 'package:totalmote/models/tv_config_model.dart';

/// Builds a minimal [TVConfig] for use in tests.
/// [extraKeys] merges additional key entries on top of the defaults.
TVConfig makeSamsungConfig({Map<String, dynamic>? extraKeys}) {
  return TVConfig(
    brand: 'Samsung',
    modelName: 'Test TV',
    protocol: 'websocket',
    description: 'Test Samsung config',
    connection: ConnectionConfig(
      protocol: 'wss',
      port: 8002,
      timeoutSeconds: 10,
      requiresSsl: false,
      ignoreSslCert: false,
    ),
    authentication: AuthenticationConfig(
      type: 'basic',
      requiresPairing: false,
      pairingPromptOnTv: false,
    ),
    scan: ScanConfig(ports: [8002], timeoutMs: 500),
    commands: {},
    payloads: {},
    keys: {
      // Parameterized pattern — the change under test
      'key_code': 'KEY_{arg}',
      // Named keys
      'power': 'KEY_POWER',
      'volume_up': 'KEY_VOLUP',
      'volume_down': 'KEY_VOLDOWN',
      'mute': 'KEY_MUTE',
      'up': 'KEY_UP',
      'down': 'KEY_DOWN',
      'left': 'KEY_LEFT',
      'right': 'KEY_RIGHT',
      'enter': 'KEY_ENTER',
      'back': 'KEY_RETURN',
      'backspace': 'KEY_BACKSPACE',
      'space': 'KEY_SPACE',
      ...?extraKeys,
    },
    features: FeaturesConfig(
      supportsTextInput: true,
      supportsMouse: false,
      supportsVoice: false,
      supportsApps: false,
      supportsPowerOn: false,
    ),
  );
}

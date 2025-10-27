import 'dart:convert';

class TVConfig {
  final String brand;
  final String modelName;
  final String protocol;
  final String description;
  final ConnectionConfig connection;
  final AuthenticationConfig authentication;
  final ScanConfig scan;
  final Map<String, dynamic> commands;
  final Map<String, dynamic> keys;
  final FeaturesConfig features;
  final Map<String, dynamic>? registration;

  TVConfig({
    required this.brand,
    required this.modelName,
    required this.protocol,
    required this.description,
    required this.connection,
    required this.authentication,
    required this.scan,
    required this.commands,
    required this.keys,
    required this.features,
    this.registration,
  });

  factory TVConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return TVConfig(
      brand: yaml['brand'] as String,
      modelName: yaml['model_name'] as String,
      protocol: yaml['protocol'] as String,
      description: yaml['description'] as String,
      connection: ConnectionConfig.fromYaml(yaml['connection']),
      authentication: AuthenticationConfig.fromYaml(yaml['authentication']),
      scan: ScanConfig.fromYaml(yaml['scan']),
      commands: Map<String, dynamic>.from(yaml['commands']),
      keys: Map<String, dynamic>.from(yaml['keys']),
      features: FeaturesConfig.fromYaml(yaml['features']),
      registration: yaml['registration'] != null
          ? Map<String, dynamic>.from(yaml['registration'])
          : null,
    );
  }

  String? getKeyCode(String key) {
    return keys[key]?.toString();
  }
}

class ConnectionConfig {
  final String protocol;
  final int port;
  final int? fallbackPort;
  final String? path;
  final String? uriTemplate;
  final int timeoutSeconds;
  final int? pingIntervalSeconds;
  final bool requiresSsl;
  final bool ignoreSslCert;

  ConnectionConfig({
    required this.protocol,
    required this.port,
    this.fallbackPort,
    this.path,
    this.uriTemplate,
    required this.timeoutSeconds,
    this.pingIntervalSeconds,
    required this.requiresSsl,
    required this.ignoreSslCert,
  });

  factory ConnectionConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return ConnectionConfig(
      protocol: yaml['protocol'] as String,
      port: yaml['port'] as int,
      fallbackPort: yaml['fallback_port'] as int?,
      path: yaml['path'] as String?,
      uriTemplate: yaml['uri_template'] as String?,
      timeoutSeconds: yaml['timeout_seconds'] as int,
      pingIntervalSeconds: yaml['ping_interval_seconds'] as int?,
      requiresSsl: yaml['requires_ssl'] as bool? ?? false,
      ignoreSslCert: yaml['ignore_ssl_cert'] as bool? ?? false,
    );
  }

  String buildUri({ required String ipAddress, String? appName,}) {
    if (uriTemplate != null && uriTemplate!.isNotEmpty) {
      // Use template
      String uri = uriTemplate!
          .replaceAll('{protocol}', protocol)
          .replaceAll('{ip}', ipAddress)
          .replaceAll('{port}', port.toString())
          .replaceAll('{path}', path ?? '');

      // Handle app name encoding if needed
      if (appName != null && uri.contains('{app_name_base64}')) {
        final encodedName = base64.encode(utf8.encode(appName));
        uri = uri.replaceAll('{app_name_base64}', encodedName);
      }

      return uri;
    }

    // Fallback to manual construction
    return '$protocol://$ipAddress:$port${path ?? ''}';
  }
}

class AuthenticationConfig {
  final String type;
  final bool requiresPairing;
  final bool pairingPromptOnTv;
  final String? appNameEncoding;
  final bool? clientKeyStorage;
  final bool? requiresDeveloperMode;

  AuthenticationConfig({
    required this.type,
    required this.requiresPairing,
    required this.pairingPromptOnTv,
    this.appNameEncoding,
    this.clientKeyStorage,
    this.requiresDeveloperMode,
  });

  factory AuthenticationConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return AuthenticationConfig(
      type: yaml['type'] as String,
      requiresPairing: yaml['requires_pairing'] as bool? ?? false,
      pairingPromptOnTv: yaml['pairing_prompt_on_tv'] as bool? ?? false,
      appNameEncoding: yaml['app_name_encoding'] as String?,
      clientKeyStorage: yaml['client_key_storage'] as bool?,
      requiresDeveloperMode: yaml['requires_developer_mode'] as bool?,
    );
  }
}

class ScanConfig {
  final List<int> ports;
  final int timeoutMs;

  ScanConfig({
    required this.ports,
    required this.timeoutMs,
  });

  factory ScanConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return ScanConfig(
      ports: (yaml['ports'] as List).map((e) => e as int).toList(),
      timeoutMs: yaml['timeout_ms'] as int,
    );
  }
}

class FeaturesConfig {
  final bool supportsTextInput;
  final bool supportsMouse;
  final bool supportsVoice;
  final bool supportsApps;
  final bool supportsPowerOn;

  FeaturesConfig({
    required this.supportsTextInput,
    required this.supportsMouse,
    required this.supportsVoice,
    required this.supportsApps,
    required this.supportsPowerOn,
  });

  factory FeaturesConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return FeaturesConfig(
      supportsTextInput: yaml['supports_text_input'] as bool? ?? false,
      supportsMouse: yaml['supports_mouse'] as bool? ?? false,
      supportsVoice: yaml['supports_voice'] as bool? ?? false,
      supportsApps: yaml['supports_apps'] as bool? ?? false,
      supportsPowerOn: yaml['supports_power_on'] as bool? ?? false,
    );
  }
}
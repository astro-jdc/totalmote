import 'dart:io';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tv_device.dart';
import '../models/tv_config_model.dart';
import '../utils/app_logger.dart';

const String appName = "Totalmote";

class GenericTVService {
  final TVConfig config;

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _clientKey = ''; // For LG TVs

  Function(String)? onStatusChanged;
  Function(bool)? onConnectionChanged;

  GenericTVService(this.config);

  bool get isConnected => _isConnected;

  // Helper function to create insecure HTTP client for SSL bypass
  HttpClient getInsecureHttpClient() {
    HttpClient httpClient = HttpClient();
    if (config.connection.ignoreSslCert) {
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return httpClient;
  }

  Future<List<TVDevice>> scanForTVs(Function(String) onProgress) async {
    List<TVDevice> discoveredTVs = [];

    try {
      final interfaces = await NetworkInterface.list();
      String? localIP;

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.')) {
              localIP = addr.address;
              break;
            }
          }
        }
        if (localIP != null) break;
      }

      if (localIP == null) {
        onProgress('Could not determine local IP address');
        logger.w('Could not determine local IP address');
        return discoveredTVs;
      }

      final parts = localIP.split('.');
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

      onProgress('Scanning $subnet.0/24 for ${config.brand} TVs...');
      logger.i('Scanning subnet: $subnet.0/24');

      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        futures.add(_checkTVAtIP(ip, discoveredTVs));
      }

      await Future.wait(futures);
      logger.i('Scan complete. Found ${discoveredTVs.length} TV(s)');
    } catch (e) {
      onProgress('Scan error: $e');
      logger.e('Scan error', error: e);
    }

    return discoveredTVs;
  }

  Future<void> _checkTVAtIP(String ip, List<TVDevice> discoveredTVs) async {
    for (var port in config.scan.ports) {
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: Duration(milliseconds: config.scan.timeoutMs),
        );

        socket.destroy();
        discoveredTVs.add(TVDevice(
          name: config.modelName,
          ipAddress: ip,
          port: port,
        ));
        logger.d('Found ${config.brand} TV at: $ip:$port');
        break; // Found one, no need to check other ports
      } catch (e) {
        // Not reachable on this port
      }
    }
  }

  Future<void> connectToTV(String ipAddress, String tvName) async {
    logger.i('═══════════════════════════════════════════════════════');
    logger.i('Starting ${config.brand} connection to $ipAddress');
    logger.i('═══════════════════════════════════════════════════════');

    if (ipAddress.isEmpty) {
      logger.w('IP address is empty');
      onStatusChanged?.call('Please enter TV IP address');
      return;
    }

    if (ipAddress == 'demo' || ipAddress == '0.0.0.0') {
      logger.d('Demo mode activated');
      _isConnected = true;
      onConnectionChanged?.call(true);
      onStatusChanged?.call('Demo Mode - No real TV connection');
      return;
    }

    // Build connection URI based on config
    final protocol = config.connection.protocol;
    final port = config.connection.port;
    final path = config.connection.path ?? '';

    String uriString;
    if (config.brand == 'Samsung') {
      String base64Name = base64.encode(utf8.encode(appName));
      uriString = '$protocol://$ipAddress:$port$path?name="$base64Name"';
    } else {
      uriString = '$protocol://$ipAddress:$port$path';
    }

    final Uri uri = Uri.parse(uriString);

    onStatusChanged?.call('Connecting...');
    logger.i('Connecting to: $uriString');

    try {
      WebSocketChannel channel;

      if (config.connection.requiresSsl && config.connection.ignoreSslCert) {
        final HttpClient insecureClient = getInsecureHttpClient();
        channel = IOWebSocketChannel.connect(
          uri,
          customClient: insecureClient,
          pingInterval: config.connection.pingIntervalSeconds != null
              ? Duration(seconds: config.connection.pingIntervalSeconds!)
              : null,
        );
      } else {
        channel = IOWebSocketChannel.connect(
          uri,
          pingInterval: config.connection.pingIntervalSeconds != null
              ? Duration(seconds: config.connection.pingIntervalSeconds!)
              : null,
        );
      }

      await channel.ready;

      _channel = channel;

      logger.i('✓ WebSocket connection established');

      // Handle LG registration if needed
      if (config.brand == 'LG' && config.registration != null) {
        _sendLGRegistration();
      } else {
        _isConnected = true;
        onConnectionChanged?.call(true);
        onStatusChanged?.call('Connected to $tvName!');
      }

      _channel!.stream.listen(
            (data) {
          logger.d('TV Message: $data');
          _handleTVMessage(data);
        },
        onError: (error) {
          logger.e('WebSocket error', error: error);
          disconnect('Connection error: ${error.toString()}');
        },
        onDone: () {
          logger.i('WebSocket connection closed by TV');
          disconnect('Disconnected from TV.');
        },
      );
    } catch (e) {
      logger.e('Failed to connect to TV', error: e);
      disconnect('Failed to connect. Check IP, Port, and Network. Error: $e');
    }
  }

  void _sendLGRegistration() {
    if (config.registration == null) return;

    final registrationPayload = Map<String, dynamic>.from(config.registration!);

    if (_clientKey.isNotEmpty) {
      registrationPayload['payload']['client-key'] = _clientKey;
    }

    _channel!.sink.add(jsonEncode(registrationPayload));
    logger.d('Sent LG registration request');
  }

  void _handleTVMessage(dynamic data) {
    try {
      final message = jsonDecode(data);

      // Handle LG registration response
      if (message['type'] == 'registered') {
        _clientKey = message['payload']?['client-key'] ?? '';
        _isConnected = true;
        onConnectionChanged?.call(true);
        onStatusChanged?.call('Connected and paired!');
        logger.i('Registration successful. Client key: $_clientKey');
        // TODO: Save _clientKey to persistent storage
      } else if (message['type'] == 'error') {
        logger.e('TV error: ${message['error']}');
        onStatusChanged?.call('Error: ${message['error']}');
      }
    } catch (e) {
      logger.w('Could not parse TV message: $e');
    }
  }

  void disconnect([String? message]) {
    _channel?.sink.close(1000, 'User Disconnected');
    _isConnected = false;
    onConnectionChanged?.call(false);
    onStatusChanged?.call(message ?? 'Disconnected');
    _channel = null;
    logger.i('Disconnected from ${config.brand} TV');
  }

  void sendKey(String key) {
    if (_channel == null || !_isConnected) {
      logger.w('Cannot send command - not connected to TV');
      onStatusChanged?.call('Cannot send command: Not connected.');
      return;
    }

    // Get the actual key code from config
    final keyCode = config.getKeyCode(key);
    if (keyCode == null) {
      logger.w('Unknown key: $key for ${config.brand}');
      return;
    }

    // Build command based on brand
    dynamic payload;

    if (config.brand == 'Samsung') {
      final commandTemplate = config.commands['remote_key'];
      payload = {
        'method': commandTemplate['method'],
        'params': {
          'Cmd': commandTemplate['params']['Cmd'],
          'DataOfCmd': keyCode,
          'Option': commandTemplate['params']['Option'],
          'TypeOfRemote': commandTemplate['params']['TypeOfRemote'],
        },
      };
    } else if (config.brand == 'LG') {
      payload = {
        'type': 'request',
        'id': 'button_${DateTime.now().millisecondsSinceEpoch}',
        'uri': keyCode,
      };

      // Add payload for special commands
      if (keyCode.contains('setMute')) {
        payload['payload'] = {'mute': true};
      } else if (keyCode.contains('launch') && key == 'home') {
        payload['payload'] = {'id': 'com.webos.app.home'};
      }
    }

    if (payload != null) {
      _channel!.sink.add(jsonEncode(payload));
      logger.d('Sent command: $key -> $keyCode');
    }
  }

  void sendText(String text) {
    if (_channel == null || !_isConnected) {
      logger.w('Cannot send text - not connected to TV');
      throw Exception('Not connected to TV');
    }

    if (!config.features.supportsTextInput) {
      logger.w('${config.brand} does not support text input');
      throw Exception('Text input not supported');
    }

    dynamic command;

    if (config.brand == 'Samsung') {
      final encodedText = base64.encode(utf8.encode(text));
      final commandTemplate = config.commands['text_input'];

      command = {
        'method': commandTemplate['method'],
        'params': {
          'Cmd': commandTemplate['params']['Cmd'],
          'DataOfCmd': encodedText,
          'Option': commandTemplate['params']['Option'],
          'TypeOfRemote': commandTemplate['params']['TypeOfRemote'],
        }
      };
    } else if (config.brand == 'LG') {
      command = {
        'type': 'request',
        'id': 'text_${DateTime.now().millisecondsSinceEpoch}',
        'uri': 'ssap://com.webos.service.ime/insertText',
        'payload': {
          'text': text,
          'replace': 0,
        }
      };
    }

    if (command != null) {
      _channel!.sink.add(json.encode(command));
      logger.d('Sent text: $text');
    }
  }

  void dispose() {
    _channel?.sink.close();
    logger.i('${config.brand} TVService disposed');
  }
}
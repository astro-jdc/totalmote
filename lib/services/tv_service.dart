import 'dart:io';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tv_device.dart';

const String appName = "Totalmote";
const int tvWsPort = 8002;
const String wsPath = "/api/v2/channels/samsung.remote.control";

class TVService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Function(String)? onStatusChanged;
  Function(bool)? onConnectionChanged;

  bool get isConnected => _isConnected;

  // Helper function to create a custom HttpClient that bypasses SSL checks
  HttpClient getInsecureHttpClient() {
    HttpClient httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
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
        return discoveredTVs;
      }

      final parts = localIP.split('.');
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

      onProgress('Scanning $subnet.0/24...');

      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        futures.add(_checkTVAtIP(ip, discoveredTVs));
      }

      await Future.wait(futures);
    } catch (e) {
      onProgress('Scan error: $e');
    }

    return discoveredTVs;
  }

  Future<void> _checkTVAtIP(String ip, List<TVDevice> discoveredTVs) async {
    try {
      final socket = await Socket.connect(
        ip,
        8001,
        timeout: const Duration(milliseconds: 500),
      );

      socket.destroy();
      discoveredTVs.add(TVDevice(
        name: 'Samsung TV',
        ipAddress: ip,
      ));
    } catch (e) {
      // Not a TV or not reachable
    }
  }

  Future<void> connectToTV(String ipAddress, String tvName) async {
    print('═══════════════════════════════════════════════════════');
    print('DEBUG: Starting connection to $ipAddress');
    print('═══════════════════════════════════════════════════════');

    if (ipAddress.isEmpty) {
      print('DEBUG: IP address is empty');
      onStatusChanged?.call('Please enter TV IP address');
      return;
    }

    if (ipAddress == 'demo' || ipAddress == '0.0.0.0') {
      print('DEBUG: Demo mode activated');
      _isConnected = true;
      onConnectionChanged?.call(true);
      onStatusChanged?.call('Demo Mode - No real TV connection');
      return;
    }

    String base64Name = base64.encode(utf8.encode(appName));
    final String uriString =
        'wss://$ipAddress:$tvWsPort$wsPath?name="$base64Name"';
    final Uri uri = Uri.parse(uriString);

    onStatusChanged?.call('Connecting...');

    try {
      final HttpClient insecureClient = getInsecureHttpClient();

      final channel = IOWebSocketChannel.connect(
        uri,
        customClient: insecureClient,
        pingInterval: const Duration(seconds: 15),
      );

      await channel.ready;

      _channel = channel;
      _isConnected = true;
      onConnectionChanged?.call(true);
      onStatusChanged?.call('Connected to $tvName!');

      print('DEBUG: WebSocket connection established.');

      _channel!.stream.listen(
            (data) {
          print('TV Message: $data');
        },
        onError: (error) {
          print('ERROR: WebSocket error: $error');
          disconnect('Connection error: ${error.toString()}');
        },
        onDone: () {
          print('DEBUG: WebSocket connection closed by TV.');
          disconnect('Disconnected from TV.');
        },
      );
    } catch (e) {
      print('FATAL ERROR: Failed to connect to TV: $e');
      disconnect('Failed to connect. Check IP, Port, and Network. Error: $e');
    }
  }

  void disconnect([String? message]) {
    _channel?.sink.close(1000, 'User Disconnected');
    _isConnected = false;
    onConnectionChanged?.call(false);
    onStatusChanged?.call(message ?? 'Disconnected');
    _channel = null;
  }

  void sendKey(String key) {
    if (_channel != null && _isConnected) {
      final payload = {
        'method': 'ms.remote.control',
        'params': {
          'Cmd': 'Click',
          'DataOfCmd': key,
          'Option': 'false',
          'TypeOfRemote': 'SendRemoteKey',
        },
      };
      _channel!.sink.add(jsonEncode(payload));
      print('Sent command: $key');
    } else {
      print('Error: Not connected to TV.');
      onStatusChanged?.call('Cannot send command: Not connected.');
    }
  }

  void sendText(String text) {
    if (_channel == null || !_isConnected) {
      throw Exception('Not connected to TV');
    }

    final encodedText = base64.encode(utf8.encode(text));

    final command = {
      'method': 'ms.remote.control',
      'params': {
        'Cmd': 'Click',
        'DataOfCmd': encodedText,
        'Option': 'false',
        'TypeOfRemote': 'SendInputString'
      }
    };

    _channel!.sink.add(json.encode(command));
  }

  void dispose() {
    _channel?.sink.close();
  }
}
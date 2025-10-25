import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const SamsungTVRemoteApp());
}

const String appName="Totalmote";
const int tvWsPort = 8002;
const String wsPath = "/api/v2/channels/samsung.remote.control";

class TVDevice {
  final String name;
  final String ipAddress;
  final int port;

  TVDevice({
    required this.name,
    required this.ipAddress,
    this.port = 8001,
  });
}

class SamsungTVRemoteApp extends StatelessWidget {
  const SamsungTVRemoteApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      ),
      home: const RemoteControlScreen(),
    );
  }
}

class RemoteControlScreen extends StatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  final TextEditingController _ipController = TextEditingController();
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _statusMessage = 'Not connected';
  String _tvName = '';
  bool _isScanning = false;
  List<TVDevice> _discoveredTVs = [];
  String _savedToken = '';
  String? _currentEndpoint; // Track which endpoint is being used

  @override
  void initState() {
    super.initState();
    _loadSavedIP();
  }

  Future<void> _loadSavedIP() async {
    setState(() {
      _ipController.text = '';
    });
  }

  Future<void> scanForTVs() async {
    setState(() {
      _isScanning = true;
      _discoveredTVs.clear();
      _statusMessage = 'Scanning network for TVs...';
    });

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
        setState(() {
          _statusMessage = 'Could not determine local IP address';
          _isScanning = false;
        });
        return;
      }

      final parts = localIP.split('.');
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

      setState(() {
        _statusMessage = 'Scanning $subnet.0/24...';
      });

      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        futures.add(_checkTVAtIP(ip));
      }

      await Future.wait(futures);

      setState(() {
        _isScanning = false;
        if (_discoveredTVs.isEmpty) {
          _statusMessage = 'No TVs found. Try manual IP entry.';
        } else {
          _statusMessage = 'Found ${_discoveredTVs.length} TV(s)';
        }
      });

      if (_discoveredTVs.isNotEmpty) {
        showTVSelectionDialog();
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan error: $e';
      });
    }
  }

  Future<void> _checkTVAtIP(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        8001,
        timeout: const Duration(milliseconds: 500),
      );

      socket.destroy();

      setState(() {
        _discoveredTVs.add(TVDevice(
          name: 'Samsung TV',
          ipAddress: ip,
        ));
      });
    } catch (e) {
      // Not a TV or not reachable
    }
  }

  void showTVSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select TV'),
        content: SizedBox(
          width: double.maxFinite,
          child: _discoveredTVs.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No TVs found.\n\nMake sure your TV is on and connected to the same WiFi network.'),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: _discoveredTVs.length,
            itemBuilder: (context, index) {
              final tv = _discoveredTVs[index];
              return ListTile(
                leading: const Icon(Icons.tv, color: Colors.blue),
                title: Text(tv.name),
                subtitle: Text(tv.ipAddress),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  _ipController.text = tv.ipAddress;
                  Navigator.pop(context);
                  connectToTV(tv.ipAddress);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (_discoveredTVs.isEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                scanForTVs();
              },
              child: const Text('Scan Again'),
            ),
        ],
      ),
    );
  }

  // Helper function to create a custom HttpClient that bypasses SSL checks.
  // This is required because Samsung TVs use self-signed certificates.
  HttpClient getInsecureHttpClient() {
    HttpClient httpClient = HttpClient();
    // This line tells the HttpClient to trust all certificates.
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return httpClient;
  }

  Future<void> connectToTV(String ipAddress) async {
    print('═══════════════════════════════════════════════════════');
    print('DEBUG: Starting connection to $ipAddress');
    print('═══════════════════════════════════════════════════════');



    if (ipAddress.isEmpty) {
      print('DEBUG: IP address is empty');
      setState(() {
        _statusMessage = 'Please enter TV IP address';
      });
      return;
    }

    if (ipAddress == 'demo' || ipAddress == '0.0.0.0') {
      print('DEBUG: Demo mode activated');
      setState(() {
        _isConnected = true;
        _statusMessage = 'Demo Mode - No real TV connection';
        _tvName = 'Demo Samsung TV';
      });
      return;
    }
    String base64Name = base64.encode(utf8.encode(appName));

    final String uriString = 'wss://$ipAddress:$tvWsPort$wsPath?name="$base64Name"';
    final Uri uri = Uri.parse(uriString);

    setState(() {
      _statusMessage = 'Connecting...';
    });

    try {
      // 1. Get the custom HTTP client that ignores SSL certs
      final HttpClient insecureClient = getInsecureHttpClient();

      // 2. Create the WebSocket channel using the custom client
      final channel = IOWebSocketChannel.connect(
        uri,
        customClient: insecureClient,
        // Optional: Set a ping interval to keep the connection alive
        pingInterval: const Duration(seconds: 15),
      );

      // 3. Listen for the connection to be established (first event)
      await channel.ready;

      // 4. Update state upon successful connection
      setState(() {
        _channel = channel;
        _isConnected = true;
        _statusMessage = 'Connected to $_tvName!';
        _tvName = 'Samsung TV ($ipAddress)';
      });
      print('DEBUG: WebSocket connection established.');

      // 5. Start listening for incoming messages (like TV confirmation)
      _channel!.stream.listen(
            (data) {
          print('TV Message: $data');
          // You can parse the JSON data here to check for authentication status
          // and confirmation (e.g., 'event': 'ms.channel.connect').
        },
        onError: (error) {
          print('ERROR: WebSocket error: $error');
          _handleDisconnection('Connection error: ${error.toString()}');
        },
        onDone: () {
          print('DEBUG: WebSocket connection closed by TV.');
          _handleDisconnection('Disconnected from TV.');
        },
      );

      // Example of sending a key command after connection
      // sendRemoteKey('KEY_POWER');

    } catch (e) {
      print('FATAL ERROR: Failed to connect to TV: $e');
      _handleDisconnection('Failed to connect. Check IP, Port, and Network. Error: $e');
    }

  }

  void _handleDisconnection(String message) {
    setState(() {
      _isConnected = false;
      _statusMessage = message;
      _channel = null;
    });
  }

  void disconnectFromTV() {
    _channel!.sink.close(1000, 'User Disconnected');
    setState(() {
      _isConnected = false;
      _statusMessage = 'Disconnected';
      _tvName = '';
    });
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
      setState(() {
        _statusMessage = 'Cannot send command: Not connected.';
      });
    }
  }



  void sendText(String text) {
    // Check for connection status immediately
    if (_channel == null || !_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to TV'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Encoding the text to base64 is correct for Samsung TV text input
      final encodedText = base64.encode(utf8.encode(text));

      final command = {
        'method': 'ms.remote.control',
        'params': {
          'Cmd': 'Click',
          'DataOfCmd': encodedText,
          // Changed to string 'false' for consistency with sendRemoteKey
          'Option': 'false',
          'TypeOfRemote': 'SendInputString'
        }
      };

      // Use _channel!.sink.add to send data
      _channel!.sink.add(json.encode(command));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent text: $text'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showTextInputDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Type Text'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search text...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              sendText(value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                sendText(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Totalmote - Samsung TV Remote'),
        centerTitle: true,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              onPressed: disconnectFromTV,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              color: const Color(0xFF16213e),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _ipController,
                      enabled: !_isConnected,
                      decoration: const InputDecoration(
                        labelText: 'TV IP Address',
                        hintText: '192.168.1.6',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tv),
                        helperText: 'Find IP in TV Settings → Network',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning || _isConnected ? null : scanForTVs,
                            icon: _isScanning
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.search),
                            label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: Colors.purple[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isConnected ? null : () => connectToTV(_ipController.text),
                            icon: const Icon(Icons.link),
                            label: const Text('Connect'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: _isConnected ? Colors.green : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error_outline,
                          color: _isConnected ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _tvName.isNotEmpty ? '$_tvName - $_statusMessage' : _statusMessage,
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Text Input
            Card(
              elevation: 4,
              color: const Color(0xFF16213e),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Text Input',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: showTextInputDialog,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Type with Phone Keyboard'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.teal[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Power Button
            RemoteButton(
              icon: Icons.power_settings_new,
              label: 'Power',
              onPressed: () => sendKey('KEY_POWER'),
              size: 70,
              color: Colors.red[700]!,
            ),
            const SizedBox(height: 24),

            // D-Pad
            Card(
              elevation: 4,
              color: const Color(0xFF16213e),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    RemoteButton(
                      icon: Icons.keyboard_arrow_up,
                      onPressed: () => sendKey('KEY_UP'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RemoteButton(
                          icon: Icons.keyboard_arrow_left,
                          onPressed: () => sendKey('KEY_LEFT'),
                        ),
                        const SizedBox(width: 12),
                        RemoteButton(
                          icon: Icons.circle,
                          label: 'OK',
                          size: 80,
                          onPressed: () => sendKey('KEY_ENTER'),
                          color: Colors.blue[800]!,
                        ),
                        const SizedBox(width: 12),
                        RemoteButton(
                          icon: Icons.keyboard_arrow_right,
                          onPressed: () => sendKey('KEY_RIGHT'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RemoteButton(
                      icon: Icons.keyboard_arrow_down,
                      onPressed: () => sendKey('KEY_DOWN'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control Buttons
            Card(
              elevation: 4,
              color: const Color(0xFF16213e),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RemoteButton(
                          icon: Icons.arrow_back,
                          label: 'Back',
                          onPressed: () => sendKey('KEY_RETURN'),
                        ),
                        RemoteButton(
                          icon: Icons.home,
                          label: 'Home',
                          onPressed: () => sendKey('KEY_HOME'),
                        ),
                        RemoteButton(
                          icon: Icons.menu,
                          label: 'Menu',
                          onPressed: () => sendKey('KEY_MENU'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RemoteButton(
                          icon: Icons.volume_down,
                          label: 'Vol-',
                          onPressed: () => sendKey('KEY_VOLDOWN'),
                        ),
                        RemoteButton(
                          icon: Icons.volume_mute,
                          label: 'Mute',
                          onPressed: () => sendKey('KEY_MUTE'),
                        ),
                        RemoteButton(
                          icon: Icons.volume_up,
                          label: 'Vol+',
                          onPressed: () => sendKey('KEY_VOLUP'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RemoteButton(
                          icon: Icons.arrow_upward,
                          label: 'Ch+',
                          onPressed: () => sendKey('KEY_CHUP'),
                        ),
                        RemoteButton(
                          icon: Icons.arrow_downward,
                          label: 'Ch-',
                          onPressed: () => sendKey('KEY_CHDOWN'),
                        ),
                        RemoteButton(
                          icon: Icons.input,
                          label: 'Source',
                          onPressed: () => sendKey('KEY_SOURCE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Media Controls
            Card(
              elevation: 4,
              color: const Color(0xFF16213e),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Media Controls',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        RemoteButton(
                          icon: Icons.fast_rewind,
                          label: 'Rewind',
                          onPressed: () => sendKey('KEY_REWIND'),
                        ),
                        RemoteButton(
                          icon: Icons.play_arrow,
                          label: 'Play',
                          onPressed: () => sendKey('KEY_PLAY'),
                        ),
                        RemoteButton(
                          icon: Icons.pause,
                          label: 'Pause',
                          onPressed: () => sendKey('KEY_PAUSE'),
                        ),
                        RemoteButton(
                          icon: Icons.fast_forward,
                          label: 'Forward',
                          onPressed: () => sendKey('KEY_FF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RemoteButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      onPressed: () => sendKey('KEY_STOP'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class RemoteButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final double size;
  final Color? color;

  const RemoteButton({
    Key? key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.size = 60,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color ?? const Color(0xFF0f3460),
          borderRadius: BorderRadius.circular(size / 2),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, size: size * 0.5),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
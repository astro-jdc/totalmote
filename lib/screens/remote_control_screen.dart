import 'package:flutter/material.dart';
import '../services/tv_service.dart';
import '../models/tv_device.dart';
import '../widgets/connection_card.dart';
import '../widgets/text_input_card.dart';
import '../widgets/dpad_card.dart';
import '../widgets/control_buttons_card.dart';
import '../widgets/media_controls_card.dart';
import '../widgets/remote_button.dart';

class RemoteControlScreen extends StatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TVService _tvService = TVService();
  bool _isConnected = false;
  String _statusMessage = 'Not connected';
  String _tvName = '';
  bool _isScanning = false;
  List<TVDevice> _discoveredTVs = [];

  @override
  void initState() {
    super.initState();
    _setupTVService();
  }

  void _setupTVService() {
    _tvService.onStatusChanged = (message) {
      setState(() {
        _statusMessage = message;
      });
    };

    _tvService.onConnectionChanged = (connected) {
      setState(() {
        _isConnected = connected;
      });
    };
  }

  Future<void> scanForTVs() async {
    setState(() {
      _isScanning = true;
      _discoveredTVs.clear();
      _statusMessage = 'Scanning network for TVs...';
    });

    _discoveredTVs = await _tvService.scanForTVs((progress) {
      setState(() {
        _statusMessage = progress;
      });
    });

    setState(() {
      _isScanning = false;
      if (_discoveredTVs.isEmpty) {
        _statusMessage = 'No TVs found. Try manual IP entry.';
      } else {
        _statusMessage = 'Found ${_discoveredTVs.length} TV(s)';
      }
    });

    if (_discoveredTVs.isNotEmpty) {
      _showTVSelectionDialog();
    }
  }

  void _showTVSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select TV'),
        content: SizedBox(
          width: double.maxFinite,
          child: _discoveredTVs.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
                'No TVs found.\n\nMake sure your TV is on and connected to the same WiFi network.'),
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
                  _connectToTV(tv.ipAddress);
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

  Future<void> _connectToTV(String ipAddress) async {
    setState(() {
      _tvName = 'Samsung TV ($ipAddress)';
    });
    await _tvService.connectToTV(ipAddress, _tvName);
  }

  void _disconnectFromTV() {
    _tvService.disconnect();
    setState(() {
      _tvName = '';
    });
  }

  void _sendKey(String key) {
    _tvService.sendKey(key);
  }

  void _sendText(String text) {
    try {
      _tvService.sendText(text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent text: $text'),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showTextInputDialog() {
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
              _sendText(value);
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
                _sendText(textController.text);
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
    _tvService.dispose();
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
              onPressed: _disconnectFromTV,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ConnectionCard(
              ipController: _ipController,
              isConnected: _isConnected,
              isScanning: _isScanning,
              statusMessage: _statusMessage,
              tvName: _tvName,
              onScan: scanForTVs,
              onConnect: () => _connectToTV(_ipController.text),
            ),
            const SizedBox(height: 16),
            TextInputCard(onShowDialog: _showTextInputDialog),
            const SizedBox(height: 16),
            RemoteButton(
              icon: Icons.power_settings_new,
              label: 'Power',
              onPressed: () => _sendKey('KEY_POWER'),
              size: 70,
              color: Colors.red[700]!,
            ),
            const SizedBox(height: 24),
            DPadCard(onSendKey: _sendKey),
            const SizedBox(height: 16),
            ControlButtonsCard(onSendKey: _sendKey),
            const SizedBox(height: 16),
            MediaControlsCard(onSendKey: _sendKey),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
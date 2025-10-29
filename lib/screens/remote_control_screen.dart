import 'package:flutter/material.dart';
import '../services/generic_tv_service.dart';
import '../services/tv_service_factory.dart';
import '../models/tv_device.dart';
import '../widgets/connection_card.dart';
import '../widgets/text_input_card.dart';
import '../widgets/dpad_card.dart';
import '../widgets/control_buttons_card.dart';
import '../widgets/media_controls_card.dart';
import '../widgets/remote_button.dart';
import '../utils/app_logger.dart';
import '../utils/app_preferences.dart';
import 'yaml_viewer_screen.dart';


class RemoteControlScreen extends StatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  final TextEditingController _ipController = TextEditingController();
  GenericTVService? _tvService;
  bool _isConnected = false;
  String _statusMessage = 'Not connected';
  String _tvName = '';
  bool _isScanning = false;
  List<TVDevice> _discoveredTVs = [];

  // TV Brand selection
  String? _selectedBrand;
  List<String> _availableBrands = [];
  bool _isLoadingBrands = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableBrands();
  }

  Future<void> _loadAvailableBrands() async {
    try {
      final brands = await TVServiceFactory.getSupportedBrands();
      setState(() {
        _availableBrands = brands;
        _isLoadingBrands = false;
      });

      // Load last used TV configuration
      if (AppPreferences.hasSavedTV()) {
        final lastBrand = AppPreferences.getLastTVBrand()!;
        final lastIP = AppPreferences.getLastTVIP()!;
        final lastName = AppPreferences.getLastTVName();

        if (brands.contains(lastBrand)) {
          setState(() {
            _selectedBrand = lastBrand;
            _ipController.text = lastIP;
            if (lastName != null) {
              _tvName = lastName;
            }
            _statusMessage = 'Loaded last used: ${lastBrand.toUpperCase()}';
          });

          // Initialize the service
          await _onBrandChanged(lastBrand);

          // Show option to reconnect
          _showReconnectDialog(lastBrand, lastIP);
          return;
        }
      }

      // No saved config, use first brand
      if (brands.isNotEmpty) {
        setState(() {
          _selectedBrand = brands.first;
        });
        _onBrandChanged(brands.first);
      }
    } catch (e) {
      logger.e('Failed to load TV brands', error: e);
      setState(() {
        _isLoadingBrands = false;
        _statusMessage = 'Failed to load TV configurations';
      });
    }
  }

  void _showReconnectDialog(String brand, String ip) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reconnect to Last TV?'),
          content: Text(
            'Would you like to reconnect to:\n\n'
                'Brand: ${brand.toUpperCase()}\n'
                'IP: $ip',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _connectToTV(ip);
              },
              child: const Text('Connect'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _onBrandChanged(String brand) async {
    setState(() {
      _selectedBrand = brand;
      _statusMessage = 'Loading ${brand.toUpperCase()} configuration...';
    });

    try {
      final service = await TVServiceFactory.createService(brand);
      _setupTVService(service);
      setState(() {
        _statusMessage = 'Ready to connect to ${brand.toUpperCase()} TV';
      });
    } catch (e) {
      logger.e('Failed to load $brand service', error: e);
      setState(() {
        _statusMessage = 'Error loading $brand configuration';
      });
    }
  }

  void _setupTVService(GenericTVService service) {
    _tvService = service;

    service.onStatusChanged = (message) {
      setState(() {
        _statusMessage = message;
      });
    };

    service.onConnectionChanged = (connected) {
      setState(() {
        _isConnected = connected;
      });
    };
  }

  Future<void> scanForTVs() async {
    if (_tvService == null) {
      setState(() {
        _statusMessage = 'Please select a TV brand first';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _discoveredTVs.clear();
      _statusMessage = 'Scanning network for TVs...';
    });

    _discoveredTVs = await _tvService!.scanForTVs((progress) {
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
        title: Text('Select ${_selectedBrand?.toUpperCase() ?? 'TV'}'),
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
                subtitle: Text('${tv.ipAddress}:${tv.port}'),
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
    if (_tvService == null) {
      setState(() {
        _statusMessage = 'Please select a TV brand first';
      });
      return;
    }

    setState(() {
      _tvName = '${_selectedBrand?.toUpperCase() ?? 'TV'} ($ipAddress)';
    });
    await _tvService!.connectToTV(ipAddress, _tvName);

    // Save successful connection
    if (_tvService!.isConnected) {
      await AppPreferences.saveLastTV(
        brand: _selectedBrand!,
        ipAddress: ipAddress,
        tvName: _tvName,
      );
    }
  }

  void _disconnectFromTV() {
    _tvService?.disconnect();
    setState(() {
      _tvName = '';
    });
  }

  void _sendKey(String key) {
    _tvService?.sendKey(key);
  }

  void _sendText(String text) {
    try {
      _tvService?.sendText(text);
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
    _tvService?.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while brands are loading
    if (_isLoadingBrands) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Loading TV Configurations...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Totalmote - Universal TV Remote'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const YamlViewerScreen(),
                ),
              );
            },
            tooltip: 'View YAML Config',
          ),
          if (AppPreferences.hasSavedTV() && !_isConnected)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await AppPreferences.clearLastTV();
                setState(() {
                  _statusMessage = 'Cleared saved TV configuration';
                });
              },
              tooltip: 'Forget Last TV',
            ),
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
            // TV Brand Selector
            Card(
              elevation: 4,
              color: const Color(0xFF16213e),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TV Brand',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingBrands)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBrand,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tv),
                          hintText: 'Select TV Brand',  // Add hint
                        ),
                        items: _availableBrands.map((brand) {
                          return DropdownMenuItem(
                            value: brand,
                            child: Text(brand.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: _isConnected
                            ? null
                            : (value) {
                          if (value != null) {
                            _onBrandChanged(value);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection Card
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

            // Text Input
            TextInputCard(onShowDialog: _showTextInputDialog),
            const SizedBox(height: 16),

            // Power Button
            RemoteButton(
              icon: Icons.power_settings_new,
              label: 'Power',
              onPressed: () => _sendKey('power'),
              size: 70,
              color: Colors.red[700]!,
            ),
            const SizedBox(height: 24),

            // D-Pad
            DPadCard(onSendKey: _sendKey),
            const SizedBox(height: 16),

            // Control Buttons
            ControlButtonsCard(onSendKey: _sendKey),
            const SizedBox(height: 16),

            // Media Controls
            MediaControlsCard(onSendKey: _sendKey),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
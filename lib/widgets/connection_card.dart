import 'package:flutter/material.dart';
import 'ip_address_text_field.dart';

class ConnectionCard extends StatelessWidget {
  final TextEditingController ipController;
  final bool isConnected;
  final bool isScanning;
  final String statusMessage;
  final String tvName;
  final VoidCallback onScan;
  final VoidCallback onConnect;
  final VoidCallback? onDisconnect;

  const ConnectionCard({
    super.key,
    required this.ipController,
    required this.isConnected,
    required this.isScanning,
    required this.statusMessage,
    required this.tvName,
    required this.onScan,
    required this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF16213e),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            IPAddressTextField(
              controller: ipController,
              enabled: !isConnected,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isScanning || isConnected ? null : onScan,
                    icon: isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search),
                    label: Text(isScanning ? 'Scanning...' : 'Scan'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.purple[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? onDisconnect : onConnect,
                    icon: Icon(isConnected ? Icons.link_off : Icons.link),
                    label: Text(isConnected ? 'Disconnect' : 'Connect'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: isConnected ? Colors.red[700] : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error_outline,
                  color: isConnected ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tvName.isNotEmpty
                        ? '$tvName - $statusMessage'
                        : statusMessage,
                    style: TextStyle(
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'remote_button.dart';

class DPadCard extends StatelessWidget {
  final Function(String) onSendKey;

  const DPadCard({
    Key? key,
    required this.onSendKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF16213e),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            RemoteButton(
              icon: Icons.keyboard_arrow_up,
              onPressed: () => onSendKey('up'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RemoteButton(
                  icon: Icons.keyboard_arrow_left,
                  onPressed: () => onSendKey('left'),
                ),
                const SizedBox(width: 12),
                RemoteButton(
                  icon: Icons.circle,
                  label: 'OK',
                  size: 80,
                  onPressed: () => onSendKey('enter'),
                  color: Colors.blue[800]!,
                ),
                const SizedBox(width: 12),
                RemoteButton(
                  icon: Icons.keyboard_arrow_right,
                  onPressed: () => onSendKey('right'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RemoteButton(
              icon: Icons.keyboard_arrow_down,
              onPressed: () => onSendKey('down'),
            ),
          ],
        ),
      ),
    );
  }
}

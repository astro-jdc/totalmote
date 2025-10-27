import 'package:flutter/material.dart';
import 'remote_button.dart';

class ControlButtonsCard extends StatelessWidget {
  final Function(String) onSendKey;

  const ControlButtonsCard({
    Key? key,
    required this.onSendKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  onPressed: () => onSendKey('back'),
                ),
                RemoteButton(
                  icon: Icons.home,
                  label: 'Home',
                  onPressed: () => onSendKey('home'),
                ),
                RemoteButton(
                  icon: Icons.menu,
                  label: 'Menu',
                  onPressed: () => onSendKey('menu'),
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
                  onPressed: () => onSendKey('volume_down'),
                ),
                RemoteButton(
                  icon: Icons.volume_mute,
                  label: 'Mute',
                  onPressed: () => onSendKey('mute'),
                ),
                RemoteButton(
                  icon: Icons.volume_up,
                  label: 'Vol+',
                  onPressed: () => onSendKey('volume_up'),
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
                  onPressed: () => onSendKey('channel_up'),
                ),
                RemoteButton(
                  icon: Icons.arrow_downward,
                  label: 'Ch-',
                  onPressed: () => onSendKey('channel_down'),
                ),
                RemoteButton(
                  icon: Icons.input,
                  label: 'Source',
                  onPressed: () => onSendKey('source'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

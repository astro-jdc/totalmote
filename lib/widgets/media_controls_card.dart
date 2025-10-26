import 'package:flutter/material.dart';
import 'remote_button.dart';

class MediaControlsCard extends StatelessWidget {
  final Function(String) onSendKey;

  const MediaControlsCard({
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
                  onPressed: () => onSendKey('KEY_REWIND'),
                ),
                RemoteButton(
                  icon: Icons.play_arrow,
                  label: 'Play',
                  onPressed: () => onSendKey('KEY_PLAY'),
                ),
                RemoteButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  onPressed: () => onSendKey('KEY_PAUSE'),
                ),
                RemoteButton(
                  icon: Icons.fast_forward,
                  label: 'Forward',
                  onPressed: () => onSendKey('KEY_FF'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RemoteButton(
              icon: Icons.stop,
              label: 'Stop',
              onPressed: () => onSendKey('KEY_STOP'),
            ),
          ],
        ),
      ),
    );
  }
}
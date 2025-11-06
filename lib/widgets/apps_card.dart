import 'package:flutter/material.dart';
import 'remote_button.dart';

class AppsCard extends StatelessWidget {
  final Function(String) onOpenApp;

  const AppsCard({
    super.key,
    required this.onOpenApp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF16213e),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Streaming Apps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildAppButton(
                  icon: Icons.play_circle_fill,
                  label: 'Netflix',
                  color: const Color(0xFFE50914),
                  key: 'netflix',
                ),
                _buildAppButton(
                  icon: Icons.movie,
                  label: 'Disney+',
                  color: const Color(0xFF113CCF),
                  key: 'disney_plus',
                ),
                _buildAppButton(
                  icon: Icons.shopping_bag,
                  label: 'Prime',
                  color: const Color(0xFF00A8E1),
                  key: 'amazon_prime',
                ),
                _buildAppButton(
                  icon: Icons.play_arrow,
                  label: 'YouTube',
                  color: const Color(0xFFFF0000),
                  key: 'youtube',
                ),
                _buildAppButton(
                  icon: Icons.music_note,
                  label: 'Spotify',
                  color: const Color(0xFF1DB954),
                  key: 'spotify',
                ),
                _buildAppButton(
                  icon: Icons.tv,
                  label: 'Hulu',
                  color: const Color(0xFF1CE783),
                  key: 'hulu',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppButton({
    required IconData icon,
    required String label,
    required Color color,
    required String key,
  }) {
    return RemoteButton(
      icon: icon,
      label: label,
      onPressed: () => onOpenApp(key),
      size: 60,
      color: color,
    );
  }
}
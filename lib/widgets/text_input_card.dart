import 'package:flutter/material.dart';

class TextInputCard extends StatelessWidget {
  final VoidCallback onShowDialog;

  const TextInputCard({
    Key? key,
    required this.onShowDialog,
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
              'Text Input',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onShowDialog,
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
    );
  }
}
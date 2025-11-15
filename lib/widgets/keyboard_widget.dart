import 'package:flutter/material.dart';

class KeyboardWidget extends StatelessWidget {
  final Function(String) onKeyPress;

  const KeyboardWidget({
    super.key,
    required this.onKeyPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']),
          const SizedBox(height: 8),
          _buildRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']),
          const SizedBox(height: 8),
          _buildRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L']),
          const SizedBox(height: 8),
          _buildRow(['Z', 'X', 'C', 'V', 'B', 'N', 'M']),
          const SizedBox(height: 8),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    // Convert display key to command format
    String keyCommand = _getKeyCommand(key);

    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: 32,
        height: 42,
        child: ElevatedButton(
          onPressed: () => onKeyPress(keyCommand),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: const Color(0xFF0f3460),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            key,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getKeyCommand(String displayKey) {
    // Numbers
    if (RegExp(r'^\d$').hasMatch(displayKey)) {
      return 'key_$displayKey';
    }

    // Letters - convert to lowercase with key_ prefix
    if (RegExp(r'^[A-Z]$').hasMatch(displayKey)) {
      return 'key_${displayKey.toLowerCase()}';
    }

    // Return as-is for other characters
    return displayKey;
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Backspace
        Padding(
          padding: const EdgeInsets.all(2),
          child: SizedBox(
            width: 60,
            height: 42,
            child: ElevatedButton(
              onPressed: () => onKeyPress('backspace'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Icon(Icons.backspace, size: 18),
            ),
          ),
        ),
        // Space
        Padding(
          padding: const EdgeInsets.all(2),
          child: SizedBox(
            width: 150,
            height: 42,
            child: ElevatedButton(
              onPressed: () => onKeyPress('space'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF0f3460),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('SPACE'),
            ),
          ),
        ),
        // Enter
        Padding(
          padding: const EdgeInsets.all(2),
          child: SizedBox(
            width: 60,
            height: 42,
            child: ElevatedButton(
              onPressed: () => onKeyPress('enter'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Icon(Icons.keyboard_return, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
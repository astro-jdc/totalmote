import 'package:flutter/material.dart';
import '../widgets/keyboard_widget.dart';

class KeyboardScreen extends StatelessWidget {
  final Function(String) onSendKey;

  const KeyboardScreen({
    Key? key,
    required this.onSendKey,
  }) : super(key: key);

  void _handleKeyPress(String key) {
    onSendKey(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('On-Screen Keyboard'),
      ),
      body: Column(
        children: [
          const Spacer(),
          KeyboardWidget(
            onKeyPress: _handleKeyPress,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
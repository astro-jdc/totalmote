import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IPAddressTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String? errorText;

  const IPAddressTextField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        _IPAddressInputFormatter(),
        LengthLimitingTextInputFormatter(15), // Max: XXX.XXX.XXX.XXX
      ],
      decoration: InputDecoration(
        labelText: 'TV IP Address',
        hintText: '192.168.1.100',
        prefixIcon: const Icon(Icons.wifi),
        border: const OutlineInputBorder(),
        errorText: errorText,
      ),
    );
  }
}

class _IPAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Validate IP format
    if (!_isValidIPFormat(text)) {
      return oldValue;
    }

    return newValue;
  }

  bool _isValidIPFormat(String text) {
    if (text.isEmpty) return true;

    // Split by dots
    final parts = text.split('.');

    // Max 4 parts
    if (parts.length > 4) return false;

    // Check each part
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      // Empty part only allowed if not last
      if (part.isEmpty && i == parts.length - 1) continue;
      if (part.isEmpty) return false;

      // Must be number
      final num = int.tryParse(part);
      if (num == null) return false;

      // Must be 0-255
      if (num > 255) return false;

      // Max 3 digits
      if (part.length > 3) return false;
    }

    return true;
  }
}
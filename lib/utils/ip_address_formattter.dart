import 'package:flutter/services.dart';

class IpAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty
    if (text.isEmpty) {
      return newValue;
    }

    // Remove any non-digit or dot characters
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Split by dots
    final parts = cleaned.split('.');

    // Limit to 4 octets
    if (parts.length > 4) {
      return oldValue;
    }

    // Validate each octet
    final validParts = <String>[];
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      // Allow empty part (user typing)
      if (part.isEmpty) {
        validParts.add(part);
        continue;
      }

      // Parse and validate
      final value = int.tryParse(part);
      if (value == null) {
        return oldValue;
      }

      // Must be 0-255
      if (value > 255) {
        return oldValue;
      }

      // Limit to 3 digits per octet
      if (part.length > 3) {
        return oldValue;
      }

      validParts.add(part);
    }

    // Rebuild the text
    final formatted = validParts.join('.');

    // Auto-add dot after complete octet
    String finalText = formatted;
    if (formatted.length > oldValue.text.length) {
      final lastPart = validParts.isNotEmpty ? validParts.last : '';
      if (lastPart.length == 3 ||
          (int.tryParse(lastPart) ?? 0) > 25 ||
          (lastPart.length == 2 && int.parse(lastPart) > 25)) {
        if (parts.length < 4 && !formatted.endsWith('.')) {
          finalText = '$formatted.';
        }
      }
    }

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
}
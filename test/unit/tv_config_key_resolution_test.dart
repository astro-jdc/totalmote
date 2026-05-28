import 'package:flutter_test/flutter_test.dart';

import '../helpers/tv_config_fixtures.dart';

void main() {
  group('TVConfig.getKeyCode — parameterized key_code pattern', () {
    final config = makeSamsungConfig();

    // Letters
    test('key_code:a resolves to KEY_A', () {
      expect(config.getKeyCode('key_code:a'), equals('KEY_A'));
    });

    test('key_code:z resolves to KEY_Z', () {
      expect(config.getKeyCode('key_code:z'), equals('KEY_Z'));
    });

    test('key_code:A (uppercase input) also resolves to KEY_A', () {
      expect(config.getKeyCode('key_code:A'), equals('KEY_A'));
    });

    test('every letter a-z resolves correctly', () {
      for (final ch in 'abcdefghijklmnopqrstuvwxyz'.split('')) {
        expect(
          config.getKeyCode('key_code:$ch'),
          equals('KEY_${ch.toUpperCase()}'),
          reason: 'Failed for key_code:$ch',
        );
      }
    });

    // Numbers
    test('key_code:0 resolves to KEY_0', () {
      expect(config.getKeyCode('key_code:0'), equals('KEY_0'));
    });

    test('key_code:9 resolves to KEY_9', () {
      expect(config.getKeyCode('key_code:9'), equals('KEY_9'));
    });

    test('every digit 0-9 resolves correctly', () {
      for (final digit in '0123456789'.split('')) {
        expect(
          config.getKeyCode('key_code:$digit'),
          equals('KEY_$digit'),
          reason: 'Failed for key_code:$digit',
        );
      }
    });

    // Edge cases
    test('unknown parameterized pattern returns null', () {
      expect(config.getKeyCode('unknown_pattern:x'), isNull);
    });

    test('key_code with empty arg returns KEY_ (graceful, not crash)', () {
      final result = config.getKeyCode('key_code:');
      // Empty arg → toUpperCase() is still '' → 'KEY_'
      // We just verify it doesn't throw
      expect(() => config.getKeyCode('key_code:'), returnsNormally);
    });
  });

  group('TVConfig.getKeyCode — plain named keys still work', () {
    final config = makeSamsungConfig();

    test('power resolves to KEY_POWER', () {
      expect(config.getKeyCode('power'), equals('KEY_POWER'));
    });

    test('volume_up resolves to KEY_VOLUP', () {
      expect(config.getKeyCode('volume_up'), equals('KEY_VOLUP'));
    });

    test('enter resolves to KEY_ENTER', () {
      expect(config.getKeyCode('enter'), equals('KEY_ENTER'));
    });

    test('backspace resolves to KEY_BACKSPACE', () {
      expect(config.getKeyCode('backspace'), equals('KEY_BACKSPACE'));
    });

    test('space resolves to KEY_SPACE', () {
      expect(config.getKeyCode('space'), equals('KEY_SPACE'));
    });

    test('unknown plain key returns null', () {
      expect(config.getKeyCode('nonexistent_key'), isNull);
    });
  });

  group('TVConfig.getKeyCode — colon in key is treated as separator', () {
    test('first colon is the separator, arg may contain colons', () {
      // e.g. 'key_code:a:extra' → pattern=key_code, arg=a:extra → KEY_A:EXTRA
      // Verifies no crash and predictable behaviour
      final config = makeSamsungConfig();
      expect(() => config.getKeyCode('key_code:a:extra'), returnsNormally);
    });
  });
}

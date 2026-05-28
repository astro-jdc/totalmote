import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:totalmote/main.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TotalMoteApp());
    await tester.pump(const Duration(seconds: 1));
    // The remote control screen must load; verify its root Scaffold is present.
    expect(find.byType(Scaffold), findsWidgets);
  });
}

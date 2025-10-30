// Copyright (c) 2025 Totalmote
//
// This source code is licensed under the MIT license found in the
// LICENSE file in the root directory of this source tree.
//
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'screens/remote_control_screen.dart';
import 'utils/app_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize preferences
  await AppPreferences.init();

  runApp(const TotalMoteApp());
}

class TotalMoteApp extends StatelessWidget {
  const TotalMoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Totalmote',
      theme: ThemeData.dark(),
      home: const RemoteControlScreen(),
    );
  }
}

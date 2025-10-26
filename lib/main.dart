import 'package:flutter/material.dart';
import 'screens/remote_control_screen.dart';

void main() {
  runApp(const SamsungTVRemoteApp());
}

const String appName = "Totalmote";

class SamsungTVRemoteApp extends StatelessWidget {
  const SamsungTVRemoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      ),
      home: const RemoteControlScreen(),
    );
  }
}
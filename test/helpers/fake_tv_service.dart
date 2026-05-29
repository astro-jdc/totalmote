import 'package:totalmote/models/tv_device.dart';
import 'package:totalmote/services/generic_tv_service.dart';

/// A fake implementation of [GenericTVService] for use in tests.
/// Records all commands sent instead of opening a real connection.
class FakeTVService extends GenericTVService {
  final List<String> sentKeys = [];
  final List<String> sentTexts = [];
  final List<String> openedApps = [];
  bool _connected = false;

  FakeTVService(super.config, {required super.appName});

  @override
  bool get isConnected => _connected;

  @override
  Future<List<TVDevice>> scanForTVs(Function(String) onProgress) async => [];

  @override
  Future<void> connectToTV(String ipAddress, String tvName) async {
    _connected = true;
    onConnectionChanged?.call(true);
    onStatusChanged?.call('Connected to $tvName');
  }

  @override
  void disconnect([String? message]) {
    _connected = false;
    onConnectionChanged?.call(false);
    onStatusChanged?.call(message ?? 'Disconnected');
  }

  @override
  void sendKey(String key) => sentKeys.add(key);

  @override
  void sendText(String text) => sentTexts.add(text);

  @override
  void openApp(String appId) => openedApps.add(appId);

  @override
  void openBrowser({String? url}) {}

  @override
  void dispose() {}
}

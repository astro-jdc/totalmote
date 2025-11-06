import '../models/tv_device.dart';
import '../models/tv_config_model.dart';

abstract class GenericTVService {
  final TVConfig config;
  final String appName;
  bool get isConnected;
  Function(String)? onStatusChanged;
  Function(bool)? onConnectionChanged;

  GenericTVService(this.config, {required this.appName});

  Future<List<TVDevice>> scanForTVs(Function(String) onProgress);
  Future<void> connectToTV(String ipAddress, String tvName);
  void disconnect([String? message]);
  void sendKey(String key);
  void sendText(String text);
  void dispose();
}
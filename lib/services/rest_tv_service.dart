import 'generic_tv_service.dart';
import '../models/tv_device.dart';
import '../models/tv_config_model.dart';
import '../utils/app_logger.dart';

class RestTVService extends GenericTVService {
  bool _connected = false;

  RestTVService(TVConfig config, {required String appName})
      : super(config, appName: appName);

  @override
  bool get isConnected => _connected;

  @override
  Future<List<TVDevice>> scanForTVs(Function(String) onProgress) async {
    // REST scan logic
    return [];
  }

  @override
  Future<void> connectToTV(String ipAddress, String tvName) async {
    // REST connect logic
    _connected = true;
    onConnectionChanged?.call(_connected);
  }

  @override
  void disconnect([String? message]) {
    _connected = false;
    onConnectionChanged?.call(_connected);
  }

  @override
  void sendKey(String key) {
    // Send key via REST
  }

  @override
  void sendText(String text) {
    // Send text via REST
  }

  @override
  void dispose() {
    // Cleanup
  }
}
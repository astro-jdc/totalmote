class TVDevice {
  final String name;
  final String ipAddress;
  final int port;

  TVDevice({
    required this.name,
    required this.ipAddress,
    this.port = 8001,
  });
}
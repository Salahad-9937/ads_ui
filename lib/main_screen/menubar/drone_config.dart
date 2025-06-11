class DroneConfig {
  final String name;
  final String ipAddress;
  final int port;
  final bool isVirtual;

  DroneConfig({
    required this.name,
    required this.ipAddress,
    this.port = 8765,
    required this.isVirtual,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'ipAddress': ipAddress,
    'port': port,
    'isVirtual': isVirtual,
  };

  factory DroneConfig.fromJson(Map<String, dynamic> json) => DroneConfig(
    name: json['name'],
    ipAddress: json['ipAddress'],
    port: json['port'] ?? 8765,
    isVirtual: json['isVirtual'],
  );
}

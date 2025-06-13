/// Конфигурация дрона, содержащая параметры подключения.
///
/// [name] - Название дрона.
/// [ipAddress] - IP-адрес для подключения к дрону.
/// [port] - Порт для подключения к дрону.
/// [isVirtual] - Флаг, указывающий, является ли дрон виртуальным.
/// [sshUsername] - Имя пользователя для SSH-подключения.
/// [sshPassword] - Пароль для SSH-подключения.
class DroneConfig {
  final String name;
  final String ipAddress;
  final int port;
  final bool isVirtual;
  final String sshUsername;
  final String sshPassword;

  DroneConfig({
    required this.name,
    required this.ipAddress,
    this.port = 8765,
    required this.isVirtual,
    required this.sshUsername,
    required this.sshPassword,
  });

  /// Преобразует конфигурацию дрона в JSON-формат.
  Map<String, dynamic> toJson() => {
    'name': name,
    'ipAddress': ipAddress,
    'port': port,
    'isVirtual': isVirtual,
    'sshUsername': sshUsername,
    'sshPassword': sshPassword,
  };

  /// Создает конфигурацию дрона из JSON-данных.
  ///
  /// [json] - JSON-объект с данными конфигурации.
  factory DroneConfig.fromJson(Map<String, dynamic> json) => DroneConfig(
    name: json['name'],
    ipAddress: json['ipAddress'],
    port: json['port'] ?? 8765,
    isVirtual: json['isVirtual'],
    sshUsername: json['sshUsername'] ?? '',
    sshPassword: json['sshPassword'] ?? '',
  );
}

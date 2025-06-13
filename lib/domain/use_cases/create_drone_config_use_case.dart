import '../entities/drone_config.dart';

class CreateDroneConfigUseCase {
  /// Валидирует и создаёт конфигурацию дрона.
  ///
  /// Возвращает [DroneConfig] при успешной валидации или бросает исключение.
  DroneConfig execute({
    required String name,
    required String ipAddress,
    required String port,
    required bool isVirtual,
    required String sshUsername,
    required String sshPassword,
  }) {
    // Валидация имени
    if (name.isEmpty) {
      throw ValidationException('Введите имя дрона');
    }

    // Валидация IP-адреса
    if (ipAddress.isEmpty) {
      throw ValidationException('Введите IP-адрес или localhost');
    }
    if (ipAddress != 'localhost') {
      final ipRegExp = RegExp(
        r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      );
      if (!ipRegExp.hasMatch(ipAddress)) {
        throw ValidationException('Неверный IP-адрес');
      }
    }

    // Валидация порта
    final parsedPort = int.tryParse(port);
    if (port.isNotEmpty &&
        (parsedPort == null || parsedPort < 1 || parsedPort > 65535)) {
      throw ValidationException('Неверный порт');
    }

    return DroneConfig(
      name: name,
      ipAddress: ipAddress,
      port: parsedPort ?? 8765,
      isVirtual: isVirtual,
      sshUsername: sshUsername,
      sshPassword: sshPassword,
    );
  }
}

class ValidationException implements Exception {
  final String message;

  ValidationException(this.message);
}

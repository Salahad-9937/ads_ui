import '../entities/drone_config.dart';

/// Абстракция для работы с конфигурациями дронов.
abstract class DroneConfigRepository {
  /// Загружает список конфигураций дронов.
  Future<List<DroneConfig>> loadDrones();

  /// Сохраняет список конфигураций дронов.
  Future<void> saveDrones(List<DroneConfig> drones);

  /// Сохраняет индекс активного дрона.
  Future<void> saveSelectedDroneIndex(int? index);

  /// Загружает индекс активного дрона.
  Future<int?> loadSelectedDroneIndex();
}

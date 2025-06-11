import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'drone_config.dart';

/// Хранилище для управления конфигурациями дронов.
///
/// [_key] - Ключ для хранения данных в SharedPreferences.
/// [_defaultDrone] - Конфигурация дрона по умолчанию.
class DroneConfigStorage {
  static const String _key = 'droneConfigs';
  static final DroneConfig _defaultDrone = DroneConfig(
    name: 'Default Drone',
    ipAddress: 'localhost',
    port: 8765,
    isVirtual: true,
  );

  /// Загружает список конфигураций дронов из хранилища.
  Future<List<DroneConfig>> loadDrones() async {
    final prefs = await SharedPreferences.getInstance();
    final droneList = prefs.getString(_key);
    List<DroneConfig> drones = [_defaultDrone]; // Always include default drone
    if (droneList != null) {
      final List<dynamic> jsonList = json.decode(droneList);
      final loadedDrones =
          jsonList.map((json) => DroneConfig.fromJson(json)).toList();
      // Add loaded drones, excluding any that match the default drone
      for (var drone in loadedDrones) {
        if (drone.name != _defaultDrone.name ||
            drone.ipAddress != _defaultDrone.ipAddress) {
          drones.add(drone);
        }
      }
    }
    await saveDrones(drones); // Ensure default drone is saved
    return drones;
  }

  /// Сохраняет список конфигураций дронов в хранилище.
  ///
  /// [drones] - Список конфигураций дронов для сохранения.
  Future<void> saveDrones(List<DroneConfig> drones) async {
    final prefs = await SharedPreferences.getInstance();
    // Ensure default drone is included
    final filteredDrones =
        drones
            .where(
              (drone) =>
                  drone.name != _defaultDrone.name ||
                  drone.ipAddress != _defaultDrone.ipAddress,
            )
            .toList();
    final jsonList =
        [
          _defaultDrone,
          ...filteredDrones,
        ].map((drone) => drone.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }
}

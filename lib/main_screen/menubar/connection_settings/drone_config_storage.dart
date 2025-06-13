import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../domain/entities/drone_config.dart';
import '../../../../domain/repositories/drone_config_repository.dart'; // Новый импорт

/// Хранилище для управления конфигурациями дронов.
class DroneConfigStorage implements DroneConfigRepository {
  static const String _key = 'droneConfigs';
  static const String _selectedDroneKey = 'selectedDroneIndex';
  static final DroneConfig _defaultDrone = DroneConfig(
    name: 'Default Drone',
    ipAddress: 'localhost',
    port: 8765,
    isVirtual: true,
    sshUsername: '',
    sshPassword: '',
  );

  @override
  Future<List<DroneConfig>> loadDrones() async {
    final prefs = await SharedPreferences.getInstance();
    final droneList = prefs.getString(_key);
    List<DroneConfig> drones = [_defaultDrone];
    if (droneList != null) {
      final List<dynamic> jsonList = json.decode(droneList);
      final loadedDrones =
          jsonList.map((json) => DroneConfig.fromJson(json)).toList();
      for (var drone in loadedDrones) {
        if (drone.name != _defaultDrone.name ||
            drone.ipAddress != _defaultDrone.ipAddress) {
          drones.add(drone);
        }
      }
    }
    await saveDrones(drones);
    return drones;
  }

  @override
  Future<void> saveDrones(List<DroneConfig> drones) async {
    final prefs = await SharedPreferences.getInstance();
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

  @override
  Future<void> saveSelectedDroneIndex(int? index) async {
    final prefs = await SharedPreferences.getInstance();
    if (index != null) {
      await prefs.setInt(_selectedDroneKey, index);
    } else {
      await prefs.remove(_selectedDroneKey);
    }
  }

  @override
  Future<int?> loadSelectedDroneIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_selectedDroneKey);
  }
}

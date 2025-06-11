import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'drone_config.dart';

class DroneConfigStorage {
  static const String _key = 'droneConfigs';

  Future<List<DroneConfig>> loadDrones() async {
    final prefs = await SharedPreferences.getInstance();
    final droneList = prefs.getString(_key);
    if (droneList != null) {
      final List<dynamic> jsonList = json.decode(droneList);
      return jsonList.map((json) => DroneConfig.fromJson(json)).toList();
    } else {
      // Initialize with default localhost drone
      final defaultDrone = [
        DroneConfig(
          name: 'Default Drone',
          ipAddress: 'localhost',
          port: 8765,
          isVirtual: true,
        ),
      ];
      await saveDrones(defaultDrone);
      return defaultDrone;
    }
  }

  Future<void> saveDrones(List<DroneConfig> drones) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = drones.map((drone) => drone.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }
}

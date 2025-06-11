import 'package:flutter/material.dart';
import 'drone_config.dart';
import 'drone_config_storage.dart';
import 'drone_config_dialog.dart';

class ConnectionSettingsDialog extends StatefulWidget {
  const ConnectionSettingsDialog({super.key});

  @override
  ConnectionSettingsDialogState createState() =>
      ConnectionSettingsDialogState();
}

class ConnectionSettingsDialogState extends State<ConnectionSettingsDialog> {
  List<DroneConfig> drones = [];
  final DroneConfigStorage _storage = DroneConfigStorage();

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  Future<void> _loadDrones() async {
    final loadedDrones = await _storage.loadDrones();
    setState(() {
      drones = loadedDrones;
    });
  }

  void _removeDrone(int index) {
    setState(() {
      drones.removeAt(index);
    });
    _storage.saveDrones(drones);
  }

  void _showDroneDialog({DroneConfig? drone, int? index}) {
    showDialog(
      context: context,
      builder:
          (context) => DroneConfigDialog(
            drone: drone,
            onSave: (config) {
              setState(() {
                if (index != null) {
                  drones[index] = config;
                } else {
                  drones.add(config);
                }
              });
              _storage.saveDrones(drones);
            },
          ),
    );
  }

  bool _isDefaultDrone(DroneConfig drone) {
    return drone.name == 'Default Drone' && drone.ipAddress == 'localhost';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Настройки подключения'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDroneDialog(),
            tooltip: 'Добавить дрон',
          ),
        ],
      ),
      content: SizedBox(
        width: screenWidth * 2 / 3, // Set width to two-thirds of screen width
        height: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Список дронов:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: drones.length,
                itemBuilder: (context, index) {
                  final drone = drones[index];
                  final isDefault = _isDefaultDrone(drone);
                  return ListTile(
                    title: Text(
                      '${drone.name} (${drone.ipAddress}:${drone.port}, ${drone.isVirtual ? 'Виртуальный' : 'Реальный'})',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed:
                              isDefault
                                  ? null
                                  : () => _showDroneDialog(
                                    drone: drone,
                                    index: index,
                                  ),
                          tooltip:
                              isDefault
                                  ? 'Нельзя редактировать'
                                  : 'Редактировать',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              isDefault ? null : () => _removeDrone(index),
                          tooltip: isDefault ? 'Нельзя удалить' : 'Удалить',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

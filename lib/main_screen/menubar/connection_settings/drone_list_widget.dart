import 'package:flutter/material.dart';
import '../../../domain/entities/drone_config.dart';

/// Виджет для отображения списка дронов с возможностью выбора, редактирования и удаления.
class DroneListWidget extends StatelessWidget {
  final List<DroneConfig> drones;
  final int? selectedDroneIndex;
  final Function(int) onSelectDrone;
  final Function(int) onEditDrone;
  final Function(int) onRemoveDrone;
  final bool Function(DroneConfig) isDefaultDrone;

  const DroneListWidget({
    super.key,
    required this.drones,
    required this.selectedDroneIndex,
    required this.onSelectDrone,
    required this.onEditDrone,
    required this.onRemoveDrone,
    required this.isDefaultDrone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              final isDefault = isDefaultDrone(drone);
              final isSelected = selectedDroneIndex == index;

              return ListTile(
                leading: IconButton(
                  icon: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.green : Colors.grey,
                  ),
                  onPressed: () => onSelectDrone(index),
                  tooltip: 'Выбрать дрон',
                ),
                title: Text(
                  '${drone.name} (${drone.ipAddress}:${drone.port}, ${drone.isVirtual ? 'Виртуальный' : 'Реальный'})',
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: isDefault ? null : () => onEditDrone(index),
                      tooltip:
                          isDefault ? 'Нельзя редактировать' : 'Редактировать',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: isDefault ? null : () => onRemoveDrone(index),
                      tooltip: isDefault ? 'Нельзя удалить' : 'Удалить',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'drone_config.dart';
import 'drone_config_dialog.dart';
import 'drone_manager.dart';
import 'drone_list_widget.dart';

/// Диалоговое окно для управления списком конфигураций дронов.
///
/// [onSelectDrone] - Callback для возврата выбранного дрона.
class ConnectionSettingsDialog extends StatefulWidget {
  final Function(DroneConfig?)? onSelectDrone;

  const ConnectionSettingsDialog({super.key, this.onSelectDrone});

  @override
  ConnectionSettingsDialogState createState() =>
      ConnectionSettingsDialogState();
}

/// Состояние диалогового окна для управления конфигурациями дронов.
class ConnectionSettingsDialogState extends State<ConnectionSettingsDialog> {
  final DroneManager _droneManager = DroneManager();

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  /// Загружает список конфигураций дронов и устанавливает активный дрон.
  Future<void> _loadDrones() async {
    await _droneManager.loadDrones();
    setState(() {
      widget.onSelectDrone?.call(_droneManager.selectedDrone);
    });
  }

  /// Обработчик выбора дрона.
  Future<void> _onSelectDrone(int index) async {
    await _droneManager.selectDrone(index);
    setState(() {
      widget.onSelectDrone?.call(_droneManager.selectedDrone);
    });
  }

  /// Обработчик удаления дрона.
  Future<void> _onRemoveDrone(int index) async {
    await _droneManager.removeDrone(index);
    setState(() {
      widget.onSelectDrone?.call(_droneManager.selectedDrone);
    });
  }

  /// Отображает диалоговое окно для добавления или редактирования конфигурации дрона.
  ///
  /// [drone] - Конфигурация дрона для редактирования (опционально).
  /// [index] - Индекс редактируемой конфигурации в списке (опционально).
  void _showDroneDialog({DroneConfig? drone, int? index}) {
    showDialog(
      context: context,
      builder:
          (context) => DroneConfigDialog(
            drone: drone,
            onSave: (config) async {
              if (index != null) {
                await _droneManager.updateDrone(index, config);
              } else {
                await _droneManager.addDrone(config);
              }
              setState(() {
                widget.onSelectDrone?.call(_droneManager.selectedDrone);
              });
            },
          ),
    );
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
        width: screenWidth * 2 / 3,
        height: 300,
        child: DroneListWidget(
          drones: _droneManager.drones,
          selectedDroneIndex: _droneManager.selectedDroneIndex,
          onSelectDrone: _onSelectDrone,
          onEditDrone:
              (index) => _showDroneDialog(
                drone: _droneManager.drones[index],
                index: index,
              ),
          onRemoveDrone: _onRemoveDrone,
          isDefaultDrone: _droneManager.isDefaultDrone,
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

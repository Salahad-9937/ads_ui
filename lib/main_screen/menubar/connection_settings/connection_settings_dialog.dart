import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/drone_config.dart';
import '../../../domain/use_cases/manage_drones_use_case.dart';
import 'drone_config_dialog.dart';
import 'drone_list_widget.dart';
import 'drone_config_storage.dart'; // Временный импорт для создания репозитория

/// Диалоговое окно для управления списком конфигураций дронов.
class ConnectionSettingsDialog extends StatefulWidget {
  final Function(DroneConfig?)? onSelectDrone;
  final dynamic webSocketService;

  const ConnectionSettingsDialog({
    super.key,
    this.onSelectDrone,
    this.webSocketService,
  });

  @override
  ConnectionSettingsDialogState createState() =>
      ConnectionSettingsDialogState();
}

class ConnectionSettingsDialogState extends State<ConnectionSettingsDialog> {
  late final ManageDronesUseCase _useCase;

  @override
  void initState() {
    super.initState();
    // Временное создание репозитория, в будущем использовать DI
    final repository = DroneConfigStorage();
    _useCase = ManageDronesUseCase(repository);
    _loadDrones();
  }

  /// Загружает список конфигураций дронов и устанавливает активный дрон.
  Future<void> _loadDrones() async {
    await _useCase.loadDrones();
    if (mounted) {
      setState(() {
        widget.onSelectDrone?.call(_useCase.selectedDrone);
        widget.webSocketService?.updateDrone(_useCase.selectedDrone);
      });
    }
  }

  /// Обработчик выбора дрона.
  Future<void> _onSelectDrone(int index) async {
    await _useCase.selectDrone(index);
    if (mounted) {
      setState(() {
        widget.onSelectDrone?.call(_useCase.selectedDrone);
        widget.webSocketService?.updateDrone(_useCase.selectedDrone);
        if (kDebugMode) {
          print(
            'Dialog selected: ${_useCase.selectedDrone?.name} (${_useCase.selectedDrone?.ipAddress}:${_useCase.selectedDrone?.port})',
          );
        }
      });
    }
  }

  /// Обработчик удаления дрона.
  Future<void> _onRemoveDrone(int index) async {
    await _useCase.removeDrone(index);
    if (mounted) {
      setState(() {
        widget.onSelectDrone?.call(_useCase.selectedDrone);
        widget.webSocketService?.updateDrone(_useCase.selectedDrone);
      });
    }
  }

  /// Отображает диалоговое окно для добавления или редактирования дрона.
  void _showDroneDialog({DroneConfig? drone, int? index}) {
    showDialog(
      context: context,
      builder:
          (context) => DroneConfigDialog(
            drone: drone,
            onSave: (config) async {
              if (index != null) {
                await _useCase.updateDrone(index, config);
              } else {
                await _useCase.addDrone(config);
              }
              if (mounted) {
                setState(() {
                  widget.onSelectDrone?.call(_useCase.selectedDrone);
                  widget.webSocketService?.updateDrone(_useCase.selectedDrone);
                });
              }
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
          drones: _useCase.drones,
          selectedDroneIndex: _useCase.selectedDroneIndex,
          onSelectDrone: _onSelectDrone,
          onEditDrone:
              (index) =>
                  _showDroneDialog(drone: _useCase.drones[index], index: index),
          onRemoveDrone: _onRemoveDrone,
          isDefaultDrone: _useCase.isDefaultDrone,
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

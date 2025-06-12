import 'package:flutter/material.dart';
import 'drone_config.dart';
import 'drone_config_storage.dart';
import 'drone_config_dialog.dart';

/// Диалоговое окно для управления списком конфигураций дронов.
///
/// [drones] - Список конфигураций дронов.
/// [_storage] - Хранилище для сохранения и загрузки конфигураций дронов.
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
  List<DroneConfig> drones = [];
  final DroneConfigStorage _storage = DroneConfigStorage();
  int? _selectedDroneIndex; // Индекс активного дрона

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  /// Загружает список конфигураций дронов и индекс активного дрона из хранилища.
  Future<void> _loadDrones() async {
    final loadedDrones = await _storage.loadDrones();
    final selectedIndex = await _storage.loadSelectedDroneIndex();
    setState(() {
      drones = loadedDrones;
      // Устанавливаем сохраненный индекс или 0, если список не пустой
      if (drones.isNotEmpty) {
        _selectedDroneIndex =
            selectedIndex != null && selectedIndex < drones.length
                ? selectedIndex
                : 0;
        widget.onSelectDrone?.call(drones[_selectedDroneIndex!]);
      } else {
        _selectedDroneIndex = null;
        widget.onSelectDrone?.call(null);
      }
    });
  }

  /// Удаляет конфигурацию дрона по указанному индексу.
  ///
  /// [index] - Индекс удаляемой конфигурации в списке.
  void _removeDrone(int index) {
    setState(() {
      drones.removeAt(index);
      // Если удален активный дрон, сбрасываем выбор или выбираем первый
      if (_selectedDroneIndex == index) {
        _selectedDroneIndex = drones.isNotEmpty ? 0 : null;
        widget.onSelectDrone?.call(
          _selectedDroneIndex != null ? drones[_selectedDroneIndex!] : null,
        );
      } else if (_selectedDroneIndex != null && _selectedDroneIndex! > index) {
        _selectedDroneIndex = _selectedDroneIndex! - 1;
      }
    });
    _storage.saveDrones(drones);
    _storage.saveSelectedDroneIndex(_selectedDroneIndex);
  }

  /// Выбирает дрон как активный.
  ///
  /// [index] - Индекс выбираемого дрона.
  void _selectDrone(int index) {
    setState(() {
      _selectedDroneIndex = index;
    });
    _storage.saveSelectedDroneIndex(_selectedDroneIndex);
    widget.onSelectDrone?.call(drones[index]);
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
            onSave: (config) {
              setState(() {
                if (index != null) {
                  drones[index] = config;
                } else {
                  drones.add(config);
                  // Если добавлен новый дрон и нет активного, выбираем его
                  if (_selectedDroneIndex == null) {
                    _selectedDroneIndex = drones.length - 1;
                    widget.onSelectDrone?.call(drones[_selectedDroneIndex!]);
                    _storage.saveSelectedDroneIndex(_selectedDroneIndex);
                  }
                }
              });
              _storage.saveDrones(drones);
            },
          ),
    );
  }

  /// Проверяет, является ли конфигурация дрона конфигурацией по умолчанию.
  ///
  /// [drone] - Конфигурация дрона для проверки.
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
        width: screenWidth * 2 / 3,
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
                  final isSelected = _selectedDroneIndex == index;
                  return ListTile(
                    leading: IconButton(
                      icon: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => _selectDrone(index),
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

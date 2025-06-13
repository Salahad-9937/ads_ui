import 'dart:async';
import '../entities/drone_config.dart';
import '../repositories/drone_config_repository.dart';

class ManageDronesUseCase {
  final DroneConfigRepository _repository;
  final StreamController<DroneConfig?> _selectedDroneController =
      StreamController<DroneConfig?>.broadcast();

  ManageDronesUseCase(this._repository);

  List<DroneConfig> _drones = [];
  int? _selectedDroneIndex;

  List<DroneConfig> get drones => List.unmodifiable(_drones);
  int? get selectedDroneIndex => _selectedDroneIndex;
  DroneConfig? get selectedDrone =>
      _selectedDroneIndex != null && _selectedDroneIndex! < _drones.length
          ? _drones[_selectedDroneIndex!]
          : null;
  Stream<DroneConfig?> get selectedDroneStream =>
      _selectedDroneController.stream;

  /// Загружает список дронов и активный дрон.
  Future<void> loadDrones() async {
    _drones = await _repository.loadDrones();
    final selectedIndex = await _repository.loadSelectedDroneIndex();
    if (_drones.isNotEmpty) {
      _selectedDroneIndex =
          selectedIndex != null && selectedIndex < _drones.length
              ? selectedIndex
              : 0;
    } else {
      _selectedDroneIndex = null;
    }
    _selectedDroneController.add(selectedDrone);
  }

  /// Добавляет новый дрон.
  Future<void> addDrone(DroneConfig config) async {
    _drones.add(config);
    if (_selectedDroneIndex == null) {
      _selectedDroneIndex = _drones.length - 1;
      await _repository.saveSelectedDroneIndex(_selectedDroneIndex);
      _selectedDroneController.add(selectedDrone);
    }
    await _repository.saveDrones(_drones);
  }

  /// Обновляет дрон по индексу.
  Future<void> updateDrone(int index, DroneConfig config) async {
    if (index >= 0 && index < _drones.length) {
      _drones[index] = config;
      await _repository.saveDrones(_drones);
      if (_selectedDroneIndex == index) {
        _selectedDroneController.add(selectedDrone);
      }
    }
  }

  /// Удаляет дрон по индексу.
  Future<void> removeDrone(int index) async {
    if (index >= 0 && index < _drones.length) {
      _drones.removeAt(index);
      if (_selectedDroneIndex == index) {
        _selectedDroneIndex = _drones.isNotEmpty ? 0 : null;
        await _repository.saveSelectedDroneIndex(_selectedDroneIndex);
        _selectedDroneController.add(selectedDrone);
      } else if (_selectedDroneIndex != null && _selectedDroneIndex! > index) {
        _selectedDroneIndex = _selectedDroneIndex! - 1;
        await _repository.saveSelectedDroneIndex(_selectedDroneIndex);
        _selectedDroneController.add(selectedDrone);
      }
      await _repository.saveDrones(_drones);
    }
  }

  /// Выбирает дрон по индексу.
  Future<void> selectDrone(int index) async {
    if (index >= 0 && index < _drones.length) {
      _selectedDroneIndex = index;
      await _repository.saveSelectedDroneIndex(_selectedDroneIndex);
      _selectedDroneController.add(selectedDrone);
    }
  }

  /// Проверяет, является ли дрон конфигурацией по умолчанию.
  bool isDefaultDrone(DroneConfig drone) {
    return drone.name == 'Default Drone' && drone.ipAddress == 'localhost';
  }

  /// Освобождает ресурсы.
  void dispose() {
    _selectedDroneController.close();
  }
}

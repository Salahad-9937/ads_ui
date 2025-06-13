import '../../../domain/entities/drone_config.dart';
import '../../../domain/repositories/drone_config_repository.dart';
import '../../../domain/use_cases/manage_drones_use_case.dart';

/// Менеджер для управления конфигурациями дронов и их состоянием.
class DroneManager {
  final ManageDronesUseCase _useCase;
  Function? _onDroneSelected;

  DroneManager({required DroneConfigRepository repository})
    : _useCase = ManageDronesUseCase(repository);

  List<DroneConfig> get drones => _useCase.drones;
  int? get selectedDroneIndex => _useCase.selectedDroneIndex;
  DroneConfig? get selectedDrone => _useCase.selectedDrone;

  /// Устанавливает callback для уведомления о смене активного дрона.
  void setOnDroneSelectedCallback(Function callback) {
    _onDroneSelected = callback;
  }

  /// Загружает список конфигураций дронов.
  Future<void> loadDrones() async {
    await _useCase.loadDrones();
    _onDroneSelected?.call();
  }

  /// Добавляет новую конфигурацию дрона.
  Future<void> addDrone(DroneConfig config) async {
    await _useCase.addDrone(config);
    _onDroneSelected?.call();
  }

  /// Обновляет конфигурацию дрона по индексу.
  Future<void> updateDrone(int index, DroneConfig config) async {
    await _useCase.updateDrone(index, config);
    if (_useCase.selectedDroneIndex == index) {
      _onDroneSelected?.call();
    }
  }

  /// Удаляет конфигурацию дрона по индексу.
  Future<void> removeDrone(int index) async {
    await _useCase.removeDrone(index);
    _onDroneSelected?.call();
  }

  /// Выбирает дрон как активный.
  Future<void> selectDrone(int index) async {
    await _useCase.selectDrone(index);
    _onDroneSelected?.call();
  }

  /// Проверяет, является ли конфигурация дрона конфигурацией по умолчанию.
  bool isDefaultDrone(DroneConfig drone) {
    return _useCase.isDefaultDrone(drone);
  }
}

import '../../../domain/entities/drone_config.dart';
import 'drone_config_storage.dart';

/// Менеджер для управления конфигурациями дронов и их состоянием.
///
/// Отвечает за загрузку, сохранение, выбор и управление дронами.
class DroneManager {
  final DroneConfigStorage _storage = DroneConfigStorage();

  List<DroneConfig> _drones = [];
  int? _selectedDroneIndex;
  Function? _onDroneSelected; // Callback для уведомления о смене дрона

  List<DroneConfig> get drones => List.unmodifiable(_drones);
  int? get selectedDroneIndex => _selectedDroneIndex;
  DroneConfig? get selectedDrone =>
      _selectedDroneIndex != null ? _drones[_selectedDroneIndex!] : null;

  /// Устанавливает callback для уведомления о смене активного дрона.
  void setOnDroneSelectedCallback(Function callback) {
    _onDroneSelected = callback;
  }

  /// Загружает список конфигураций дронов и индекс активного дрона из хранилища.
  Future<void> loadDrones() async {
    _drones = await _storage.loadDrones();
    final selectedIndex = await _storage.loadSelectedDroneIndex();

    if (_drones.isNotEmpty) {
      _selectedDroneIndex =
          selectedIndex != null && selectedIndex < _drones.length
              ? selectedIndex
              : 0;
      _onDroneSelected?.call(); // Уведомляем о выборе дрона при загрузке
    } else {
      _selectedDroneIndex = null;
    }
  }

  /// Добавляет новую конфигурацию дрона.
  ///
  /// [config] - Конфигурация дрона для добавления.
  Future<void> addDrone(DroneConfig config) async {
    _drones.add(config);

    // Если добавлен новый дрон и нет активного, выбираем его
    if (_selectedDroneIndex == null) {
      _selectedDroneIndex = _drones.length - 1;
      await _storage.saveSelectedDroneIndex(_selectedDroneIndex);
      _onDroneSelected?.call(); // Уведомляем о смене дрона
    }

    await _storage.saveDrones(_drones);
  }

  /// Обновляет конфигурацию дрона по указанному индексу.
  ///
  /// [index] - Индекс обновляемой конфигурации.
  /// [config] - Новая конфигурация дрона.
  Future<void> updateDrone(int index, DroneConfig config) async {
    if (index >= 0 && index < _drones.length) {
      _drones[index] = config;
      await _storage.saveDrones(_drones);
      if (_selectedDroneIndex == index) {
        _onDroneSelected?.call(); // Уведомляем, если обновлён активный дрон
      }
    }
  }

  /// Удаляет конфигурацию дрона по указанному индексу.
  ///
  /// [index] - Индекс удаляемой конфигурации в списке.
  Future<void> removeDrone(int index) async {
    if (index >= 0 && index < _drones.length) {
      _drones.removeAt(index);

      // Если удален активный дрон, сбрасываем выбор или выбираем первый
      if (_selectedDroneIndex == index) {
        _selectedDroneIndex = _drones.isNotEmpty ? 0 : null;
        await _storage.saveSelectedDroneIndex(_selectedDroneIndex);
        _onDroneSelected?.call(); // Уведомляем о смене дрона
      } else if (_selectedDroneIndex != null && _selectedDroneIndex! > index) {
        _selectedDroneIndex = _selectedDroneIndex! - 1;
        await _storage.saveSelectedDroneIndex(_selectedDroneIndex);
      }

      await _storage.saveDrones(_drones);
    }
  }

  /// Выбирает дрон как активный.
  ///
  /// [index] - Индекс выбираемого дрона.
  Future<void> selectDrone(int index) async {
    if (index >= 0 && index < _drones.length) {
      _selectedDroneIndex = index;
      await _storage.saveSelectedDroneIndex(_selectedDroneIndex);
      _onDroneSelected?.call(); // Уведомляем о смене дрона
    }
  }

  /// Проверяет, является ли конфигурация дрона конфигурацией по умолчанию.
  ///
  /// [drone] - Конфигурация дрона для проверки.
  bool isDefaultDrone(DroneConfig drone) {
    return drone.name == 'Default Drone' && drone.ipAddress == 'localhost';
  }
}

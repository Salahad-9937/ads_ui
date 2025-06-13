import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/drone_config.dart';
import '../../domain/use_cases/manage_drones_use_case.dart';
import '../../domain/use_cases/manage_websocket_use_case.dart';

class MainScreenViewModel {
  final ManageWebSocketUseCase _webSocketUseCase;
  final ManageDronesUseCase _dronesUseCase;

  final _droneStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _imageController = StreamController<Uint8List?>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _autoReconnectController = StreamController<bool>.broadcast();
  final _currentDroneController = StreamController<DroneConfig?>.broadcast();
  final _expandedViewController = StreamController<String?>.broadcast();

  Stream<Map<String, dynamic>> get droneStatusStream =>
      _droneStatusController.stream;
  Stream<Uint8List?> get imageStream => _imageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get autoReconnectStream => _autoReconnectController.stream;
  Stream<DroneConfig?> get currentDroneStream => _currentDroneController.stream;
  Stream<String?> get expandedViewStream => _expandedViewController.stream;

  String? _expandedView; // Храним текущее значение expandedView

  MainScreenViewModel({
    required ManageWebSocketUseCase webSocketUseCase,
    required ManageDronesUseCase dronesUseCase,
  }) : _webSocketUseCase = webSocketUseCase,
       _dronesUseCase = dronesUseCase {
    _init();
  }

  void _init() {
    // Подписка на потоки из use cases
    _dronesUseCase.selectedDroneStream.listen((drone) {
      _currentDroneController.add(drone);
      _webSocketUseCase.updateDrone(drone);
      if (kDebugMode) {
        print(
          'MainScreenViewModel: Drone changed to ${drone?.name} (${drone?.ipAddress}:${drone?.port})',
        );
      }
    });

    _webSocketUseCase.droneStatusStream.listen((status) {
      _droneStatusController.add(status);
    });

    _webSocketUseCase.imageStream.listen((image) {
      _imageController.add(image);
    });

    _webSocketUseCase.connectionStream.listen((connected) {
      _connectionController.add(connected);
    });

    _webSocketUseCase.autoReconnectStream.listen((enabled) {
      _autoReconnectController.add(enabled);
    });

    // Загрузка начальных данных
    _dronesUseCase.loadDrones().then((_) {
      _currentDroneController.add(_dronesUseCase.selectedDrone);
      _webSocketUseCase.updateDrone(_dronesUseCase.selectedDrone);
    });

    // Начальное значение для expandedView
    _expandedView = null;
    _expandedViewController.add(_expandedView);
  }

  void toggleView(String view) {
    _expandedView = _expandedView == view ? null : view;
    _expandedViewController.add(_expandedView);
  }

  void connectToServer() => _webSocketUseCase.connectToServer();

  void disconnect() => _webSocketUseCase.disconnect();

  void toggleAutoReconnect() => _webSocketUseCase.toggleAutoReconnect();

  void dispose() {
    _droneStatusController.close();
    _imageController.close();
    _connectionController.close();
    _autoReconnectController.close();
    _currentDroneController.close();
    _expandedViewController.close();
    _webSocketUseCase.dispose();
    _dronesUseCase.dispose();
  }
}

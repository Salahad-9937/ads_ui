// lib/domain/use_cases/manage_websocket_use_case.dart
import 'dart:typed_data';
import '../../servises/websocket_service.dart';
import '../entities/drone_config.dart';

/// Use case для управления WebSocket-соединением с дроном.
class ManageWebSocketUseCase {
  final WebSocketService _webSocketService;

  ManageWebSocketUseCase({required WebSocketService webSocketService})
    : _webSocketService = webSocketService;

  /// Поток статуса дрона.
  Stream<Map<String, dynamic>> get droneStatusStream =>
      _webSocketService.droneStatusStream;

  /// Поток изображения с камеры дрона.
  Stream<Uint8List?> get imageStream => _webSocketService.imageStream;

  /// Поток состояния соединения.
  Stream<bool> get connectionStream => _webSocketService.connectionStream;

  /// Поток состояния автопереподключения.
  Stream<bool> get autoReconnectStream => _webSocketService.autoReconnectStream;

  /// Подключается к серверу дрона.
  void connectToServer() {
    _webSocketService.connectToServer();
  }

  /// Отключается от сервера дрона.
  void disconnect() {
    _webSocketService.disconnect();
  }

  /// Переключает режим автопереподключения.
  void toggleAutoReconnect() {
    _webSocketService.toggleAutoReconnect();
  }

  /// Обновляет текущий дрон для подключения.
  void updateDrone(DroneConfig? drone) {
    _webSocketService.updateDrone(drone);
  }

  /// Освобождает ресурсы.
  void dispose() {
    _webSocketService.dispose();
  }
}

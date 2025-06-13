// lib/servises/websocket_service.dart
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import '../main_screen/menubar/connection_settings/drone_manager.dart';
import '../domain/entities/drone_config.dart';

/// Сервис для управления WebSocket-соединением с сервером дрона.
class WebSocketService {
  WebSocketChannel? _channel;
  Map<String, dynamic> _droneStatus = {};
  Uint8List? _currentImage;
  bool _isConnected = false;
  bool _isReconnecting = false;
  bool _autoReconnect = false;
  bool _explicitlyConnected = false;
  Timer? _reconnectTimer;
  final DroneManager droneManager;
  DroneConfig? _currentDrone;

  final StreamController<Map<String, dynamic>> _droneStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Uint8List?> _imageController =
      StreamController<Uint8List?>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _autoReconnectController =
      StreamController<bool>.broadcast();

  WebSocketService({required this.droneManager}) {
    _currentDrone = droneManager.selectedDrone;
    droneManager.setOnDroneSelectedCallback(_onDroneSelected);
  }

  Stream<Map<String, dynamic>> get droneStatusStream =>
      _droneStatusController.stream;
  Stream<Uint8List?> get imageStream => _imageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get autoReconnectStream => _autoReconnectController.stream;

  bool get isConnected => _isConnected;
  Map<String, dynamic> get droneStatus => _droneStatus;
  Uint8List? get currentImage => _currentImage;
  bool get autoReconnect => _autoReconnect;

  /// Обновляет текущий дрон для подключения
  void updateDrone(DroneConfig? drone) {
    _currentDrone = drone;
    if (kDebugMode) {
      print(
        'Updated drone: ${_currentDrone?.name} (${_currentDrone?.ipAddress}:${_currentDrone?.port})',
      );
    }
    if (_isConnected) {
      disconnect();
      if (_explicitlyConnected) {
        connectToServer();
      }
    }
    _droneStatusController.add({});
    _imageController.add(null);
  }

  /// Устанавливает соединение с сервером через WebSocket.
  void connectToServer() async {
    if (_isReconnecting || _isConnected) return;
    _isReconnecting = true;
    _explicitlyConnected = true;

    try {
      final drone =
          _currentDrone ??
          DroneConfig(
            name: 'Default Drone',
            ipAddress: 'localhost',
            port: 8765,
            isVirtual: true,
            sshUsername: '',
            sshPassword: '',
          );
      final url = 'ws://${drone.ipAddress}:${drone.port}';
      if (kDebugMode) {
        print('Connecting to: ws://${drone.ipAddress}:${drone.port}');
      }
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      _connectionController.add(true);

      _channel!.stream.listen(
        (data) {
          try {
            final message = json.decode(data);
            if (message['type'] == 'status') {
              _droneStatus = message['data'];
              _droneStatusController.add(_droneStatus);
            } else if (message['type'] == 'image') {
              _currentImage = base64Decode(message['data']);
              _imageController.add(_currentImage);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing WebSocket data: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
          _handleDisconnect();
        },
        onDone: () {
          if (kDebugMode) {
            print('WebSocket closed');
          }
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Connection error: $e');
      }
      _handleDisconnect();
    } finally {
      _isReconnecting = false;
    }
  }

  /// Разрывает соединение с сервером.
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _droneStatus = {};
    _currentImage = null;
    _explicitlyConnected = false;
    _connectionController.add(false);
    _droneStatusController.add({});
    _imageController.add(null);
    if (kDebugMode) {
      print('Disconnected from WebSocket');
    }
  }

  /// Включает или отключает автоматическое переподключение.
  void toggleAutoReconnect() {
    _autoReconnect = !_autoReconnect;
    _autoReconnectController.add(_autoReconnect);
    if (!_autoReconnect) {
      _reconnectTimer?.cancel();
    } else if (!_isConnected && _explicitlyConnected) {
      _startReconnectTimer();
    }
  }

  /// Обрабатывает разрыв соединения и инициирует переподключение, если включено.
  void _handleDisconnect() {
    _isConnected = false;
    _droneStatus = {};
    _currentImage = null;
    _connectionController.add(false);
    _droneStatusController.add({});
    _imageController.add(null);
    _channel?.sink.close();
    _channel = null;
    if (_autoReconnect && _explicitlyConnected) {
      _startReconnectTimer();
    }
  }

  /// Запускает таймер для периодических попыток переподключения.
  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isConnected &&
          !_isReconnecting &&
          _explicitlyConnected &&
          _autoReconnect) {
        connectToServer();
      }
      if (_isConnected || !_explicitlyConnected) {
        timer.cancel();
      }
    });
  }

  /// Обрабатывает смену активного дрона.
  void _onDroneSelected() {
    _currentDrone = droneManager.selectedDrone;
    if (kDebugMode) {
      print(
        'Drone selected: ${_currentDrone?.name} (${_currentDrone?.ipAddress}:${_currentDrone?.port})',
      );
    }
    if (_isConnected) {
      disconnect();
      if (_explicitlyConnected) {
        connectToServer();
      }
    }
    _droneStatusController.add({});
    _imageController.add(null);
  }

  /// Освобождает ресурсы, закрывая соединение и отменяя таймер.
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _droneStatusController.close();
    _imageController.close();
    _connectionController.close();
    _autoReconnectController.close();
  }
}

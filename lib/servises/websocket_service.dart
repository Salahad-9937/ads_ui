import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import '../main_screen/menubar/connection_settings/drone_manager.dart';
import '../main_screen/menubar/connection_settings/drone_config.dart';

/// Сервис для управления WebSocket-соединением с сервером дрона.
///
/// [_channel] - Канал WebSocket для связи с сервером.
/// [_droneStatus] - Текущий статус дрона.
/// [_currentImage] - Текущее изображение с камеры дрона.
/// [_isConnected] - Флаг, указывающий, активно ли соединение.
/// [_isReconnecting] - Флаг, указывающий, выполняется ли переподключение.
/// [_autoReconnect] - Флаг, указывающий, включено ли автоматическое переподключение.
/// [_explicitlyConnected] - Флаг, указывающий, было ли соединение инициировано явно.
/// [_reconnectTimer] - Таймер для автоматического переподключения.
/// [droneManager] - Менеджер для получения конфигурации активного дрона.
/// [onStatusUpdate] - Callback для обновления статуса дрона.
/// [onImageUpdate] - Callback для обновления изображения.
/// [onConnectionUpdate] - Callback для обновления состояния соединения.
/// [onAutoReconnectUpdate] - Callback для обновления состояния автопереподключения.
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
  final Function(Map<String, dynamic>) onStatusUpdate;
  final Function(Uint8List?) onImageUpdate;
  final Function(bool) onConnectionUpdate;
  final Function(bool) onAutoReconnectUpdate;

  WebSocketService({
    required this.droneManager,
    required this.onStatusUpdate,
    required this.onImageUpdate,
    required this.onConnectionUpdate,
    required this.onAutoReconnectUpdate,
  });

  bool get isConnected => _isConnected;
  Map<String, dynamic> get droneStatus => _droneStatus;
  Uint8List? get currentImage => _currentImage;
  bool get autoReconnect => _autoReconnect;

  /// Устанавливает соединение с сервером через WebSocket.
  void connectToServer() async {
    if (_isReconnecting || _isConnected) return;
    _isReconnecting = true;
    _explicitlyConnected = true;

    try {
      // Получаем конфигурацию активного дрона или используем значения по умолчанию
      final drone =
          droneManager.selectedDrone ??
          DroneConfig(
            name: 'Default Drone',
            ipAddress: 'localhost',
            port: 8765,
            isVirtual: true,
            sshUsername: '',
            sshPassword: '',
          );
      final url = 'ws://${drone.ipAddress}:${drone.port}';
      print('Connecting to: ws://${drone.ipAddress}:${drone.port}');
      _channel = WebSocketChannel.connect(Uri.parse(url));
      onConnectionUpdate(true);
      _isConnected = true;

      _channel!.stream.listen(
        (data) {
          final message = json.decode(data);
          if (message['type'] == 'status') {
            _droneStatus = message['data'];
            onStatusUpdate(_droneStatus);
          } else if (message['type'] == 'image') {
            _currentImage = base64Decode(message['data']);
            onImageUpdate(_currentImage);
          }
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
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
    onConnectionUpdate(false);
    onStatusUpdate({});
    onImageUpdate(null);
  }

  /// Включает или отключает автоматическое переподключение.
  void toggleAutoReconnect() {
    _autoReconnect = !_autoReconnect;
    onAutoReconnectUpdate(_autoReconnect);
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
    onConnectionUpdate(false);
    onStatusUpdate({});
    onImageUpdate(null);
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

  /// Освобождает ресурсы, закрывая соединение и отменяя таймер.
  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

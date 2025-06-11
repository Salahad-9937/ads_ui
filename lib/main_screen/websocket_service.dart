import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';

class WebSocketService {
  WebSocketChannel? _channel;
  Map<String, dynamic> _droneStatus = {};
  Uint8List? _currentImage;
  bool _isConnected = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  final Function(Map<String, dynamic>) onStatusUpdate;
  final Function(Uint8List?) onImageUpdate;
  final Function(bool) onConnectionUpdate;

  WebSocketService({
    required this.onStatusUpdate,
    required this.onImageUpdate,
    required this.onConnectionUpdate,
  });

  bool get isConnected => _isConnected;
  Map<String, dynamic> get droneStatus => _droneStatus;
  Uint8List? get currentImage => _currentImage;

  void connectToServer() async {
    if (_isReconnecting) return;
    _isReconnecting = true;

    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8765'));
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

  void _handleDisconnect() {
    _isConnected = false;
    _droneStatus = {};
    _currentImage = null;
    onConnectionUpdate(false);
    onStatusUpdate({});
    onImageUpdate(null);
    _channel?.sink.close();
    _channel = null;
    _startReconnectTimer();
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected && !_isReconnecting) {
        connectToServer();
      }
      if (_isConnected) {
        timer.cancel();
      }
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

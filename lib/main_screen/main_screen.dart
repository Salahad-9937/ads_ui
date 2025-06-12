import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'menubar/menu_bar.dart';
import 'panels/panel_container.dart';
import 'view_window/view_window.dart';
import '../servises/websocket_service.dart';
import 'panels/status_panel.dart';
import 'panels/tasks_panel.dart';
import 'menubar/connection_settings/drone_manager.dart';

/// Главный экран приложения, отображающий интерфейс управления дроном.
///
/// [webSocketService] - Сервис для работы с WebSocket-соединением.
/// [droneStatus] - Текущий статус дрона.
/// [currentImage] - Текущее изображение с камеры дрона.
/// [isConnected] - Флаг, указывающий, активно ли соединение с сервером.
/// [isAutoReconnectEnabled] - Флаг, указывающий, включено ли автоматическое переподключение.
/// [expandedView] - Идентификатор развернутого вида (например, 'camera1', 'camera2').
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late WebSocketService webSocketService;
  late DroneManager droneManager;
  Map<String, dynamic> droneStatus = {};
  Uint8List? currentImage;
  bool isConnected = false;
  bool isAutoReconnectEnabled = false;
  String? expandedView;

  @override
  void initState() {
    super.initState();
    droneManager = DroneManager();
    droneManager.loadDrones(); // Загружаем конфигурации дронов
    webSocketService = WebSocketService(
      droneManager: droneManager,
      onStatusUpdate: (status) {
        setState(() {
          droneStatus = status;
        });
      },
      onImageUpdate: (image) {
        setState(() {
          currentImage = image;
        });
      },
      onConnectionUpdate: (connected) {
        setState(() {
          isConnected = connected;
        });
      },
      onAutoReconnectUpdate: (enabled) {
        setState(() {
          isAutoReconnectEnabled = enabled;
        });
      },
    );
  }

  @override
  void dispose() {
    webSocketService.dispose();
    super.dispose();
  }

  /// Переключает развернутый вид для указанного представления.
  ///
  /// [view] - Идентификатор представления (например, 'camera1', 'camera2').
  void toggleView(String view) {
    setState(() {
      if (expandedView == view) {
        expandedView = null;
      } else {
        expandedView = view;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: DroneMenuBar(
          isConnected: isConnected,
          isAutoReconnectEnabled: isAutoReconnectEnabled,
          onConnect: webSocketService.connectToServer,
          onDisconnect: webSocketService.disconnect,
          onToggleReconnect: webSocketService.toggleAutoReconnect,
        ),
      ),
      body: Row(
        children: [
          PanelContainer(
            isLeftPanel: true,
            child: StatusPanel(droneStatus: droneStatus),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MainWindow(
                  currentImage: currentImage,
                  expandedView: expandedView,
                  toggleView: toggleView,
                  constraints: constraints,
                );
              },
            ),
          ),
          PanelContainer(isLeftPanel: false, child: const TasksPanel()),
        ],
      ),
    );
  }
}

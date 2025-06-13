// lib/main_screen/main_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'menubar/menu_bar.dart';
import 'panels/panel_container.dart';
import 'view_window/view_window.dart';
import '../servises/websocket_service.dart';
import 'panels/status_panel.dart';
import 'panels/tasks_panel.dart';
import 'menubar/connection_settings/drone_manager.dart';
import 'menubar/connection_settings/drone_config_storage.dart';
import '../domain/entities/drone_config.dart';
import '../domain/use_cases/manage_websocket_use_case.dart';

/// Главный экран приложения, отображающий интерфейс управления дроном.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late ManageWebSocketUseCase _webSocketUseCase;
  late DroneManager droneManager;
  Map<String, dynamic> droneStatus = {};
  Uint8List? currentImage;
  bool isConnected = false;
  bool isAutoReconnectEnabled = false;
  String? expandedView;
  DroneConfig? currentDrone;

  @override
  void initState() {
    super.initState();
    // Временное создание репозитория и сервисов, в будущем использовать DI
    final repository = DroneConfigStorage();
    droneManager = DroneManager(repository: repository);
    final webSocketService = WebSocketService(droneManager: droneManager);
    _webSocketUseCase = ManageWebSocketUseCase(
      webSocketService: webSocketService,
    );

    droneManager.setOnDroneSelectedCallback(_onDroneSelected);
    droneManager.loadDrones().then((_) {
      setState(() {
        currentDrone = droneManager.selectedDrone;
        _webSocketUseCase.updateDrone(currentDrone);
      });
    });

    // Подписка на потоки
    _webSocketUseCase.droneStatusStream.listen((status) {
      setState(() {
        droneStatus = status;
      });
    });
    _webSocketUseCase.imageStream.listen((image) {
      setState(() {
        currentImage = image;
      });
    });
    _webSocketUseCase.connectionStream.listen((connected) {
      setState(() {
        isConnected = connected;
      });
    });
    _webSocketUseCase.autoReconnectStream.listen((enabled) {
      setState(() {
        isAutoReconnectEnabled = enabled;
      });
    });
  }

  /// Обрабатывает смену активного дрона
  void _onDroneSelected() {
    setState(() {
      currentDrone = droneManager.selectedDrone;
      _webSocketUseCase.updateDrone(currentDrone);
      if (kDebugMode) {
        print(
          'MainScreen: Drone changed to ${currentDrone?.name} (${currentDrone?.ipAddress}:${currentDrone?.port})',
        );
      }
    });
  }

  @override
  void dispose() {
    _webSocketUseCase.dispose();
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
          onConnect: _webSocketUseCase.connectToServer,
          onDisconnect: _webSocketUseCase.disconnect,
          onToggleReconnect: _webSocketUseCase.toggleAutoReconnect,
          droneManager: droneManager,
          webSocketService:
              _webSocketUseCase, // Временная передача для совместимости
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

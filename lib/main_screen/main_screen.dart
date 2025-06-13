import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../di.dart';
import 'menubar/menu_bar.dart';
import 'panels/panel_container.dart';
import 'view_window/view_window.dart';
import '../domain/use_cases/manage_websocket_use_case.dart';
import '../domain/use_cases/manage_drones_use_case.dart';
import 'panels/status_panel.dart';
import 'panels/tasks_panel.dart';
import '../domain/entities/drone_config.dart';

/// Главный экран приложения, отображающий интерфейс управления дроном.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final ManageWebSocketUseCase _webSocketUseCase =
      getIt<ManageWebSocketUseCase>();
  final ManageDronesUseCase _dronesUseCase = getIt<ManageDronesUseCase>();
  Map<String, dynamic> droneStatus = {};
  Uint8List? currentImage;
  bool isConnected = false;
  bool isAutoReconnectEnabled = false;
  String? expandedView;
  DroneConfig? currentDrone;

  @override
  void initState() {
    super.initState();
    _dronesUseCase.selectedDroneStream.listen(_onDroneSelected);
    _dronesUseCase.loadDrones().then((_) {
      setState(() {
        currentDrone = _dronesUseCase.selectedDrone;
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
  void _onDroneSelected(DroneConfig? drone) {
    setState(() {
      currentDrone = drone;
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
    _dronesUseCase.dispose();
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
          dronesUseCase: _dronesUseCase,
          webSocketUseCase: _webSocketUseCase,
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../di.dart';
import '../presentation/view_models/main_screen_view_model.dart';
import '../domain/use_cases/manage_drones_use_case.dart';
import '../domain/use_cases/manage_websocket_use_case.dart';
import 'menubar/menu_bar.dart';
import 'panels/panel_container.dart';
import 'view_window/view_window.dart';
import 'panels/status_panel.dart';
import 'panels/tasks_panel.dart';

/// Главный экран приложения, отображающий интерфейс управления дроном.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final MainScreenViewModel _viewModel = getIt<MainScreenViewModel>();

  Map<String, dynamic> _droneStatus = {};
  Uint8List? _currentImage;
  bool _isConnected = false;
  bool _isAutoReconnectEnabled = false;
  String? _expandedView;

  @override
  void initState() {
    super.initState();
    // Подписка на потоки из ViewModel
    _viewModel.droneStatusStream.listen((status) {
      setState(() {
        _droneStatus = status;
      });
    });
    _viewModel.imageStream.listen((image) {
      setState(() {
        _currentImage = image;
      });
    });
    _viewModel.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
    });
    _viewModel.autoReconnectStream.listen((enabled) {
      setState(() {
        _isAutoReconnectEnabled = enabled;
      });
    });
    _viewModel.expandedViewStream.listen((view) {
      setState(() {
        _expandedView = view;
      });
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: DroneMenuBar(
          isConnected: _isConnected,
          isAutoReconnectEnabled: _isAutoReconnectEnabled,
          onConnect: _viewModel.connectToServer,
          onDisconnect: _viewModel.disconnect,
          onToggleReconnect: _viewModel.toggleAutoReconnect,
          dronesUseCase: getIt.get<ManageDronesUseCase>(),
          webSocketUseCase: getIt.get<ManageWebSocketUseCase>(),
        ),
      ),
      body: Row(
        children: [
          PanelContainer(
            isLeftPanel: true,
            child: StatusPanel(droneStatus: _droneStatus),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MainWindow(
                  currentImage: _currentImage,
                  expandedView: _expandedView,
                  toggleView: _viewModel.toggleView,
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

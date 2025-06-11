import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'menu_bar.dart';
import 'panels/status_panel_container.dart';
import 'panels/tasks_panel_container.dart';
import 'main_window.dart';
import 'websocket_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late WebSocketService webSocketService;
  Map<String, dynamic> droneStatus = {};
  Uint8List? currentImage;
  bool isConnected = false;
  bool isAutoReconnectEnabled = false;
  String? expandedView;

  @override
  void initState() {
    super.initState();
    webSocketService = WebSocketService(
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
          StatusPanelContainer(droneStatus: droneStatus),
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
          TasksPanelContainer(),
        ],
      ),
    );
  }
}

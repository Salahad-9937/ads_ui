import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'menu_bar.dart';
import 'tasks_panel.dart';
import 'status_panel.dart';
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
  bool isStatusPanelOpen = false;
  bool isTasksPanelOpen = false;
  late AnimationController _statusPanelController;
  late AnimationController _tasksPanelController;
  late Animation<Offset> _statusPanelAnimation;
  late Animation<Offset> _tasksPanelAnimation;
  late AnimationController _statusWidthController;
  late AnimationController _tasksWidthController;
  late Animation<double> _statusWidthAnimation;
  late Animation<double> _tasksWidthAnimation;

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

    _statusPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tasksPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _statusWidthController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tasksWidthController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _statusPanelAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _statusPanelController, curve: Curves.easeInOut),
    );
    _tasksPanelAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: const Offset(0.0, 0.0),
    ).animate(
      CurvedAnimation(parent: _tasksPanelController, curve: Curves.easeInOut),
    );
    _statusWidthAnimation = Tween<double>(begin: 30.0, end: 280.0).animate(
      CurvedAnimation(parent: _statusWidthController, curve: Curves.easeInOut),
    );
    _tasksWidthAnimation = Tween<double>(begin: 30.0, end: 280.0).animate(
      CurvedAnimation(parent: _tasksWidthController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    webSocketService.dispose();
    _statusPanelController.dispose();
    _tasksPanelController.dispose();
    _statusWidthController.dispose();
    _tasksWidthController.dispose();
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

  void _toggleStatusPanel() {
    setState(() {
      isStatusPanelOpen = !isStatusPanelOpen;
      if (isStatusPanelOpen) {
        _statusPanelController.forward();
        _statusWidthController.forward();
      } else {
        _statusPanelController.reverse();
        _statusWidthController.reverse();
      }
    });
  }

  void _toggleTasksPanel() {
    setState(() {
      isTasksPanelOpen = !isTasksPanelOpen;
      if (isTasksPanelOpen) {
        _tasksPanelController.forward();
        _tasksWidthController.forward();
      } else {
        _tasksPanelController.reverse();
        _tasksWidthController.reverse();
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
          // Status Panel
          AnimatedBuilder(
            animation: _statusWidthAnimation,
            builder: (context, child) {
              return SizedBox(
                width: _statusWidthAnimation.value,
                child: ClipRect(
                  child: Row(
                    children: [
                      if (_statusWidthAnimation.value > 250)
                        Expanded(
                          child: SlideTransition(
                            position: _statusPanelAnimation,
                            child: SizedBox(
                              width: _statusWidthAnimation.value - 30,
                              child: Drawer(
                                child: StatusPanel(droneStatus: droneStatus),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: 30,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onTap: _toggleStatusPanel,
                              child: Container(
                                height: constraints.maxHeight,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    isStatusPanelOpen
                                        ? Icons.chevron_left
                                        : Icons.chevron_right,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Main Content
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
          // Tasks Panel
          AnimatedBuilder(
            animation: _tasksWidthAnimation,
            builder: (context, child) {
              return SizedBox(
                width: _tasksWidthAnimation.value,
                child: ClipRect(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onTap: _toggleTasksPanel,
                              child: Container(
                                height: constraints.maxHeight,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    isTasksPanelOpen
                                        ? Icons.chevron_right
                                        : Icons.chevron_left,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_tasksWidthAnimation.value > 250)
                        Expanded(
                          child: SlideTransition(
                            position: _tasksPanelAnimation,
                            child: SizedBox(
                              width: _tasksWidthAnimation.value - 30,
                              child: Drawer(child: TasksPanel()),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

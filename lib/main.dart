import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'menu_bar.dart';
import 'tasks_panel.dart';
import 'status_panel.dart';
import 'main_window.dart';

void main() {
  runApp(DroneControlApp());
}

class DroneControlApp extends StatelessWidget {
  const DroneControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  WebSocketChannel? channel;
  Map<String, dynamic> droneStatus = {};
  Uint8List? currentImage;
  bool isConnected = false;
  String? expandedView;
  bool isStatusPanelOpen = false;
  bool isTasksPanelOpen = false;
  Timer? _reconnectTimer;
  bool _isReconnecting = false;
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
    connectToServer();
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

  void connectToServer() async {
    if (_isReconnecting) return;
    _isReconnecting = true;

    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8765'));
      setState(() {
        isConnected = true;
      });

      channel!.stream.listen(
        (data) {
          final message = json.decode(data);
          if (message['type'] == 'status') {
            setState(() {
              droneStatus = message['data'];
            });
          } else if (message['type'] == 'image') {
            setState(() {
              currentImage = base64Decode(message['data']);
            });
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
    setState(() {
      isConnected = false;
      droneStatus = {};
      currentImage = null;
    });
    channel?.sink.close();
    channel = null;
    _startReconnectTimer();
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isConnected && !_isReconnecting) {
        connectToServer();
      }
      if (isConnected) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    channel?.sink.close();
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
        child: DroneMenuBar(isConnected: isConnected),
      ),
      body: Row(
        children: [
          // Status Panel
          AnimatedBuilder(
            animation: _statusWidthAnimation,
            builder: (context, child) {
              return Container(
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
              return Container(
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'connection_settings/connection_settings_dialog.dart';
import '../../../domain/use_cases/manage_drones_use_case.dart';
import '../../../domain/use_cases/manage_websocket_use_case.dart';

/// Меню приложения для управления подключением и настройками дрона.
class DroneMenuBar extends StatelessWidget {
  final bool isConnected;
  final bool isAutoReconnectEnabled;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onToggleReconnect;
  final ManageDronesUseCase dronesUseCase;
  final ManageWebSocketUseCase webSocketUseCase;

  const DroneMenuBar({
    super.key,
    required this.isConnected,
    required this.isAutoReconnectEnabled,
    required this.onConnect,
    required this.onDisconnect,
    required this.onToggleReconnect,
    required this.dronesUseCase,
    required this.webSocketUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isConnected ? Colors.green : Colors.red,
      child: MenuBar(
        children: [
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                onPressed: onConnect,
                child: const Text('Подключиться'),
              ),
              MenuItemButton(
                onPressed: onDisconnect,
                child: const Text('Отключиться'),
              ),
              MenuItemButton(
                onPressed: onToggleReconnect,
                leadingIcon: Icon(
                  isAutoReconnectEnabled
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 16,
                ),
                child: const Text('Переподключение'),
              ),
            ],
            child: const Text('Подключение'),
          ),
          SubmenuButton(
            menuChildren: [
              MenuItemButton(onPressed: () {}, child: const Text('Калибровка')),
              MenuItemButton(
                onPressed: () {},
                child: const Text('Диагностика'),
              ),
              MenuItemButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => ConnectionSettingsDialog(
                          onSelectDrone: (drone) {
                            // Обновление UI не требуется здесь
                          },
                          webSocketUseCase: webSocketUseCase,
                        ),
                  );
                },
                child: const Text('Настройки подключения'),
              ),
            ],
            child: const Text('Инструменты'),
          ),
          MenuItemButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            leadingIcon: const Icon(Icons.exit_to_app, size: 16),
            child: const Text('Выход'),
          ),
        ],
      ),
    );
  }
}

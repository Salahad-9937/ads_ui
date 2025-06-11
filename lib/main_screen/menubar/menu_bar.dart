import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'connection_settings/connection_settings_dialog.dart';

/// Меню приложения для управления подключением и настройками дрона.
///
/// [isConnected] - Флаг, указывающий, активно ли соединение с дроном.
/// [isAutoReconnectEnabled] - Флаг, указывающий, включено ли автоматическое переподключение.
/// [onConnect] - Callback для подключения к серверу.
/// [onDisconnect] - Callback для отключения от сервера.
/// [onToggleReconnect] - Callback для переключения автоматического переподключения.
class DroneMenuBar extends StatelessWidget {
  final bool isConnected;
  final bool isAutoReconnectEnabled;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onToggleReconnect;

  const DroneMenuBar({
    super.key,
    required this.isConnected,
    required this.isAutoReconnectEnabled,
    required this.onConnect,
    required this.onDisconnect,
    required this.onToggleReconnect,
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
                    builder: (context) => const ConnectionSettingsDialog(),
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

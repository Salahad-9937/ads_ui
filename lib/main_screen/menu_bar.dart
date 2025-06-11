import 'package:flutter/material.dart';

class DroneMenuBar extends StatelessWidget {
  final bool isConnected;

  const DroneMenuBar({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isConnected ? Colors.green : Colors.red,
      child: MenuBar(
        children: [
          SubmenuButton(
            menuChildren: [
              MenuItemButton(onPressed: () {}, child: const Text('Новый')),
              MenuItemButton(onPressed: () {}, child: const Text('Открыть')),
              MenuItemButton(onPressed: () {}, child: const Text('Сохранить')),
            ],
            child: const Text('Файл'),
          ),
          SubmenuButton(
            menuChildren: [
              MenuItemButton(onPressed: () {}, child: const Text('Копировать')),
              MenuItemButton(onPressed: () {}, child: const Text('Вставить')),
              MenuItemButton(onPressed: () {}, child: const Text('Отменить')),
            ],
            child: const Text('Правка'),
          ),
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                onPressed: () {},
                child: const Text('Полный экран'),
              ),
              MenuItemButton(onPressed: () {}, child: const Text('Масштаб')),
            ],
            child: const Text('Вид'),
          ),
          SubmenuButton(
            menuChildren: [
              MenuItemButton(onPressed: () {}, child: const Text('Калибровка')),
              MenuItemButton(
                onPressed: () {},
                child: const Text('Диагностика'),
              ),
            ],
            child: const Text('Инструменты'),
          ),
        ],
      ),
    );
  }
}

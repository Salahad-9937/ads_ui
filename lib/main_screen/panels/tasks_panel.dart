import 'package:flutter/material.dart';

/// Панель для отображения списка текущих задач дрона.
class TasksPanel extends StatelessWidget {
  const TasksPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Текущие задачи',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Задача 1: Патрулирование'),
          subtitle: const Text('Статус: Выполняется'),
        ),
        ListTile(
          title: const Text('Задача 2: Съёмка изображений'),
          subtitle: const Text('Статус: Ожидает'),
        ),
      ],
    );
  }
}

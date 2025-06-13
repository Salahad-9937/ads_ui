// lib/main_screen/panels/status_panel.dart
import 'package:flutter/material.dart';

import '../../presentation/view_models/status_panel_view_model.dart';

/// Панель для отображения текущего статуса дрона.
class StatusPanel extends StatefulWidget {
  const StatusPanel({super.key});

  @override
  StatusPanelState createState() => StatusPanelState();
}

class StatusPanelState extends State<StatusPanel> {
  final StatusPanelViewModel _viewModel = StatusPanelViewModel();
  List<Map<String, dynamic>> _statusItems = [];

  @override
  void initState() {
    super.initState();
    _viewModel.statusStream.listen((items) {
      setState(() {
        _statusItems = items;
      });
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void updateStatus(Map<String, dynamic> droneStatus) {
    _viewModel.updateStatus(droneStatus);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Статус дрона',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_statusItems.isNotEmpty) ...[
          for (final item in _statusItems)
            StatusItem(
              item['label'] as String,
              item['value'] as String,
              item['icon'] as IconData,
            ),
        ] else
          const Center(child: Text('Данные статуса отсутствуют')),
      ],
    );
  }
}

/// Элемент списка для отображения отдельного параметра статуса дрона.
///
/// [label] - Название параметра.
/// [value] - Значение параметра.
/// [icon] - Иконка для отображения рядом с параметром.
class StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatusItem(this.label, this.value, this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

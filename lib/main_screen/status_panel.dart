import 'package:flutter/material.dart';

class StatusPanel extends StatelessWidget {
  final Map<String, dynamic> droneStatus;

  const StatusPanel({super.key, required this.droneStatus});

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
        if (droneStatus.isNotEmpty) ...[
          StatusItem(
            'Батарея',
            droneStatus['battery']?.toString() ?? 'N/A',
            Icons.battery_full,
          ),
          StatusItem(
            'Высота',
            droneStatus['altitude']?.toString() ?? 'N/A',
            Icons.height,
          ),
          StatusItem(
            'Скорость',
            droneStatus['speed']?.toString() ?? 'N/A',
            Icons.speed,
          ),
          StatusItem(
            'Температура',
            droneStatus['temperature']?.toString() ?? 'N/A',
            Icons.thermostat,
          ),
          StatusItem(
            'GPS Широта',
            droneStatus['gps_lat']?.toString() ?? 'N/A',
            Icons.location_on,
          ),
          StatusItem(
            'GPS Долгота',
            droneStatus['gps_lon']?.toString() ?? 'N/A',
            Icons.location_on,
          ),
        ] else
          const Center(child: Text('Данные статуса отсутствуют')),
      ],
    );
  }
}

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

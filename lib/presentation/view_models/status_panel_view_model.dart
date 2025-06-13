// lib/presentation/view_models/status_panel_view_model.dart
import 'dart:async';
import 'package:flutter/material.dart';

class StatusPanelViewModel {
  final _statusController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get statusStream =>
      _statusController.stream;

  StatusPanelViewModel() {
    _init();
  }

  void _init() {
    // Начальное значение для пустого статуса
    _statusController.add([]);
  }

  void updateStatus(Map<String, dynamic> droneStatus) {
    final statusItems = [
      {
        'label': 'Батарея',
        'value': droneStatus['battery']?.toString() ?? 'N/A',
        'icon': Icons.battery_full,
      },
      {
        'label': 'Высота',
        'value': droneStatus['altitude']?.toString() ?? 'N/A',
        'icon': Icons.height,
      },
      {
        'label': 'Скорость',
        'value': droneStatus['speed']?.toString() ?? 'N/A',
        'icon': Icons.speed,
      },
      {
        'label': 'Температура',
        'value': droneStatus['temperature']?.toString() ?? 'N/A',
        'icon': Icons.thermostat,
      },
      {
        'label': 'GPS Широта',
        'value': droneStatus['gps_lat']?.toString() ?? 'N/A',
        'icon': Icons.location_on,
      },
      {
        'label': 'GPS Долгота',
        'value': droneStatus['gps_lon']?.toString() ?? 'N/A',
        'icon': Icons.location_on,
      },
    ];
    _statusController.add(statusItems);
  }

  void dispose() {
    _statusController.close();
  }
}

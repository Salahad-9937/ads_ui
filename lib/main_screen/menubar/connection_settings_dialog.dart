import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DroneConfig {
  final String name;
  final String ipAddress;
  final int port;
  final bool isVirtual;

  DroneConfig({
    required this.name,
    required this.ipAddress,
    this.port = 8765,
    required this.isVirtual,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'ipAddress': ipAddress,
    'port': port,
    'isVirtual': isVirtual,
  };

  factory DroneConfig.fromJson(Map<String, dynamic> json) => DroneConfig(
    name: json['name'],
    ipAddress: json['ipAddress'],
    port: json['port'] ?? 8765,
    isVirtual: json['isVirtual'],
  );
}

class ConnectionSettingsDialog extends StatefulWidget {
  const ConnectionSettingsDialog({super.key});

  @override
  ConnectionSettingsDialogState createState() =>
      ConnectionSettingsDialogState();
}

class ConnectionSettingsDialogState extends State<ConnectionSettingsDialog> {
  List<DroneConfig> drones = [];

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  Future<void> _loadDrones() async {
    final prefs = await SharedPreferences.getInstance();
    final droneList = prefs.getString('droneConfigs');
    if (droneList != null) {
      final List<dynamic> jsonList = json.decode(droneList);
      setState(() {
        drones = jsonList.map((json) => DroneConfig.fromJson(json)).toList();
      });
    } else {
      // Initialize with default localhost drone
      setState(() {
        drones = [
          DroneConfig(
            name: 'Default Drone',
            ipAddress: 'localhost',
            port: 8765,
            isVirtual: true,
          ),
        ];
      });
      _saveDrones();
    }
  }

  Future<void> _saveDrones() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = drones.map((drone) => drone.toJson()).toList();
    await prefs.setString('droneConfigs', json.encode(jsonList));
  }

  void _removeDrone(int index) {
    setState(() {
      drones.removeAt(index);
    });
    _saveDrones();
  }

  void _showDroneDialog({DroneConfig? drone, int? index}) {
    showDialog(
      context: context,
      builder:
          (context) => DroneConfigDialog(
            drone: drone,
            onSave: (config) {
              setState(() {
                if (index != null) {
                  drones[index] = config;
                } else {
                  drones.add(config);
                }
              });
              _saveDrones();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Настройки подключения'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showDroneDialog(),
            tooltip: 'Добавить дрон',
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Список дронов:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: drones.length,
                itemBuilder: (context, index) {
                  final drone = drones[index];
                  return ListTile(
                    title: Text(
                      '${drone.name} (${drone.ipAddress}:${drone.port}, ${drone.isVirtual ? 'Виртуальный' : 'Реальный'})',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed:
                              () =>
                                  _showDroneDialog(drone: drone, index: index),
                          tooltip: 'Редактировать',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeDrone(index),
                          tooltip: 'Удалить',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class DroneConfigDialog extends StatefulWidget {
  final DroneConfig? drone;
  final Function(DroneConfig) onSave;

  const DroneConfigDialog({super.key, this.drone, required this.onSave});

  @override
  DroneConfigDialogState createState() => DroneConfigDialogState();
}

class DroneConfigDialogState extends State<DroneConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _isVirtual = false;

  @override
  void initState() {
    super.initState();
    if (widget.drone != null) {
      _nameController.text = widget.drone!.name;
      _ipController.text = widget.drone!.ipAddress;
      _portController.text = widget.drone!.port.toString();
      _isVirtual = widget.drone!.isVirtual;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _saveDrone() {
    if (_formKey.currentState!.validate()) {
      final config = DroneConfig(
        name: _nameController.text,
        ipAddress: _ipController.text,
        port: int.tryParse(_portController.text) ?? 8765,
        isVirtual: _isVirtual,
      );
      widget.onSave(config);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.drone == null ? 'Добавить дрон' : 'Редактировать дрон',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Имя дрона'),
              validator: (value) => value!.isEmpty ? 'Введите имя дрона' : null,
            ),
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'IP-адрес'),
              validator: (value) {
                if (value!.isEmpty) return 'Введите IP-адрес или localhost';
                if (value != 'localhost') {
                  final ipRegExp = RegExp(
                    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
                  );
                  if (!ipRegExp.hasMatch(value)) return 'Неверный IP-адрес';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Порт (по умолчанию 8765)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isNotEmpty) {
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Неверный порт';
                  }
                }
                return null;
              },
            ),
            CheckboxListTile(
              title: const Text('Виртуальный дрон'),
              value: _isVirtual,
              onChanged: (value) {
                setState(() {
                  _isVirtual = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(onPressed: _saveDrone, child: const Text('Сохранить')),
      ],
    );
  }
}

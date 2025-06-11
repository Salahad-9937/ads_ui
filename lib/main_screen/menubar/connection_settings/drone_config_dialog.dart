import 'package:flutter/material.dart';
import 'drone_config.dart';

/// Диалоговое окно для добавления или редактирования конфигурации дрона.
///
/// [drone] - Конфигурация дрона для редактирования (опционально).
/// [onSave] - Callback для сохранения конфигурации.
class DroneConfigDialog extends StatefulWidget {
  final DroneConfig? drone;
  final Function(DroneConfig) onSave;

  const DroneConfigDialog({super.key, this.drone, required this.onSave});

  @override
  DroneConfigDialogState createState() => DroneConfigDialogState();
}

/// Состояние диалогового окна для управления конфигурацией дрона.
///
/// [_formKey] - Ключ формы для валидации.
/// [_nameController] - Контроллер для поля имени дрона.
/// [_ipController] - Контроллер для поля IP-адреса.
/// [_portController] - Контроллер для поля порта.
/// [_isVirtual] - Флаг, указывающий, является ли дрон виртуальным.
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

  /// Сохраняет конфигурацию дрона и закрывает диалоговое окно.
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

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
/// [_sshUsernameController] - Контроллер для поля имени пользователя SSH.
/// [_sshPasswordController] - Контроллер для поля пароля SSH.
/// [_isVirtual] - Флаг, указывающий, является ли дрон виртуальным.
class DroneConfigDialogState extends State<DroneConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _sshUsernameController = TextEditingController();
  final _sshPasswordController = TextEditingController();
  bool _isVirtual = false;

  @override
  void initState() {
    super.initState();
    if (widget.drone != null) {
      _nameController.text = widget.drone!.name;
      _ipController.text = widget.drone!.ipAddress;
      _portController.text = widget.drone!.port.toString();
      _isVirtual = widget.drone!.isVirtual;
      _sshUsernameController.text = widget.drone!.sshUsername;
      _sshPasswordController.text = widget.drone!.sshPassword;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _sshUsernameController.dispose();
    _sshPasswordController.dispose();
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
        sshUsername: _sshUsernameController.text,
        sshPassword: _sshPasswordController.text,
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
            TextFormField(
              controller: _sshUsernameController,
              decoration: const InputDecoration(
                labelText: 'Имя пользователя SSH',
              ),
              validator:
                  (value) =>
                      value!.isEmpty ? 'Введите имя пользователя SSH' : null,
            ),
            TextFormField(
              controller: _sshPasswordController,
              decoration: const InputDecoration(labelText: 'Пароль SSH'),
              obscureText: true,
              validator:
                  (value) => value!.isEmpty ? 'Введите пароль SSH' : null,
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

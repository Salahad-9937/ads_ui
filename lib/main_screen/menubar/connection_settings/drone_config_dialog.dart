import 'package:flutter/material.dart';
import '../../../domain/use_cases/create_drone_config_use_case.dart';
import '../../../domain/entities/drone_config.dart';

/// Диалоговое окно для добавления или редактирования конфигурации дрона.
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
  final _sshUsernameController = TextEditingController();
  final _sshPasswordController = TextEditingController();
  bool _isVirtual = false;
  String? _errorMessage;
  final _useCase = CreateDroneConfigUseCase();

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
      try {
        final config = _useCase.execute(
          name: _nameController.text,
          ipAddress: _ipController.text,
          port: _portController.text,
          isVirtual: _isVirtual,
          sshUsername: _sshUsernameController.text,
          sshPassword: _sshPasswordController.text,
        );
        widget.onSave(config);
        Navigator.of(context).pop();
      } on ValidationException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      }
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
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Имя дрона'),
            ),
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: 'IP-адрес'),
            ),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Порт (по умолчанию 8765)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: _sshUsernameController,
              decoration: const InputDecoration(
                labelText: 'Имя пользователя SSH',
              ),
            ),
            TextFormField(
              controller: _sshPasswordController,
              decoration: const InputDecoration(labelText: 'Пароль SSH'),
              obscureText: true,
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

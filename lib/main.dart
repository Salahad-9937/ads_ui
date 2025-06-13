// lib/main.dart
import 'package:flutter/material.dart';
import 'di.dart';
import 'main_screen/main_screen.dart';

void main() {
  setupDependencies(); // Инициализация DI
  runApp(const DroneControlApp());
}

class DroneControlApp extends StatelessWidget {
  const DroneControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const MainScreen(),
    );
  }
}

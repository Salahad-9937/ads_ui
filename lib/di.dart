// lib/di.dart
import 'package:get_it/get_it.dart';
import 'main_screen/menubar/connection_settings/drone_config_storage.dart';
import 'servises/websocket_service.dart';
import 'domain/use_cases/manage_websocket_use_case.dart';
import 'domain/use_cases/manage_drones_use_case.dart';
import 'main_screen/menubar/connection_settings/drone_manager.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Регистрация репозитория
  getIt.registerSingleton<DroneConfigStorage>(DroneConfigStorage());

  // Регистрация DroneManager (временно, пока не удалён)
  getIt.registerSingleton<DroneManager>(
    DroneManager(repository: getIt<DroneConfigStorage>()),
  );

  // Регистрация WebSocketService
  getIt.registerSingleton<WebSocketService>(
    WebSocketService(droneManager: getIt<DroneManager>()),
  );

  // Регистрация use case'ов
  getIt.registerSingleton<ManageWebSocketUseCase>(
    ManageWebSocketUseCase(webSocketService: getIt<WebSocketService>()),
  );
  getIt.registerSingleton<ManageDronesUseCase>(
    ManageDronesUseCase(getIt<DroneConfigStorage>()),
  );
}

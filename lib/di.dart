import 'package:get_it/get_it.dart';
import 'main_screen/menubar/connection_settings/drone_config_storage.dart';
import 'domain/repositories/drone_config_repository.dart';
import 'domain/use_cases/manage_drones_use_case.dart';
import 'main_screen/menubar/connection_settings/drone_manager.dart';
import 'servises/websocket_service.dart';
import 'domain/use_cases/manage_websocket_use_case.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  // Репозитории
  getIt.registerSingleton<DroneConfigRepository>(DroneConfigStorage());

  // Use cases
  getIt.registerSingleton<ManageDronesUseCase>(
    ManageDronesUseCase(getIt<DroneConfigRepository>()),
  );

  // Сервисы и менеджеры
  getIt.registerSingleton<DroneManager>(
    DroneManager(repository: getIt<DroneConfigRepository>()),
  );

  getIt.registerSingleton<WebSocketService>(
    WebSocketService(
      onStatusUpdate: (status) {},
      onImageUpdate: (image) {},
      onConnectionUpdate: (connected) {},
      onAutoReconnectUpdate: (enabled) {},
    ),
  );

  getIt.registerSingleton<ManageWebSocketUseCase>(
    ManageWebSocketUseCase(getIt<WebSocketService>(), getIt<DroneManager>()),
  );
}

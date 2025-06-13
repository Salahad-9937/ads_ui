import 'package:get_it/get_it.dart';
import 'main_screen/menubar/connection_settings/drone_config_storage.dart';
import 'servises/websocket_service.dart';
import 'domain/use_cases/manage_websocket_use_case.dart';
import 'domain/use_cases/manage_drones_use_case.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Регистрация репозитория
  getIt.registerSingleton<DroneConfigStorage>(DroneConfigStorage());

  // Регистрация use case'ов
  getIt.registerSingleton<ManageDronesUseCase>(
    ManageDronesUseCase(getIt<DroneConfigStorage>()),
  );

  // Регистрация WebSocketService
  getIt.registerSingleton<WebSocketService>(
    WebSocketService(dronesUseCase: getIt<ManageDronesUseCase>()),
  );

  // Регистрация ManageWebSocketUseCase
  getIt.registerSingleton<ManageWebSocketUseCase>(
    ManageWebSocketUseCase(webSocketService: getIt<WebSocketService>()),
  );
}

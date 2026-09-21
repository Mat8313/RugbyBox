import 'app/bootstrap.dart';
import 'core/config/app_config.dart';
import 'dev/screen_simulator.dart';

/// Point d'entrée de développement (PC).
void main() {
  bootstrap(
    const AppConfig(useMockData: true),
    wrap: (app) => ScreenSimulator(child: app),
  );
}

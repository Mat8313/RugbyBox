import 'app/bootstrap.dart';
import 'core/config/app_config.dart';

/// Point d'entrée de développement (PC). Le simulateur d'écran viendra ici.
void main() {
  bootstrap(const AppConfig(useMockData: true));
}

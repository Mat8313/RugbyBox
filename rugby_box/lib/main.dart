import 'app/bootstrap.dart';
import 'core/config/app_config.dart';

/// Point d'entrée de production (Raspberry Pi).
void main() {
  bootstrap(const AppConfig(useMockData: false));
}

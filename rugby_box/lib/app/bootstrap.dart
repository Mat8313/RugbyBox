import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../core/config/app_config.dart';
import '../core/data/data_providers.dart';
import '../core/data/espn/asset_espn_data_source.dart';
import '../core/data/espn/http_espn_data_source.dart';
import 'rugby_box_app.dart';

/// Assemble et démarre l'application. Appelé une seule fois, par un `main`.
void bootstrap(AppConfig config, {Widget Function(Widget app)? wrap}) {
  _listenToLogs();

  Widget app = const RugbyBoxApp();
  if (wrap != null) app = wrap(app);
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        // Fichiers embarqués pour développer hors ligne, sinon la vraie API.
        espnDataSourceProvider.overrideWithValue(
          config.useMockData
              ? AssetEspnDataSource(bundle: rootBundle)
              : HttpEspnDataSource(client: http.Client()),
        ),
      ],
      child: app,
    ),
  );
}

/// Le seul écouteur des logs : une ligne par entrée sur la sortie standard,
/// que systemd transmet à journald (`journalctl -u rugbybox`).
///
/// Pas d'heure dans la ligne : journald date déjà chaque ligne, et le Pi
/// peut avoir une heure fausse avant la synchro NTP.
void _listenToLogs() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final error = record.error == null ? '' : ' (${record.error})';
    // La sortie standard est justement la destination voulue.
    // ignore: avoid_print
    print('${record.level.name} ${record.loggerName}: ${record.message}$error');
  });
}

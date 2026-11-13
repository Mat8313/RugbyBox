import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/data/data_providers.dart';
import '../core/data/espn/asset_espn_data_source.dart';
import '../core/data/espn/http_espn_data_source.dart';
import 'rugby_box_app.dart';

/// Assemble et démarre l'application. Appelé une seule fois, par un `main`.
void bootstrap(AppConfig config, {Widget Function(Widget app)? wrap}) {
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

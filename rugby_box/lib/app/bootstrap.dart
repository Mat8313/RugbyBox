import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/data/data_providers.dart';
import '../core/data/espn/asset_espn_data_source.dart';
import 'rugby_box_app.dart';

/// Assemble et démarre l'application. Appelé une seule fois, par un `main`.
void bootstrap(AppConfig config, {Widget Function(Widget app)? wrap}) {
  Widget app = const RugbyBoxApp();
  if (wrap != null) app = wrap(app);
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        // Pas encore de source réseau : hors données fictives, l'écran
        // affiche l'erreur de `espnDataSourceProvider` non fourni.
        if (config.useMockData)
          espnDataSourceProvider.overrideWithValue(
            AssetEspnDataSource(bundle: rootBundle),
          ),
      ],
      child: app,
    ),
  );
}

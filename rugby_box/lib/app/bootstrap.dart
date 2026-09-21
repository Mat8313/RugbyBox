import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import 'rugby_box_app.dart';

/// Assemble et démarre l'application. Appelé une seule fois, par un `main`.
void bootstrap(AppConfig config) {
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const RugbyBoxApp(),
    ),
  );
}

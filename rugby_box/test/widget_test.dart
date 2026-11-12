import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/app/rugby_box_app.dart';
import 'package:rugby_box/core/config/app_config.dart';

void main() {
  testWidgets("L'app démarre et affiche l'écran d'accueil", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(useMockData: true),
          ),
        ],
        child: const RugbyBoxApp(),
      ),
    );

    expect(find.text('TOP 14'), findsOneWidget);
    expect(find.text('Données fictives'), findsOneWidget);
  });

  testWidgets("L'écran d'accueil tient dans l'écran du Pi", (tester) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(useMockData: true),
          ),
        ],
        child: const RugbyBoxApp(),
      ),
    );

    expect(find.text('TOP 14'), findsOneWidget);
  });
}

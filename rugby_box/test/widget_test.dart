import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/app/rugby_box_app.dart';
import 'package:rugby_box/core/config/app_config.dart';
import 'package:rugby_box/core/data/data_providers.dart';
import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/features/fixtures/presentation/matches_screen.dart';
import 'package:rugby_box/features/standings/presentation/standings_screen.dart';

import 'support/fixture_data_source.dart';
import 'support/memory_data_source.dart';

Future<void> _pumpApp(WidgetTester tester, {EspnDataSource? source}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(const AppConfig(useMockData: true)),
        if (source != null) espnDataSourceProvider.overrideWithValue(source),
      ],
      child: const RugbyBoxApp(),
    ),
  );
}

/// Une journée terminée (20/09) et le classement 2027, lus hors du temps
/// simulé des tests widget.
Future<MemoryDataSource> _realData(WidgetTester tester) async {
  const files = FixtureDataSource(
    scoreboardFile: 'scoreboard_top14_2026-09-20.json',
    standingsFile: 'standings_top14_2027.json',
  );
  return (await tester.runAsync(
    () async => MemoryDataSource(
      await files.fetchScoreboard('', DateTime(0)),
      await files.fetchStandings('', 0),
    ),
  ))!;
}

void main() {
  testWidgets("L'app démarre et affiche l'écran d'accueil", (tester) async {
    await _pumpApp(tester);

    expect(find.text('TOP 14'), findsOneWidget);
    expect(find.text('Données fictives'), findsOneWidget);
  });

  // Touch Display 2 (1280×720) en `devicePixelRatio` 1,5, dans les deux sens.
  // Un débordement ferait échouer le test.
  for (final (name, size) in [
    ('paysage', const Size(853, 480)),
    ('portrait', const Size(480, 853)),
  ]) {
    testWidgets("L'écran tient dans l'écran du Pi en $name", (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpApp(tester, source: await _realData(tester));
      await tester.pump();

      expect(find.byType(MatchTile), findsWidgets);
      // Les 14 lignes sont construites et visibles : pas de défilement.
      expect(find.byType(StandingTile).hitTestable(), findsNWidgets(14));
    });
  }
}

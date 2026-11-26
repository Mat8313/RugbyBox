import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/data_providers.dart';
import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/features/standings/presentation/standings_screen.dart';

import '../../../support/fixture_data_source.dart';
import '../../../support/memory_data_source.dart';

Future<void> _pumpScreen(WidgetTester tester, EspnDataSource source) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [espnDataSourceProvider.overrideWithValue(source)],
      child: const MaterialApp(home: Scaffold(body: StandingsScreen())),
    ),
  );
}

/// Le classement 2027 et un jour sans match, lus hors du temps simulé.
Future<MemoryDataSource> _realStandings(WidgetTester tester) async {
  final standings = await tester.runAsync(
    () => const FixtureDataSource(
      scoreboardFile: '',
      standingsFile: 'standings_top14_2027.json',
    ).fetchStandings('', 0),
  );
  return MemoryDataSource(
    EspnScoreboardDto.fromJson({'events': <Object>[]}),
    standings!,
  );
}

void main() {
  testWidgets('Affiche une roue pendant le chargement', (tester) async {
    await _pumpScreen(tester, const StuckDataSource());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Affiche les 14 équipes et la saison', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpScreen(tester, await _realStandings(tester));
    await tester.pump();

    expect(find.byType(StandingTile), findsNWidgets(14));
    expect(find.text('Saison 2026-27'), findsOneWidget);
    expect(find.text('RC Toulon'), findsOneWidget);
  });

  testWidgets('Promet un nouvel essai sur une panne prévue', (tester) async {
    await _pumpScreen(tester, StuckDataSource(Exception('réseau coupé')));
    await tester.pump();

    expect(find.textContaining('Nouvel essai'), findsOneWidget);
  });

  testWidgets('Ne promet rien sur un bug', (tester) async {
    await _pumpScreen(tester, StuckDataSource(StateError('bug')));
    await tester.pump();

    expect(find.textContaining('Nouvel essai'), findsNothing);
    expect(find.textContaining('Redémarrez'), findsOneWidget);
  });
}

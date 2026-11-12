import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/data_providers.dart';
import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/features/fixtures/presentation/matches_screen.dart';

import '../../../support/fixture_data_source.dart';

/// Source qui ne répond jamais (chargement infini) ou lève [error].
class const _StuckDataSource([final Object? error]) implements EspnDataSource {
  Future<Never> _answer() =>
      error == null ? Completer<Never>().future : Future.error(error!);

  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) =>
      _answer();

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) =>
      _answer();
}

/// Source qui rend des réponses déjà chargées en mémoire.
class const _MemoryDataSource(
  final EspnScoreboardDto scoreboard,
  final EspnStandingsDto standings,
) implements EspnDataSource {
  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) =>
      Future.value(scoreboard);

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) =>
      Future.value(standings);
}

Future<void> _pumpScreen(WidgetTester tester, EspnDataSource source) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [espnDataSourceProvider.overrideWithValue(source)],
      child: const MaterialApp(home: Scaffold(body: MatchesScreen())),
    ),
  );
}

void main() {
  testWidgets('Affiche une roue pendant le chargement', (tester) async {
    await _pumpScreen(tester, const _StuckDataSource());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Affiche les matchs une fois chargés', (tester) async {
    // Lecture disque hors du temps simulé des tests widget, puis source en
    // mémoire : le chargement ne dépend plus que de microtâches.
    const files = FixtureDataSource(
      scoreboardFile: 'scoreboard_top14_2026-09-20.json',
      standingsFile: 'standings_top14_2027.json',
    );
    final source = (await tester.runAsync(
      () async => _MemoryDataSource(
        await files.fetchScoreboard('', DateTime(0)),
        await files.fetchStandings('', 0),
      ),
    ))!;

    await _pumpScreen(tester, source);
    await tester.pump();

    expect(find.byType(MatchTile), findsWidgets);
  });

  testWidgets('Promet un nouvel essai sur une panne prévue', (tester) async {
    await _pumpScreen(tester, _StuckDataSource(Exception('réseau coupé')));
    await tester.pump();

    expect(find.textContaining('Nouvel essai'), findsOneWidget);
  });

  testWidgets('Ne promet rien sur un bug', (tester) async {
    await _pumpScreen(tester, _StuckDataSource(StateError('bug')));
    await tester.pump();

    expect(find.textContaining('Nouvel essai'), findsNothing);
    expect(find.textContaining('Redémarrez'), findsOneWidget);
  });
}

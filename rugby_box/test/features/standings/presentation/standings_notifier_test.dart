import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/data_providers.dart';
import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/domain/standing_row.dart';
import 'package:rugby_box/features/fixtures/presentation/matches_notifier.dart';
import 'package:rugby_box/features/standings/presentation/standings_notifier.dart';

import '../../../support/fixture_data_source.dart';

/// Fausse source dont on peut couper le scoreboard en cours de test.
class _SwitchableSource implements EspnDataSource {
  static const _fixtures = FixtureDataSource(
    scoreboardFile: 'scoreboard_top14_2026-09-20.json',
    standingsFile: 'standings_top14_2027.json',
  );

  bool scoreboardDown = false;

  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) {
    if (scoreboardDown) throw Exception('ESPN injoignable');
    return _fixtures.fetchScoreboard(leagueId, day);
  }

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) =>
      _fixtures.fetchStandings(leagueId, season);
}

void main() {
  late _SwitchableSource source;
  late ProviderContainer container;

  /// États successifs du classement, notés à partir du premier chargement.
  late List<AsyncValue<List<StandingRow>>> standingsStates;

  setUp(() async {
    source = _SwitchableSource();
    container = ProviderContainer.test(
      overrides: [espnDataSourceProvider.overrideWithValue(source)],
    );
    standingsStates = [];
    container.listen(standingsProvider, (_, next) => standingsStates.add(next));
    // Les matchs d'abord : sinon leur premier chargement relancerait le
    // classement pendant le test.
    await container.read(matchesProvider.future);
    await container.read(standingsProvider.future);
    standingsStates.clear();
  });

  /// Relance les matchs et attend qu'ils aient fini, puis que le classement
  /// ait réagi.
  Future<void> refreshMatches() async {
    container.invalidate(matchesProvider);
    // Pas de `matchesProvider.future` : en erreur, il attend le réessai, et
    // l'état reste un AsyncLoading qui porte l'erreur (retryMatches).
    bool settled(AsyncValue<Object?> state) =>
        !state.isLoading || state.hasError;
    while (!settled(container.read(matchesProvider))) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await container.read(standingsProvider.future);
  }

  /// Nombre de relectures du classement depuis le premier chargement.
  int standingsReloads() =>
      standingsStates.where((state) => state.isLoading).length;

  group('StandingsNotifier', () {
    test('rend les 14 lignes du classement, triées', () async {
      final rows = await container.read(standingsProvider.future);

      expect(rows.map((row) => row.rank), [for (var i = 1; i <= 14; i++) i]);
    });

    test('se relit quand les matchs ont une nouvelle valeur', () async {
      await refreshMatches();

      // Une seule fois : l'état intermédiaire du rafraîchissement des
      // matchs (AsyncData en chargement) ne compte pas.
      expect(standingsReloads(), 1);
      expect(container.read(standingsProvider).hasValue, isTrue);
    });

    test('ne bouge pas quand le scoreboard tombe en panne', () async {
      source.scoreboardDown = true;

      await refreshMatches();

      expect(container.read(matchesProvider).hasError, isTrue);
      expect(standingsReloads(), 0);
      expect(container.read(standingsProvider).value, hasLength(14));
    });
  });
}

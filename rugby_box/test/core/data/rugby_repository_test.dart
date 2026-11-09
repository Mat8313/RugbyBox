import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/rugby_data_source.dart';
import 'package:rugby_box/core/data/rugby_repository.dart';
import 'package:rugby_box/core/domain/competition.dart';

import '../../support/fixture_data_source.dart';
import '../../support/playlist_data_source.dart';

/// Espion : enveloppe une vraie fausse source, compte les appels au
/// classement, et peut simuler une panne d'ESPN sur le classement.
class SpySource({required final RugbyDataSource inner})
    implements RugbyDataSource {
  /// Nombre d'appels à [fetchStandings] reçus.
  int standingsCalls = 0;

  /// Si `true`, [fetchStandings] lève une erreur, comme un ESPN en panne.
  bool standingsDown = false;

  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) =>
      inner.fetchScoreboard(leagueId, day);

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) {
    standingsCalls++;
    if (standingsDown) throw Exception('ESPN injoignable');
    return inner.fetchStandings(leagueId, season);
  }
}

void main() {
  const top14 = Competition(
    id: '270559',
    name: 'Top 14',
    shortName: 'TOP14',
    format: Format.league,
  );

  // La journée du 26/09 : 7 événements chez ESPN, dont un fantôme.
  final day = DateTime.utc(2026, 9, 26);

  SpySource newSpy() => SpySource(
    inner: const FixtureDataSource(
      scoreboardFile: 'scoreboard_top14_2026-09-26.json',
      standingsFile: 'standings_top14_2027.json',
    ),
  );

  group('RugbyRepository', () {
    test('Rend les matchs de la journée, fantôme écarté', () async {
      final repository = RugbyRepository(
        dataSource: newSpy(),
        competition: top14,
      );

      final matches = await repository.fetchMatches(day);

      expect(matches.length, 6);
    });

    test('Ne redemande pas le classement quand il est en cache', () async {
      final spy = newSpy();
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await repository.fetchMatches(day);
      await repository.fetchMatches(day);

      expect(spy.standingsCalls, 1);
    });

    test('Sans cache et ESPN en panne, lève une erreur', () async {
      final spy = newSpy()..standingsDown = true;
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await expectLater(repository.fetchMatches(day), throwsStateError);
    });

    test('Redemande le classement quand un match se termine', () async {
      // Le soir du 26/09, relevé après relevé (voir le tableau des statuts).
      final spy = SpySource(
        inner: PlaylistDataSource(
          scoreboardFiles: [
            'live/scoreboard_top14_2026-09-26_18-25.json',
            'live/scoreboard_top14_2026-09-26_18-30.json',
            'live/scoreboard_top14_2026-09-26_18-35.json',
            'live/scoreboard_top14_2026-09-26_18-35.json',
          ],
          standingsFile: 'standings_top14_2027.json',
        ),
      );
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await repository.fetchMatches(day); // 18-25
      expect(spy.standingsCalls, 1);

      await repository.fetchMatches(day); // 18-30
      expect(spy.standingsCalls, 2);

      await repository.fetchMatches(day); // 18-35
      expect(spy.standingsCalls, 3);

      await repository.fetchMatches(day); // 18-35 encore
      expect(spy.standingsCalls, 3);
    });
  });
}

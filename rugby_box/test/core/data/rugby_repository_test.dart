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

  /// Saisons dont le classement n'est pas encore publié : [fetchStandings]
  /// lève une erreur pour elles.
  Set<int> unpublishedSeasons = {};

  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) =>
      inner.fetchScoreboard(leagueId, day);

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) {
    standingsCalls++;
    if (standingsDown) throw Exception('ESPN injoignable');
    if (unpublishedSeasons.contains(season)) {
      throw Exception('Classement $season pas encore publié');
    }
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

    test(
      'En août, se replie sur le classement de la saison précédente',
      () async {
        // Le 15/08/2027, on est en saison 2028, pas encore publiée.
        final spy = newSpy()..unpublishedSeasons = {2028};
        final repository = RugbyRepository(dataSource: spy, competition: top14);

        final matches = await repository.fetchMatches(
          DateTime.utc(2027, 8, 15),
        );

        expect(matches.length, 6);
        expect(repository.isUsingPreviousSeason, isTrue);
      },
    );

    test('Sans aucune des deux saisons, lève une erreur', () async {
      final spy = newSpy()..unpublishedSeasons = {2027, 2028};
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await expectLater(
        repository.fetchMatches(DateTime.utc(2027, 8, 15)),
        throwsStateError,
      );
    });

    test('Ne signale pas de repli en pleine saison', () async {
      final repository = RugbyRepository(
        dataSource: newSpy(),
        competition: top14,
      );

      await repository.fetchMatches(day);

      expect(repository.isUsingPreviousSeason, isFalse);
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

    test('Réessaie le classement après 1, 2, 5, 15 et 30 min', () async {
      // 18-25 puis 18-30 (transition), puis 18-30 en boucle : plus rien ne
      // finit, seuls les réessais peuvent redemander le classement.
      final spy = SpySource(
        inner: PlaylistDataSource(
          scoreboardFiles: [
            'live/scoreboard_top14_2026-09-26_18-25.json',
            ...List.filled(9, 'live/scoreboard_top14_2026-09-26_18-30.json'),
          ],
          standingsFile: 'standings_top14_2027.json',
        ),
      );
      var clock = DateTime.utc(2026, 9, 26, 16, 30); // 18 h 30 à Paris
      final repository = RugbyRepository(
        dataSource: spy,
        competition: top14,
        now: () => clock,
      );

      /// Avance l'horloge de [minutes], appelle le repository, et rend le
      /// nombre total d'appels au classement.
      Future<int> after(double minutes) async {
        clock = clock.add(Duration(seconds: (minutes * 60).round()));
        await repository.fetchMatches(day);
        return spy.standingsCalls;
      }

      expect(await after(0), 1); // 18-25 : premier classement
      expect(await after(0), 2); // 18-30 : transition, la série démarre
      expect(await after(0.5), 2); // +30 s : pas encore l'heure
      expect(await after(0.5), 3); // +1 min pile : réessai n° 1
      expect(await after(2), 4); // +2 min : réessai n° 2
      expect(await after(5), 5); // +5 min : réessai n° 3
      expect(await after(15), 6); // +15 min : réessai n° 4
      expect(await after(30), 7); // +30 min : réessai n° 5, série finie
      expect(await after(120), 7); // 2 h plus tard : plus rien
      expect(repository.lastSuccessUtc, clock);
    });
  });
}

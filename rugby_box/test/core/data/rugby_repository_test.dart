import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/rugby_repository.dart';
import 'package:rugby_box/core/domain/competition.dart';

import '../../support/fixture_data_source.dart';
import '../../support/playlist_data_source.dart';

/// Espion : enveloppe une fausse source, note les saisons demandées au
/// classement, et peut simuler des pannes d'ESPN.
class SpySource({required final EspnDataSource inner})
    implements EspnDataSource {
  /// Saisons demandées à [fetchStandings], dans l'ordre des appels.
  final List<int> standingsSeasons = [];
  int get standingsCalls => standingsSeasons.length;

  bool scoreboardDown = false;
  bool standingsDown = false;

  /// Si `true`, [fetchStandings] rend un classement lisible mais vide.
  bool standingsEmpty = false;

  /// Saisons pas encore publiées : [fetchStandings] échoue pour elles.
  Set<int> unpublishedSeasons = {};

  /// Si `true`, [fetchStandings] rend les lignes du dernier au premier.
  bool standingsReversed = false;

  /// Si `true`, [fetchStandings] ajoute une ligne sans stats, que le mapper
  /// doit écarter.
  bool standingsWithBrokenRow = false;

  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) {
    if (scoreboardDown) throw Exception('ESPN injoignable');
    return inner.fetchScoreboard(leagueId, day);
  }

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) async {
    standingsSeasons.add(season);
    if (standingsDown) throw Exception('ESPN injoignable');
    if (unpublishedSeasons.contains(season)) {
      throw Exception('Classement $season pas encore publié');
    }
    if (standingsEmpty) return const EspnStandingsDto(children: []);
    final standings = await inner.fetchStandings(leagueId, season);
    if (!standingsReversed && !standingsWithBrokenRow) return standings;
    return EspnStandingsDto(
      children: [
        for (final group in standings.children!)
          EspnStandingsGroupDto(
            standings: EspnStandingsTableDto(
              entries: [
                ...standingsReversed
                    ? group.standings!.entries!.reversed
                    : group.standings!.entries!,
                if (standingsWithBrokenRow)
                  const EspnStandingEntryDto(
                    team: EspnTeamDto(id: '999', displayName: 'Inconnu'),
                    stats: null,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

void main() {
  const top14 = Competition(
    id: '270559',
    name: 'Top 14',
    shortName: 'TOP14',
    format: CompetitionFormat.league,
  );

  // 26/09 : 7 événements chez ESPN, dont un fantôme.
  final day = DateTime.utc(2026, 9, 26);

  SpySource newSpy() => SpySource(
    inner: const FixtureDataSource(
      scoreboardFile: 'scoreboard_top14_2026-09-26.json',
      standingsFile: 'standings_top14_2027.json',
    ),
  );

  group('RugbyRepository', () {
    test("L'horloge par défaut est en UTC", () {
      // En heure locale, `parisDay` lirait les chiffres de l'heure de Paris
      // et ajouterait encore 1 ou 2 h : le jour basculerait trop tôt.
      final repository = RugbyRepository(
        dataSource: newSpy(),
        competition: top14,
      );

      expect(repository.now().isUtc, isTrue);
    });

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

      await expectLater(
        repository.fetchMatches(day),
        throwsA(isA<StandingsUnavailableException>()),
      );
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
        throwsA(isA<StandingsUnavailableException>()),
      );
    });

    test('Ne signale pas de repli en pleine saison', () async {
      final repository = RugbyRepository(
        dataSource: newSpy(),
        competition: top14,
      );
      // Avant tout appel : rien ne justifie d'annoncer un repli.
      expect(repository.isUsingPreviousSeason, isFalse);

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
            ...List.filled(12, 'live/scoreboard_top14_2026-09-26_18-30.json'),
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

      // Avance l'horloge, appelle, et rend le total d'appels au classement.
      Future<int> after(double minutes) async {
        clock = clock.add(Duration(seconds: (minutes * 60).round()));
        await repository.fetchMatches(day);
        return spy.standingsCalls;
      }

      // Chaque délai est vérifié des deux côtés : rien 30 s avant, un appel
      // pile à l'heure. Sans le « avant », un délai raccourci passerait.
      expect(await after(0), 1); // 18-25 : premier classement
      expect(await after(0), 2); // 18-30 : transition, la série démarre
      expect(await after(0.5), 2); // +30 s : pas encore l'heure
      expect(await after(0.5), 3); // +1 min pile : réessai n° 1
      expect(await after(1.5), 3); // +1 min 30 : pas encore
      expect(await after(0.5), 4); // +2 min : réessai n° 2
      expect(await after(4.5), 4);
      expect(await after(0.5), 5); // +5 min : réessai n° 3
      expect(await after(14.5), 5);
      expect(await after(0.5), 6); // +15 min : réessai n° 4
      expect(await after(29.5), 6);
      expect(await after(0.5), 7); // +30 min : réessai n° 5, série finie
      expect(await after(120), 7); // 2 h plus tard : plus rien
      expect(repository.lastSuccessUtc, clock);
    });

    test('Change de saison le 1er août', () async {
      final july = newSpy();
      await RugbyRepository(
        dataSource: july,
        competition: top14,
      ).fetchMatches(DateTime.utc(2027, 7, 31));

      final august = newSpy();
      await RugbyRepository(
        dataSource: august,
        competition: top14,
      ).fetchMatches(DateTime.utc(2027, 8));

      expect(july.standingsSeasons.first, 2027);
      expect(august.standingsSeasons.first, 2028);
    });

    test("Ne redemande une saison non publiée qu'après une heure", () async {
      final spy = newSpy()..unpublishedSeasons = {2028};
      var clock = DateTime.utc(2027, 8, 15, 12);
      final repository = RugbyRepository(
        dataSource: spy,
        competition: top14,
        now: () => clock,
      );
      final august = DateTime.utc(2027, 8, 15);

      await repository.fetchMatches(august);
      expect(spy.standingsSeasons, [2028, 2027]);

      clock = clock.add(const Duration(minutes: 30));
      await repository.fetchMatches(august);
      expect(spy.standingsSeasons, [2028, 2027]); // 2027 vient du cache

      // ESPN publie 2028 ; une heure plus tard, on la redemande.
      spy.unpublishedSeasons = {};
      clock = clock.add(const Duration(minutes: 30));
      await repository.fetchMatches(august);
      expect(spy.standingsSeasons, [2028, 2027, 2028]);
      expect(repository.isUsingPreviousSeason, isFalse);
    });

    test(
      'Une panne au démarrage ne passe pas pour une saison non publiée',
      () async {
        final spy = newSpy()..standingsDown = true;
        var clock = DateTime.utc(2026, 9, 26, 12);
        final repository = RugbyRepository(
          dataSource: spy,
          competition: top14,
          now: () => clock,
        );

        // ESPN injoignable : l'erreur parle bien de la saison demandée.
        await expectLater(
          repository.fetchMatches(day),
          throwsA(
            isA<StandingsUnavailableException>().having(
              (e) => e.season,
              'season',
              2027,
            ),
          ),
        );

        // 30 s plus tard, le réseau revient : on redemande tout de suite 2027.
        spy.standingsDown = false;
        clock = clock.add(const Duration(seconds: 30));
        await repository.fetchMatches(day);

        expect(spy.standingsSeasons, [2027, 2026, 2027]);
        expect(repository.isUsingPreviousSeason, isFalse);
      },
    );

    test('Le repli ne concerne que la saison du jour demandé', () async {
      final spy = newSpy()..unpublishedSeasons = {2028};
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await repository.fetchMatches(DateTime.utc(2027, 8, 15));
      expect(repository.isUsingPreviousSeason, isTrue);

      await repository.fetchMatches(DateTime.utc(2027, 6));
      expect(repository.isUsingPreviousSeason, isFalse);
    });

    test('Un classement vide ne remplace pas celui du cache', () async {
      final spy = SpySource(
        inner: PlaylistDataSource(
          scoreboardFiles: [
            'live/scoreboard_top14_2026-09-26_18-25.json',
            'live/scoreboard_top14_2026-09-26_18-30.json',
            'live/scoreboard_top14_2026-09-26_18-30.json',
          ],
          standingsFile: 'standings_top14_2027.json',
        ),
      );
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await repository.fetchMatches(day);
      spy.standingsEmpty = true;
      await repository.fetchMatches(day); // fin de match : classement vide

      // Avec un cache vidé, tous les matchs passeraient pour des fantômes.
      expect(await repository.fetchMatches(day), isNotEmpty);
    });

    test(
      "Un scoreboard en panne ne touche pas l'heure du dernier succès",
      () async {
        final spy = newSpy();
        var clock = DateTime.utc(2026, 9, 26, 12);
        final repository = RugbyRepository(
          dataSource: spy,
          competition: top14,
          now: () => clock,
        );
        await repository.fetchMatches(day);
        final success = clock;

        spy.scoreboardDown = true;
        clock = clock.add(const Duration(minutes: 1));
        await expectLater(repository.fetchMatches(day), throwsException);

        expect(repository.lastSuccessUtc, success);
      },
    );
  });

  group('RugbyRepository, journal', () {
    /// Écoute les logs pendant le test. `onRecord` est synchrone : chaque
    /// entrée est déjà dans la liste quand l'appel journalisé se termine.
    List<LogRecord> captureLogs() {
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      return records;
    }

    test('Note chaque match écarté en warning', () async {
      final logs = captureLogs();
      final repository = RugbyRepository(
        dataSource: newSpy(),
        competition: top14,
      );

      await repository.fetchMatches(day); // 26/09 : un fantôme

      final warning = logs.singleWhere((r) => r.level == Level.WARNING);
      expect(warning.loggerName, 'RugbyRepository');
      expect(warning.message, startsWith('match '));
      expect(warning.message, contains(' écarté : '));
      expect(warning.message, contains('fantôme'));
    });

    test("Ne note qu'une fois un rejet qui se répète", () async {
      // Pendant un match, fetchMatches tourne toutes les 30 s : sans
      // mémoire, le même fantôme donnerait 480 lignes en un après-midi.
      final logs = captureLogs();
      final repository = RugbyRepository(
        dataSource: newSpy(),
        competition: top14,
      );

      await repository.fetchMatches(day);
      await repository.fetchMatches(day);
      await repository.fetchMatches(day);

      expect(logs.where((r) => r.level == Level.WARNING).length, 1);
    });

    test('Note chaque club écarté du classement en warning', () async {
      final logs = captureLogs();
      final spy = newSpy()..standingsWithBrokenRow = true;
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      final rows = await repository.fetchStandings(day);

      expect(rows.length, 14);
      expect(
        logs.where((r) => r.level == Level.WARNING).map((r) => r.message),
        ['club du classement 999 écarté : stat rank absente ou illisible'],
      );
    });

    test('Note une panne rattrapée en info, avec son erreur', () async {
      final logs = captureLogs();
      final spy = newSpy()..standingsDown = true;
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await expectLater(repository.fetchStandings(day), throwsException);

      // 2027 échoue, puis le repli sur 2026 aussi : deux pannes notées.
      expect(logs.map((r) => r.level).toSet(), {Level.INFO});
      expect(logs.map((r) => r.message), [
        contains('Classement 2027 injoignable'),
        contains('Classement 2026 injoignable'),
      ]);
      expect(logs.first.error, isA<Exception>());
    });
  });

  group('RugbyRepository.fetchStandings', () {
    test('Rend les 14 lignes triées du 1er au dernier', () async {
      // ESPN rend ici le classement à l'envers : le tri doit le remettre.
      final spy = newSpy()..standingsReversed = true;
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      final rows = await repository.fetchStandings(day);

      expect(rows.map((row) => row.rank), [for (var i = 1; i <= 14; i++) i]);
      expect(rows.map((row) => row.season).toSet(), {2027});
    });

    test('Réutilise le classement déjà en cache', () async {
      final spy = newSpy();
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await repository.fetchMatches(day);
      await repository.fetchStandings(day);

      expect(spy.standingsCalls, 1);
    });

    test('En août, appelé en premier, étiquette les lignes avec la saison '
        'précédente', () async {
      // Le 20/08/2027 : saison 2028 pas publiée, repli sur 2027. Aucun
      // fetchMatches avant : le drapeau ne peut venir que de cet appel.
      final spy = newSpy()..unpublishedSeasons = {2028};
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      final rows = await repository.fetchStandings(DateTime.utc(2027, 8, 20));

      expect(rows.map((row) => row.season).toSet(), {2027});
      expect(repository.isUsingPreviousSeason, isTrue);
    });

    test('Sans aucun classement, lève une erreur', () async {
      final spy = newSpy()..standingsDown = true;
      final repository = RugbyRepository(dataSource: spy, competition: top14);

      await expectLater(
        repository.fetchStandings(day),
        throwsA(isA<StandingsUnavailableException>()),
      );
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/espn/espn_mapper.dart';
import 'package:rugby_box/core/domain/competition.dart';
import 'package:rugby_box/core/domain/match.dart';
import 'package:rugby_box/core/domain/team.dart';

void main() {
  group('mapEspnStatus', () {
    test('Un match reporté est reconnu comme tel (report en post)', () {
      const type = EspnTypeDto(
        name: 'STATUS_POSTPONED',
        state: 'post',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.postponed);
    });

    test('Un match annulé est reconnu comme tel', () {
      const type = EspnTypeDto(
        name: 'STATUS_CANCELED',
        state: 'post',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.canceled);
    });

    test('Un match prévu est reconnu comme tel', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'pre',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.planned);
    });

    test('Un match en cours est reconnu comme tel', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'in',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.inProgress);
    });

    test(
      'Un match passé et dit fini (completed: true) est reconnu comme tel',
      () {
        const type = EspnTypeDto(
          name: 'STATUS_UNKNOWN',
          state: 'post',
          completed: true,
        );

        expect(mapEspnStatus(type), MatchStatus.finished);
      },
    );

    test('Un match passé et dit non fini (completed: false) est rejeté', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'post',
        completed: false,
      );

      expect(mapEspnStatus(type), isNull);
    });

    test('Un match passé et fin inconnu (completed: null) est rejeté', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'post',
        completed: null,
      );

      expect(mapEspnStatus(type), isNull);
    });

    test('Un match avec des informations fausses sur son état est rejeté', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'xyz',
        completed: true,
      );

      expect(mapEspnStatus(type), isNull);
    });

    test('Un match sans information sur son état est rejeté', () {
      expect(mapEspnStatus(null), isNull);
    });
  });

  group('parseEspnScore', () {
    test('Un score positif est valide', () {
      expect(parseEspnScore('40'), 40);
    });

    test('Un score de 0 est valide', () {
      expect(parseEspnScore('0'), 0);
    });

    test('Un score null est non valide (null)', () {
      expect(parseEspnScore(null), isNull);
    });

    test('Un score negatif est non valide (null)', () {
      expect(parseEspnScore('-3'), isNull);
    });

    test('Un score hors format (abc) est non valide (null)', () {
      expect(parseEspnScore('abc'), isNull);
    });

    test('Un score vide est non valide (null)', () {
      expect(parseEspnScore(''), isNull);
    });
  });

  group('parseEspnDate', () {
    test('Une date ESPN avec Z est lue en UTC', () {
      final date = parseEspnDate('2026-09-20T19:05Z');

      expect(date, DateTime.utc(2026, 9, 20, 19, 5));
      expect(date!.isUtc, true);
    });

    test('Une date avec décalage est convertie en UTC', () {
      expect(
        parseEspnDate('2026-09-20T21:05+02:00'),
        DateTime.utc(2026, 9, 20, 19, 5),
      );
    });

    test('Une date sans fuseau est refusée', () {
      expect(parseEspnDate('2026-09-20T19:05'), isNull);
    });

    test('Une date illisible est refusée', () {
      expect(parseEspnDate('samedi soir'), isNull);
    });

    test('Une date absente est refusée', () {
      expect(parseEspnDate(null), isNull);
    });
  });

  group('findEspnSide', () {
    test(
      'Équipe qui reçoit est bien à domicile et est la première dans la liste',
      () {
        const competitor1 = EspnCompetitorDto(
          homeAway: 'home',
          score: '0',
          team: null,
        );
        const competitor2 = EspnCompetitorDto(
          homeAway: 'away',
          score: '0',
          team: null,
        );
        const competitors = [competitor1, competitor2];
        expect(findEspnSide(competitors, 'home'), competitor1);
      },
    );

    test(
      'Équipe qui reçoit est bien à domicile et est la deuxième dans la liste',
      () {
        const competitor1 = EspnCompetitorDto(
          homeAway: 'away',
          score: '0',
          team: null,
        );
        const competitor2 = EspnCompetitorDto(
          homeAway: 'home',
          score: '0',
          team: null,
        );
        const competitors = [competitor1, competitor2];
        expect(findEspnSide(competitors, 'home'), competitor2);
      },
    );

    test('Deux équipes avec le même rôle sont rejetées (null)', () {
      const competitor1 = EspnCompetitorDto(
        homeAway: 'away',
        score: '0',
        team: null,
      );
      const competitor2 = EspnCompetitorDto(
        homeAway: 'away',
        score: '0',
        team: null,
      );
      const competitors = [competitor1, competitor2];
      expect(findEspnSide(competitors, 'away'), isNull);
    });

    test('Une des deux équipe sans rôle rend le match rejeté (null)', () {
      const competitor1 = EspnCompetitorDto(
        homeAway: null,
        score: '0',
        team: null,
      );
      const competitor2 = EspnCompetitorDto(
        homeAway: 'away',
        score: '0',
        team: null,
      );
      const competitors = [competitor1, competitor2];
      expect(findEspnSide(competitors, 'home'), isNull);
    });

    test('Une liste de compétiteurs absente donne null', () {
      expect(findEspnSide(null, 'away'), isNull);
    });
  });

  group('mapEspnTeam', () {
    const names = {'25986': (name: 'RC Toulon', shortName: 'RCT')};

    test('Une équipe connue prend les noms de la table, pas ceux d’ESPN', () {
      const dto = EspnTeamDto(id: '25986', displayName: 'Toulon');

      expect(
        mapEspnTeam(dto, names),
        const Team(id: '25986', name: 'RC Toulon', shortName: 'RCT'),
      );
    });

    test('Une équipe inconnue se replie sur displayName', () {
      const dto = EspnTeamDto(id: '289337', displayName: 'Vannes');

      expect(
        mapEspnTeam(dto, names),
        const Team(id: '289337', name: 'Vannes', shortName: 'VAN'),
      );
    });

    test('Un nom de moins de 3 lettres donne un nom court sans planter', () {
      const dto = EspnTeamDto(id: '1', displayName: 'Xv');

      expect(mapEspnTeam(dto, names)?.shortName, 'XV');
    });

    test('Une équipe sans id est rejetée', () {
      const dto = EspnTeamDto(id: null, displayName: 'Toulon');

      expect(mapEspnTeam(dto, names), isNull);
    });

    test('Une équipe inconnue sans displayName est rejetée', () {
      const dto = EspnTeamDto(id: '289337', displayName: null);

      expect(mapEspnTeam(dto, names), isNull);
    });

    test('Une équipe inconnue au displayName vide est rejetée', () {
      const dto = EspnTeamDto(id: '289337', displayName: '');

      expect(mapEspnTeam(dto, names), isNull);
    });

    test('Une équipe connue sans displayName reste valide', () {
      const dto = EspnTeamDto(id: '25986', displayName: null);

      expect(mapEspnTeam(dto, names)?.name, 'RC Toulon');
    });

    test('Une équipe absente est rejetée', () {
      expect(mapEspnTeam(null, names), isNull);
    });
  });
  group('collectEspnTeamIds', () {
    test('Réunit les ids de tous les groupes (poules)', () {
      const standings = EspnStandingsDto(
        children: [
          EspnStandingsGroupDto(
            standings: EspnStandingsTableDto(
              entries: [
                EspnStandingEntryDto(
                  team: EspnTeamDto(id: '25986', displayName: 'Toulon'),
                ),
              ],
            ),
          ),
          EspnStandingsGroupDto(
            standings: EspnStandingsTableDto(
              entries: [
                EspnStandingEntryDto(
                  team: EspnTeamDto(id: '289337', displayName: 'Vannes'),
                ),
              ],
            ),
          ),
        ],
      );

      expect(collectEspnTeamIds(standings), {'25986', '289337'});
    });

    test('Ignore les lignes sans équipe ou sans id', () {
      const standings = EspnStandingsDto(
        children: [
          EspnStandingsGroupDto(
            standings: EspnStandingsTableDto(
              entries: [
                EspnStandingEntryDto(team: null),
                EspnStandingEntryDto(
                  team: EspnTeamDto(id: null, displayName: 'Sans id'),
                ),
                EspnStandingEntryDto(
                  team: EspnTeamDto(id: '25986', displayName: 'Toulon'),
                ),
              ],
            ),
          ),
          EspnStandingsGroupDto(standings: null),
        ],
      );

      expect(collectEspnTeamIds(standings), {'25986'});
    });

    test('Un classement absent donne un ensemble vide', () {
      expect(collectEspnTeamIds(null), isEmpty);
      expect(
        collectEspnTeamIds(const EspnStandingsDto(children: null)),
        isEmpty,
      );
    });
  });

  group('isEspnTeamInCompetition', () {
    const validTeamIds = {'25986', '289337'};

    test('Une équipe du classement est acceptée', () {
      const dto = EspnTeamDto(id: '25986', displayName: 'Toulon');

      expect(isEspnTeamInCompetition(dto, validTeamIds), isTrue);
    });

    test('Une équipe hors du classement est refusée, même au nom connu', () {
      const dto = EspnTeamDto(id: '126831', displayName: 'Bordeaux');

      expect(isEspnTeamInCompetition(dto, validTeamIds), isFalse);
    });

    test('Une équipe sans id, ou absente, est refusée', () {
      const dto = EspnTeamDto(id: null, displayName: 'Toulon');

      expect(isEspnTeamInCompetition(dto, validTeamIds), isFalse);
      expect(isEspnTeamInCompetition(null, validTeamIds), isFalse);
    });

    test('Sur les vraies réponses, seul le fantôme du 26/09 est arrêté', () {
      Map<String, dynamic> read(String name) =>
          jsonDecode(File('test/fixtures/espn/$name').readAsStringSync())
              as Map<String, dynamic>;

      final validIds = collectEspnTeamIds(
        EspnStandingsDto.fromJson(read('standings_top14_2027.json')),
      );
      final events = EspnScoreboardDto.fromJson(
        read('scoreboard_top14_2026-09-26.json'),
      ).events!;

      final refused = [
        for (final event in events)
          if (!event.competitions!.single.competitors!.every(
            (c) => isEspnTeamInCompetition(c.team, validIds),
          ))
            event.id,
      ];

      expect(validIds.length, 14);
      expect(refused, ['604853']);
    });
  });

  group('EspnMatchMapper sur les vraies réponses', () {
    Map<String, dynamic> read(String name) =>
        jsonDecode(File('test/fixtures/espn/$name').readAsStringSync())
            as Map<String, dynamic>;

    const top14 = Competition(
      id: '270559',
      name: 'Top 14',
      shortName: 'TOP14',
      format: CompetitionFormat.league,
    );

    // Le mapper tel que le repository le construira : classement d'abord.
    final mapper = EspnMatchMapper(
      competition: top14,
      teamNames: const {
        '143737': (name: 'Union Bordeaux-Bègles', shortName: 'UBB'),
      },
      validTeamIds: collectEspnTeamIds(
        EspnStandingsDto.fromJson(read('standings_top14_2027.json')),
      ),
    );

    test('Le 20/09 : UBB 40-10 Stade Français, match terminé', () {
      final result = mapper.mapScoreboard(
        EspnScoreboardDto.fromJson(read('scoreboard_top14_2026-09-20.json')),
      );

      expect(result.rejections, isEmpty);
      expect(result.matches, [
        Match(
          id: '604380',
          competition: top14,
          kickoffUtc: DateTime.utc(2026, 9, 20, 19, 5),
          status: MatchStatus.finished,
          // Dans la table : noms français.
          homeTeam: const Team(
            id: '143737',
            name: 'Union Bordeaux-Bègles',
            shortName: 'UBB',
          ),
          // Hors de la table : repli sur le `displayName` d'ESPN.
          awayTeam: const Team(
            id: '25921',
            name: 'Stade Francais Paris',
            shortName: 'STA',
          ),
          homeScore: 40,
          awayScore: 10,
        ),
      ]);
    });

    test('Le 26/09 : le fantôme est écarté, les 6 vrais matchs passent', () {
      final result = mapper.mapScoreboard(
        EspnScoreboardDto.fromJson(read('scoreboard_top14_2026-09-26.json')),
      );

      expect(result.rejections.length, 1);
      expect(result.rejections.single.eventId, '604853');
      expect(result.rejections.single.reason, contains('fantôme'));

      expect(result.matches.length, 6);

      final toulon = result.matches.singleWhere((m) => m.id == '604385');
      expect(toulon.status, MatchStatus.planned);
      expect(toulon.homeScore, isNull);
      expect(toulon.awayScore, isNull);
    });

    // Toulon - Vannes du 26/09, relevé pendant le match (heure de Paris).
    const snapshots = [
      (
        time: '16-40',
        status: MatchStatus.inProgress,
        phase: MatchPhase.firstHalf,
        home: 0,
        away: 0,
      ),
      (
        time: '17-30',
        status: MatchStatus.inProgress,
        phase: MatchPhase.halftime,
        home: 7,
        away: 10,
      ),
      (
        time: '17-45',
        status: MatchStatus.inProgress,
        phase: MatchPhase.secondHalf,
        home: 7,
        away: 10,
      ),
      (
        time: '18-30',
        status: MatchStatus.finished,
        phase: null,
        home: 28,
        away: 10,
      ),
    ];

    for (final snapshot in snapshots) {
      test('Toulon - Vannes à ${snapshot.time} : ${snapshot.status.name} '
          '${snapshot.home}-${snapshot.away}', () {
        final result = mapper.mapScoreboard(
          EspnScoreboardDto.fromJson(
            read('scoreboard_top14_2026-09-26_${snapshot.time}.json'),
          ),
        );

        expect(result.rejections, isEmpty);
        final match = result.matches.single;
        expect(match.status, snapshot.status);
        expect(match.homeScore, snapshot.home);
        expect(match.awayScore, snapshot.away);
        expect(match.phase, snapshot.phase);
      });
    }
  });
}

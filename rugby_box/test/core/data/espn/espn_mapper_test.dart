import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/espn/espn_mapper.dart';
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
}

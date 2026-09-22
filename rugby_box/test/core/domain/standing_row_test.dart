import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/domain/standing_row.dart';
import 'package:rugby_box/core/domain/team.dart';

/// Fabrique une ligne de classement de test.
///
/// Les paramètres nommés ont des valeurs par défaut : chaque test ne précise
/// que ce qui l'intéresse, ce qui rend son intention lisible.
StandingRow buildRow({
  int won = 0,
  int drawn = 0,
  int lost = 0,
  int pointsFor = 0,
  int pointsAgainst = 0,
  int points = 0,
}) {
  return StandingRow(
    team: const Team(id: 'rct', name: 'RC Toulon', shortName: 'TLN'),
    season: '2025-2026',
    rank: 1,
    won: won,
    drawn: drawn,
    lost: lost,
    pointsFor: pointsFor,
    pointsAgainst: pointsAgainst,
    tryBonus: 0,
    losingBonus: 0,
    points: points,
  );
}

void main() {
  group('StandingRow', () {
    test('played est la somme des victoires, nuls et défaites', () {
      final row = buildRow(won: 12, drawn: 1, lost: 3);

      expect(row.played, 16);
    });

    test("pointsDifference est négative quand l'équipe encaisse plus qu'elle ne marque", () {
      final row = buildRow(pointsAgainst: 27, pointsFor: 10);
      expect(row.pointsDifference, -17);
    });

    test('deux lignes aux mêmes valeurs sont égales', () {
      final toulon = buildRow(
        won: 2,
        drawn: 0,
        lost: 1,
        pointsFor: 10,
        pointsAgainst: 21,
      );
      final rct = buildRow(
        won: 2,
        drawn: 0,
        lost: 1,
        pointsFor: 10,
        pointsAgainst: 21,
      );

      expect(toulon, rct);
    });

    test('deux lignes qui diffèrent par un seul champ sont inégales', () {
      final toulon = buildRow(
        won: 2,
        drawn: 0,
        lost: 1,
        pointsFor: 10,
        pointsAgainst: 21,
      );
      final castres = buildRow(
        won: 3,
        drawn: 0,
        lost: 1,
        pointsFor: 10,
        pointsAgainst: 21,
      );

      expect(toulon, isNot(castres));
    });

    test("points est celui de la source, jamais recalculé", () {
      final row = buildRow(won: 5, lost: 2, points: 70);
      expect(row.points, 70);
    });
  });
}

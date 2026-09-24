import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/domain/match.dart';

void main() {
  group('MatchStatus.hasScore', () {
    test('Le statut de match fini doit avoir un score.', () {
      expect(MatchStatus.finished.hasScore, true);
    });

    test('Le statut de match en cours doit avoir un score.', () {
      expect(MatchStatus.inProgress.hasScore, true);
    });

    test('Le statut de match prévu ne doit pas avoir un score.', () {
      expect(MatchStatus.planned.hasScore, false);
    });

    test('Le statut de match décalé ne doit pas avoir un score.', () {
      expect(MatchStatus.postponed.hasScore, false);
    });

    test('Le statut de match annulé ne doit pas avoir un score.', () {
      // choix de simplicité pour la v1.0 au vu de la rareté du cas contraire.
      expect(MatchStatus.canceled.hasScore, false);
    });
  });
}

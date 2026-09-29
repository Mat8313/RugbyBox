import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';

/// Lit une vraie réponse d'ESPN enregistrée dans `test/fixtures/espn/`.
///
/// `flutter test` s'exécute depuis la racine du package : le chemin est
/// donc relatif à `rugby_box/`.
EspnScoreboardDto loadScoreboard(String fileName) {
  final text = File('test/fixtures/espn/$fileName').readAsStringSync();
  final json = jsonDecode(text) as Map<String, dynamic>;
  return EspnScoreboardDto.fromJson(json);
}

/// Lit un vrai classement d'ESPN enregistré dans `test/fixtures/espn/`.
EspnStandingsDto loadStandings(String fileName) {
  final text = File('test/fixtures/espn/$fileName').readAsStringSync();
  final json = jsonDecode(text) as Map<String, dynamic>;
  return EspnStandingsDto.fromJson(json);
}

void main() {
  group('EspnScoreboardDto sur une vraie réponse', () {
    test('lit un match terminé : UBB 40-10 Stade Français', () {
      final scoreboard = loadScoreboard('scoreboard_top14_2026-09-20.json');
      final event = scoreboard.events!.single;
      final competitors = event.competitions!.single.competitors!;

      final ubb = competitors[0];
      final stf = competitors[1];

      expect(ubb.homeAway, "home");
      expect(stf.homeAway, "away");
      expect(ubb.team!.id, '143737');
      expect(stf.team!.id, '25921');
      expect(ubb.score, "40");
      expect(stf.score, "10");
      expect(ubb.team!.displayName, "Bordeaux Begles");
      expect(stf.team!.displayName, "Stade Francais Paris");
      expect(event.id, "604380");
      expect(event.date, "2026-09-20T19:05Z");
      expect(event.status!.type!.state, "post");
      expect(event.status!.type!.name, "STATUS_FINAL");
      expect(event.status!.type!.completed, true);
    });

    test('lit la journée du 26/09, match fantôme compris', () {
      final scoreboard = loadScoreboard('scoreboard_top14_2026-09-26.json');

      final match = scoreboard.events!.firstWhere((e) => e.id == "604385");
      final rct = match.competitions![0].competitors![0];
      final vannes = match.competitions![0].competitors![1];

      expect(scoreboard.events!.length, 7);
      expect(rct.homeAway, "home");
      expect(vannes.homeAway, "away");
      expect(rct.team!.displayName, "Toulon");
      expect(vannes.team!.displayName, "Vannes");
      expect(rct.team!.id, "25986");
      expect(vannes.team!.id, "289337");
      expect(rct.score, "0");
      expect(vannes.score, "0");
    });
  });
  group('EspnStandingsDto sur une vraie réponse', () {
    test('lit le classement du Top 14 (saison 2027) : 14 clubs', () {
      final standings = loadStandings('standings_top14_2027.json');
      final entries = standings.children!.single.standings!.entries!;

      expect(entries.length, 14);

      final toulon = entries.firstWhere((e) => e.team?.id == '25986');
      expect(toulon.team!.displayName, 'Toulon');
    });
  });
}

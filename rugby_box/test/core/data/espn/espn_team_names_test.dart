import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/espn/espn_mapper.dart';
import 'package:rugby_box/core/data/espn/espn_team_names.dart';

void main() {
  group('espnTeamNames', () {
    test('Couvre les 14 clubs du classement du Top 14 (saison 2027)', () {
      final standings = EspnStandingsDto.fromJson(
        jsonDecode(
          File('test/fixtures/espn/standings_top14_2027.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
      );

      final missing = collectEspnTeamIds(standings)
          .difference(espnTeamNames.keys.toSet());

      expect(missing, isEmpty);
    });

    test('Aucun sigle en doublon', () {
      final shortNames = [
        for (final names in espnTeamNames.values) names.shortName,
      ];

      expect(shortNames.toSet().length, shortNames.length);
    });
  });
}

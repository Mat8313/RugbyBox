import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/espn_data_source.dart';

import 'fixture_data_source.dart';

void main() {
  // Typée par le contrat, comme le repository la voit.
  const EspnDataSource source = FixtureDataSource(
    scoreboardFile: 'scoreboard_top14_2026-09-20.json',
    standingsFile: 'standings_top14_2027.json',
  );

  test('renvoie le scoreboard du fichier choisi', () async {
    final scoreboard = await source.fetchScoreboard(
      '270559',
      DateTime.utc(2026, 9, 20),
    );

    expect(scoreboard.events, isNotEmpty);
  });

  test('renvoie le classement du fichier choisi', () async {
    final standings = await source.fetchStandings('270559', 2027);

    expect(standings.children, isNotEmpty);
  });
}

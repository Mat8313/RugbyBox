import 'dart:convert';
import 'dart:io';

import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';

/// Lit une réponse ESPN enregistrée dans `test/fixtures/espn/`.
Future<Map<String, dynamic>> readEspnFixture(String file) async {
  final text = await File('test/fixtures/espn/$file').readAsString();
  return jsonDecode(text) as Map<String, dynamic>;
}

/// Fausse source qui rend toujours les mêmes fichiers, quels que soient la
/// ligue et le jour demandés.
class const FixtureDataSource({
  required final String scoreboardFile,
  required final String standingsFile,
}) implements EspnDataSource {
  @override
  Future<EspnScoreboardDto> fetchScoreboard(
    String leagueId,
    DateTime day,
  ) async => EspnScoreboardDto.fromJson(await readEspnFixture(scoreboardFile));

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) async =>
      EspnStandingsDto.fromJson(await readEspnFixture(standingsFile));
}

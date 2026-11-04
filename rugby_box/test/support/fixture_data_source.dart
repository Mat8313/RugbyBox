import 'dart:convert';
import 'dart:io';

import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/rugby_data_source.dart';

/// Fausse source qui lit de vraies réponses d'ESPN enregistrées dans
/// `test/fixtures/espn/`, au lieu d'appeler le réseau.
///
/// Elle ignore la compétition et la date demandées : chaque test choisit les
/// fichiers qu'elle renvoie.
class const FixtureDataSource({
  /// Fichier renvoyé par [fetchScoreboard], par exemple
  /// `scoreboard_top14_2026-09-20.json`.
  required final String scoreboardFile,

  /// Fichier renvoyé par [fetchStandings], par exemple
  /// `standings_top14_2027.json`.
  required final String standingsFile,
}) implements RugbyDataSource {
  @override
  Future<EspnScoreboardDto> fetchScoreboard(
    String leagueId,
    DateTime day,
  ) async {
    final text = await File('test/fixtures/espn/$scoreboardFile')
        .readAsString();
    final json = jsonDecode(text) as Map<String, dynamic>;
    return EspnScoreboardDto.fromJson(json);
  }

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) async {
    final text = await File('test/fixtures/espn/$standingsFile').readAsString();
    final json = jsonDecode(text) as Map<String, dynamic>;
    return EspnStandingsDto.fromJson(json);
  }
}

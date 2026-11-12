import 'dart:convert';

import 'package:flutter/services.dart';

import 'espn_data_source.dart';
import 'espn_dtos.dart';

/// Source fictive : rend des réponses ESPN enregistrées, embarquées dans
/// l'app (`assets/mock/espn/`), quels que soient la ligue et le jour.
///
/// Sert au mode « données fictives » (`AppConfig.useMockData`), pour
/// développer sans réseau et toujours avec les mêmes matchs.
class const AssetEspnDataSource({
  /// D'où lire les fichiers : `rootBundle` dans l'app.
  required final AssetBundle bundle,
}) implements EspnDataSource {
  static const _folder = 'assets/mock/espn';
  static const _scoreboardFile = 'scoreboard_top14_2026-09-26.json';
  static const _standingsFile = 'standings_top14_2027.json';

  @override
  Future<EspnScoreboardDto> fetchScoreboard(
    String leagueId,
    DateTime day,
  ) async => EspnScoreboardDto.fromJson(await _readJson(_scoreboardFile));

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) async =>
      EspnStandingsDto.fromJson(await _readJson(_standingsFile));

  /// Lit le fichier [file] de [_folder] et le décode en JSON.
  Future<Map<String, dynamic>> _readJson(String file) async {
    final text = await bundle.loadString('$_folder/$file');
    return jsonDecode(text) as Map<String, dynamic>;
  }
}

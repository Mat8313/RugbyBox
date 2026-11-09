import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/rugby_data_source.dart';

import 'fixture_data_source.dart';

/// Fausse source qui rend un scoreboard différent à chaque appel, dans
/// l'ordre de [scoreboardFiles], comme une playlist. Sert à rejouer un match
/// relevé après relevé (par exemple `18-25`, puis `18-30`, puis `18-35`).
///
/// Pas `const` : elle retient sa position dans la playlist, donc elle change
/// d'un appel à l'autre.
class PlaylistDataSource({
  /// Fichiers renvoyés par [fetchScoreboard], un par appel, dans l'ordre.
  /// Chemins relatifs à `test/fixtures/espn/`, par exemple
  /// `live/scoreboard_top14_2026-09-26_18-25.json`.
  required final List<String> scoreboardFiles,

  /// Fichier renvoyé par [fetchStandings], toujours le même.
  required final String standingsFile,
}) implements RugbyDataSource {
  /// Rang, dans [scoreboardFiles], du fichier à lire au prochain appel.
  int _next = 0;

  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) {
    if (_next >= scoreboardFiles.length) {
      throw StateError('Playlist épuisée (${scoreboardFiles.length} fichiers)');
    }

    final file = scoreboardFiles[_next];
    _next += 1;

    return FixtureDataSource(
      scoreboardFile: file,
      standingsFile: standingsFile,
    ).fetchScoreboard(leagueId, day);
  }

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) =>
      FixtureDataSource(
        scoreboardFile: scoreboardFiles.first,
        standingsFile: standingsFile,
      ).fetchStandings(leagueId, season);
}

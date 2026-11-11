import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';

import 'fixture_data_source.dart';

/// Fausse source qui rend un scoreboard différent à chaque appel, dans
/// l'ordre de [scoreboardFiles] : sert à rejouer un match relevé après
/// relevé.
class PlaylistDataSource({
  required final List<String> scoreboardFiles,
  required final String standingsFile,
}) implements EspnDataSource {
  int _next = 0;

  @override
  Future<EspnScoreboardDto> fetchScoreboard(
    String leagueId,
    DateTime day,
  ) async {
    if (_next >= scoreboardFiles.length) {
      throw StateError('Playlist épuisée (${scoreboardFiles.length} fichiers)');
    }
    final file = scoreboardFiles[_next++];
    return EspnScoreboardDto.fromJson(await readEspnFixture(file));
  }

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) async =>
      EspnStandingsDto.fromJson(await readEspnFixture(standingsFile));
}

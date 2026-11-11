import 'espn_dtos.dart';

/// Va chercher les réponses brutes d'ESPN, sans les traduire ni les garder.
///
/// En cas d'échec (réseau, JSON illisible), lève une [Exception], jamais une
/// `Error` : le repository ne rattrape que les exceptions.
abstract interface class EspnDataSource {
  /// Les matchs de la ligue [leagueId] (`270559` = Top 14) le jour [day].
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day);

  /// Le classement de la ligue [leagueId] pour [season], désignée par son
  /// année de fin (`2027` pour 2026-27).
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season);
}

import 'espn/espn_dtos.dart';

/// Contrat d'une source de données rugby : va chercher les réponses brutes
/// d'ESPN, sans les traduire ni les garder en mémoire.
///
/// Deux implémentations prévues : la vraie (réseau) et une fausse (fixtures),
/// interchangeables aux yeux du repository.
abstract interface class RugbyDataSource {
  /// Les matchs de la compétition [leagueId] (`270559` pour le Top 14) pour
  /// la journée [day] (`.../scoreboard?dates=AAAAMMJJ`).
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day);

  /// Le classement de la compétition [leagueId] pour la saison [season]
  /// (`.../standings?season=AAAA`), désignée par son année de fin : `2027`
  /// pour 2026-27.
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season);
}

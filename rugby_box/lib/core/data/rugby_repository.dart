import '../domain/competition.dart';
import '../domain/match.dart';
import 'espn/espn_dtos.dart';
import 'espn/espn_mapper.dart';
import 'espn/espn_team_names.dart';
import 'rugby_data_source.dart';

/// Décide quoi demander à la source, traduit avec le mapper, et se souvient
/// du dernier classement valide.
class RugbyRepository({
  /// Où aller chercher les DTO (réseau ou fixtures).
  required final RugbyDataSource dataSource,

  /// La compétition suivie par ce repository.
  required final Competition competition,
}) {
  /// Dernier classement valide, une case par saison (clé : année de fin,
  /// `2027` pour 2026-27).
  final Map<int, EspnStandingsDto> _standingsBySeason = {};

  /// Heure UTC du dernier appel réussi, `null` tant qu'aucun n'a réussi.
  DateTime? _lastSuccessUtc;

  /// Heure UTC du dernier appel réussi, en lecture seule (pour afficher
  /// « Mis à jour il y a X min »). `null` tant qu'aucun n'a réussi.
  DateTime? get lastSuccessUtc => _lastSuccessUtc;

  /// Va chercher le classement de [season] et le range dans le casier s'il
  /// est valide. En cas d'échec, rend l'ancien ; sans ancien, lève une erreur.
  Future<EspnStandingsDto> _refreshStandings(int season) async {
    try {
      final fresh = await dataSource.fetchStandings(competition.id, season);
      if (collectEspnTeamIds(fresh).isNotEmpty) {
        _standingsBySeason[season] = fresh;
        return fresh;
      }
    } catch (_) {
      // Panne réseau ou JSON illisible : on passe au plan B ci-dessous.
    }

    // Plan B : l'ancien classement de cette saison, s'il existe.
    final cached = _standingsBySeason[season];
    if (cached != null) return cached;
    throw StateError('Classement $season indisponible, et aucun en cache');
  }

  /// Les matchs de la compétition pour la journée [day].
  ///
  /// Lève une erreur si le scoreboard est inaccessible, ou si aucun
  /// classement n'a jamais pu être obtenu pour cette saison.
  Future<List<Match>> fetchMatches(DateTime day) async {
    final season = _seasonOf(day);

    // ② le classement : celui du casier s'il existe, sinon on va le chercher.
    final standings =
        _standingsBySeason[season] ?? await _refreshStandings(season);

    final mapper = EspnMatchMapper(
      competition: competition,
      teamNames: espnTeamNames,
      validTeamIds: collectEspnTeamIds(standings),
    );

    final scoreboard = await dataSource.fetchScoreboard(competition.id, day);
    final result = mapper.mapScoreboard(scoreboard);

    // Arrivé ici, rien n'a levé d'erreur : l'appel a réussi.
    _lastSuccessUtc = DateTime.now().toUtc();
    return result.matches;
  }

  /// Saison ESPN de [day], désignée par son année de fin. Une saison va
  /// d'août à juin : le 20/09/2026 → `2027`, le 15/03/2027 → `2027`.
  int _seasonOf(DateTime day) => day.month >= 8 ? day.year + 1 : day.year; // ①
}

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

  /// L'horloge, en UTC. Par défaut l'heure réelle ; un test passe la sienne
  /// pour faire avancer le temps sans attendre.
  final DateTime Function() now = _systemNowUtc,
}) {
  /// Délais entre deux réessais du classement après une fin de match :
  /// ESPN ne le met pas forcément à jour tout de suite.
  static const retryDelays = [
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  /// Rang, dans [retryDelays], du prochain réessai.
  int _retryIndex = 0;

  /// Heure UTC du prochain réessai, `null` si aucune série n'est en cours.
  DateTime? _nextRetryUtc;

  /// Démarre (ou redémarre) une série de réessais à partir de [nowUtc].
  void _startRetries(DateTime nowUtc) {
    _retryIndex = 0;
    _nextRetryUtc = nowUtc.add(retryDelays[0]);
  }

  /// Dernier classement valide, une case par saison (clé : année de fin,
  /// `2027` pour 2026-27).
  final Map<int, EspnStandingsDto> _standingsBySeason = {};

  /// Heure UTC du dernier appel réussi, `null` tant qu'aucun n'a réussi.
  DateTime? _lastSuccessUtc;

  /// Heure UTC du dernier appel réussi, en lecture seule (pour afficher
  /// « Mis à jour il y a X min »). `null` tant qu'aucun n'a réussi.
  DateTime? get lastSuccessUtc => _lastSuccessUtc;

  /// Statut de chaque match (clé : `Match.id`) vu au dernier appel.
  final Map<String, MatchStatus> _lastStatusById = {};

  /// Vrai si au moins un match de [matches] était `inProgress` au dernier
  /// appel et est `finished` maintenant. Met la mémoire à jour au passage.
  bool _detectNewlyFinished(List<Match> matches) {
    var newlyFinished = false;
    for (final match in matches) {
      final MatchStatus? before = _lastStatusById[match.id];
      if (before == MatchStatus.inProgress &&
          match.status == MatchStatus.finished) {
        newlyFinished = true;
      }
      _lastStatusById[match.id] = match.status;
    }
    return newlyFinished;
  }

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

  /// Vrai si le dernier classement utilisé est celui de la saison
  /// précédente, faute de mieux (typiquement en août, avant qu'ESPN publie
  /// le nouveau). L'UI peut le signaler.
  bool get isUsingPreviousSeason => _isUsingPreviousSeason;
  bool _isUsingPreviousSeason = false;

  /// Comme [_refreshStandings], mais se replie sur la saison précédente si
  /// [season] n'a encore aucun classement. Lève une erreur si aucune des
  /// deux n'est disponible.
  Future<EspnStandingsDto> _standingsWithFallback(int season) async {
    try {
      // ① Le classement de la saison demandée (frais ou du casier).
      final standings = await _refreshStandings(season);
      _isUsingPreviousSeason = false;
      return standings;
    } on StateError {
      // ② Rien pour cette saison : celle d'avant, du casier sinon d'ESPN.
      // Si elle manque aussi, la StateError remonte toute seule.
      final previous =
          _standingsBySeason[season - 1] ?? await _refreshStandings(season - 1);
      _isUsingPreviousSeason = true;
      return previous;
    }
  }

  /// Les matchs de la compétition pour la journée [day].
  ///
  /// Lève une erreur si le scoreboard est inaccessible, ou si aucun
  /// classement n'a jamais pu être obtenu pour cette saison.
  Future<List<Match>> fetchMatches(DateTime day) async {
    final season = _seasonOf(day);
    final nowUtc = now(); // une seule lecture de l'horloge par appel

    // ② le classement : celui du casier s'il existe, sinon on va le chercher.
    final standings =
        _standingsBySeason[season] ?? await _standingsWithFallback(season);

    final mapper = EspnMatchMapper(
      competition: competition,
      teamNames: espnTeamNames,
      validTeamIds: collectEspnTeamIds(standings),
    );

    final scoreboard = await dataSource.fetchScoreboard(competition.id, day);
    final result = mapper.mapScoreboard(scoreboard);

    // ③ un match vient de finir : le classement a changé, on le redemande.
    if (_detectNewlyFinished(result.matches)) {
      await _standingsWithFallback(season);
      _startRetries(nowUtc);
    } else {
      // ④ sinon, un réessai de la série en cours est peut-être dû.
      await _retryIfDue(season, nowUtc);
    }

    // Arrivé ici, rien n'a levé d'erreur : l'appel a réussi.
    _lastSuccessUtc = nowUtc;
    return result.matches;
  }

  /// Si une série de réessais est en cours et que son heure est passée,
  /// redemande le classement de [season] et programme le réessai suivant
  /// (ou termine la série s'il n'y a plus de délai).
  Future<void> _retryIfDue(int season, DateTime nowUtc) async {
    // ① Pas de série en cours, ou pas encore l'heure : rien à faire.
    final next = _nextRetryUtc;
    if (next == null || nowUtc.isBefore(next)) return;

    // ② C'est l'heure : on redemande.
    await _standingsWithFallback(season);

    // ③ On avance dans la liste, puis on programme le suivant ou on arrête.
    _retryIndex++;
    _nextRetryUtc = _retryIndex < retryDelays.length
        ? nowUtc.add(retryDelays[_retryIndex])
        : null;
  }

  /// Saison ESPN de [day], désignée par son année de fin. Une saison va
  /// d'août à juin : le 20/09/2026 → `2027`, le 15/03/2027 → `2027`.
  int _seasonOf(DateTime day) => day.month >= 8 ? day.year + 1 : day.year; // ①
}

/// Horloge par défaut de [RugbyRepository] : l'heure réelle, en UTC.
DateTime _systemNowUtc() => DateTime.now().toUtc();

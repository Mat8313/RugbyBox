import '../domain/competition.dart';
import '../domain/match.dart';
import 'espn/espn_data_source.dart';
import 'espn/espn_dtos.dart';
import 'espn/espn_mapper.dart';
import 'espn/espn_team_names.dart';
import 'retry_schedule.dart';

/// Aucun classement disponible pour [season], ni frais ni en cache.
///
/// Situation prévue (ESPN en panne, saison pas encore publiée) : l'appelant
/// réessaie plus tard.
class const StandingsUnavailableException(final int season)
    implements Exception {
  @override
  String toString() => 'Classement $season indisponible, et aucun en cache';
}

/// Décide quoi demander à ESPN, traduit avec le mapper, et se souvient du
/// dernier classement valide de chaque saison.
class RugbyRepository({
  required final EspnDataSource dataSource,
  required final Competition competition,

  /// Horloge UTC, remplaçable dans les tests.
  final DateTime Function() now = _systemNowUtc,
}) {
  /// Délais entre deux réessais du classement après une fin de match :
  /// ESPN ne le met pas toujours à jour tout de suite.
  static const retryDelays = [
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  /// Délai avant de redemander une saison qu'ESPN n'a pas encore publiée.
  static const unpublishedSeasonDelay = Duration(hours: 1);

  /// Dernier classement valide, par saison (année de fin).
  final Map<int, EspnStandingsDto> _standingsBySeason = {};

  /// Saisons introuvables chez ESPN, et heure à partir de laquelle on peut
  /// les redemander.
  final Map<int, DateTime> _unpublishedUntilUtc = {};

  /// Statut de chaque match (par `Match.id`) au dernier appel.
  final Map<String, MatchStatus> _lastStatusById = {};

  final RetrySchedule _retries = RetrySchedule(retryDelays);

  DateTime? _lastSuccessUtc;
  bool _isUsingPreviousSeason = false;

  /// Heure UTC du dernier appel réussi (« Mis à jour il y a X min »).
  DateTime? get lastSuccessUtc => _lastSuccessUtc;

  /// Vrai si le dernier appel a dû se contenter du classement de la saison
  /// précédente (en août, avant qu'ESPN publie le nouveau).
  bool get isUsingPreviousSeason => _isUsingPreviousSeason;

  /// Les matchs de la compétition pour la journée [day].
  ///
  /// Lève une [StandingsUnavailableException] si aucun classement n'est
  /// disponible, ou l'exception de la source si le scoreboard est inaccessible.
  Future<List<Match>> fetchMatches(DateTime day) async {
    final season = _seasonOf(day);
    final nowUtc = now(); // une seule lecture par appel : heures cohérentes

    final standings =
        _standingsBySeason[season] ??
        await _standingsWithFallback(season, nowUtc);

    final mapper = EspnMatchMapper(
      competition: competition,
      teamNames: espnTeamNames,
      validTeamIds: collectEspnTeamIds(standings),
    );
    final scoreboard = await dataSource.fetchScoreboard(competition.id, day);
    final result = mapper.mapScoreboard(scoreboard);

    // Un match vient de finir : le classement a changé.
    if (_detectNewlyFinished(result.matches)) {
      await _standingsWithFallback(season, nowUtc);
      _retries.start(nowUtc);
    } else if (_retries.isDue(nowUtc)) {
      await _standingsWithFallback(season, nowUtc);
      _retries.advance(nowUtc);
    }

    _isUsingPreviousSeason = !_standingsBySeason.containsKey(season);
    _lastSuccessUtc = nowUtc;
    return result.matches;
  }

  /// Saison ESPN de [day], désignée par son année de fin : une saison va
  /// d'août à juin.
  int _seasonOf(DateTime day) => day.month >= 8 ? day.year + 1 : day.year;

  /// Vrai si un match de [matches] est passé de `inProgress` à `finished`
  /// depuis le dernier appel. Met la mémoire à jour au passage.
  bool _detectNewlyFinished(List<Match> matches) {
    var newlyFinished = false;
    for (final match in matches) {
      final before = _lastStatusById[match.id];
      if (before == MatchStatus.inProgress &&
          match.status == MatchStatus.finished) {
        newlyFinished = true;
      }
      _lastStatusById[match.id] = match.status;
    }
    return newlyFinished;
  }

  /// Le classement de [season], sinon celui de la saison précédente.
  ///
  /// Une saison introuvable n'est redemandée qu'après
  /// [unpublishedSeasonDelay], pour ne pas solliciter ESPN pour rien.
  Future<EspnStandingsDto> _standingsWithFallback(
    int season,
    DateTime nowUtc,
  ) async {
    final until = _unpublishedUntilUtc[season];
    final mayAsk = until == null || !nowUtc.isBefore(until);
    if (mayAsk) {
      try {
        final standings = await _refreshStandings(season);
        _unpublishedUntilUtc.remove(season);
        return standings;
      } on StandingsUnavailableException {
        // Saison pas publiée, ou panne : on ne le sait pas encore.
      }
    }

    final EspnStandingsDto previous;
    try {
      previous =
          _standingsBySeason[season - 1] ?? await _refreshStandings(season - 1);
    } on StandingsUnavailableException {
      // Les deux manquent : sans doute une panne, on ne marque rien.
      throw StandingsUnavailableException(season);
    }

    // La saison précédente a répondu : ESPN est joignable, la nouvelle
    // manque vraiment.
    if (mayAsk) {
      _unpublishedUntilUtc[season] = nowUtc.add(unpublishedSeasonDelay);
    }
    return previous;
  }

  /// Redemande le classement de [season] et le garde s'il est valide. En
  /// cas d'échec, rend l'ancien ; sans ancien, lève une
  /// [StandingsUnavailableException].
  Future<EspnStandingsDto> _refreshStandings(int season) async {
    try {
      final fresh = await dataSource.fetchStandings(competition.id, season);
      if (collectEspnTeamIds(fresh).isNotEmpty) {
        _standingsBySeason[season] = fresh;
        return fresh;
      }
    } on Exception {
      // Panne prévue (réseau, JSON illisible) : on se rabat sur le cache.
    }

    return _standingsBySeason[season] ??
        (throw StandingsUnavailableException(season));
  }
}

DateTime _systemNowUtc() => DateTime.now().toUtc();

import 'dart:async';

import 'package:rugby_box/core/data/espn/espn_data_source.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';

/// Source qui ne répond jamais (chargement infini) ou lève [error].
class const StuckDataSource([final Object? error]) implements EspnDataSource {
  Future<Never> _answer() =>
      error == null ? Completer<Never>().future : Future.error(error!);

  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) =>
      _answer();

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) =>
      _answer();
}

/// Source qui rend des réponses déjà chargées en mémoire : dans un test
/// widget, le chargement ne dépend plus que de microtâches.
class const MemoryDataSource(
  final EspnScoreboardDto scoreboard,
  final EspnStandingsDto standings,
) implements EspnDataSource {
  @override
  Future<EspnScoreboardDto> fetchScoreboard(String leagueId, DateTime day) =>
      Future.value(scoreboard);

  @override
  Future<EspnStandingsDto> fetchStandings(String leagueId, int season) =>
      Future.value(standings);
}

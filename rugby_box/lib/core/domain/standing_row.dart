import 'package:freezed_annotation/freezed_annotation.dart';

import 'team.dart';

part 'standing_row.freezed.dart';

/// Une ligne du classement d'une compétition, pour une équipe et une saison.
@freezed
class const StandingRow({
  required final Team team,

  /// Saison, désignée par son année de fin (`2027` pour 2026-27).
  required final int season,

  /// Place au classement, 1 = premier.
  required final int rank,
  required final int won,
  required final int drawn,
  required final int lost,

  /// Points marqués et encaissés sur la saison.
  required final int pointsFor,
  required final int pointsAgainst,

  /// Bonus offensifs cumulés : 1 point par match où l'équipe inscrit au
  /// moins 3 essais de plus que son adversaire, quel que soit le résultat.
  required final int tryBonus,

  /// Bonus défensifs cumulés : 1 point par match perdu de 5 points ou moins.
  required final int losingBonus,

  /// Total au classement, tel que la source le donne (peut inclure une
  /// pénalité administrative : ne jamais le recalculer).
  required final int points,
}) with _$StandingRow {
  int get played => won + drawn + lost;

  /// Positive pour une équipe qui marque plus qu'elle n'encaisse.
  int get pointsDifference => pointsFor - pointsAgainst;
}

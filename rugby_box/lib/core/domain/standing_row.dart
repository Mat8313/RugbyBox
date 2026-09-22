import 'package:freezed_annotation/freezed_annotation.dart';

import 'team.dart';

part 'standing_row.freezed.dart';

/// Une ligne du classement d'une compétition, pour une équipe et une saison.
///
/// Objet du domaine : du Dart pur, immuable, sans Flutter, ni HTTP, ni JSON.
@freezed
class const StandingRow({
  /// Équipe concernée par cette ligne.
  required final Team team,

  /// Saison, au format de la source (ex. `'2025-2026'`).
  required final String season,

  /// Place au classement, 1 = premier.
  required final int rank,

  /// Nombre de victoires
  required final int won,

  /// Nombre de matchs nuls
  required final int drawn,

  /// Nombre de défaites
  required final int lost,

  /// Points marqués par l'équipe sur la saison.
  required final int pointsFor,

  /// Points encaissés par l'équipe sur la saison.
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
  /// Nombre de matchs joués
  int get played => won + drawn + lost;

  /// Différence de points : positive pour une équipe qui domine.
  int get pointsDifference => pointsFor - pointsAgainst;
}

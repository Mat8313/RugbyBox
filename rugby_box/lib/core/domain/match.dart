import 'package:freezed_annotation/freezed_annotation.dart';

import 'competition.dart';
import 'team.dart';

part 'match.freezed.dart';

/// Où en est un match dans son déroulement.
enum MatchStatus { planned, inProgress, finished, postponed, canceled }

/// Un match entre deux équipes, dans une compétition donnée.
///
/// Objet du domaine : du Dart pur, immuable, sans Flutter, ni HTTP, ni JSON.
@freezed
class const Match({
  /// Identifiant stable venant de la source de données.
  required final String id,

  /// Compétition dans laquelle ce match est joué.
  required final Competition competition,

  /// Coup d'envoi, **toujours en UTC**. Converti en heure de Paris à l'affichage.
  required final DateTime kickoffUtc,

  /// État du match (prévu, en cours, terminé, reporté ou annulé).
  required final MatchStatus status,

  /// Équipe qui reçoit.
  required final Team homeTeam,

  /// Équipe qui se déplace.
  required final Team awayTeam,

  /// Score de l'équipe qui reçoit. `null` tant que le match n'a pas commencé.
  final int? homeScore,

  /// Score de l'équipe qui se déplace. `null` tant que le match n'a pas commencé.
  final int? awayScore,
}) with _$Match;

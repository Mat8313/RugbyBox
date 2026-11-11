import 'package:freezed_annotation/freezed_annotation.dart';

import 'competition.dart';
import 'team.dart';

part 'match.freezed.dart';

/// Où en est un match dans son déroulement.
enum MatchStatus {
  planned,
  inProgress,
  finished,
  postponed,
  canceled;

  /// Vrai si un match dans ce statut doit avoir un score.
  bool get hasScore => switch (this) {
    planned => false,
    inProgress => true,
    finished => true,
    postponed => false,
    canceled => false,
  };
}

/// Moment d'un match en direct qui précise [MatchStatus.inProgress].
enum MatchPhase { firstHalf, halftime, secondHalf }

/// Un match entre deux équipes, dans une compétition donnée.
@freezed
class const Match({
  /// Id ESPN du match.
  required final String id,
  required final Competition competition,

  /// Coup d'envoi, **toujours en UTC** : converti en heure de Paris à
  /// l'affichage.
  required final DateTime kickoffUtc,
  required final MatchStatus status,
  required final Team homeTeam,
  required final Team awayTeam,

  /// Scores : renseignés si et seulement si [MatchStatus.hasScore].
  final int? homeScore,
  final int? awayScore,

  /// Moment du direct, `null` hors d'un match en cours (ou si ESPN ne le
  /// précise pas).
  final MatchPhase? phase,
}) with _$Match;

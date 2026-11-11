import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition.freezed.dart';

/// Forme d'une compétition : un seul classement, ou des poules.
enum CompetitionFormat { league, pools }

/// Une compétition suivie par le boîtier (Top 14, Champions Cup…).
@freezed
class const Competition({
  /// Id ESPN de la ligue (`270559` pour le Top 14).
  required final String id,

  /// Nom complet (« Top 14 »).
  required final String name,

  /// Nom court, pour les bandeaux (« TOP14 »).
  required final String shortName,

  required final CompetitionFormat format,
}) with _$Competition;

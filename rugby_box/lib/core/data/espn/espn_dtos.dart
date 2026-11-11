import 'package:json_annotation/json_annotation.dart';

part 'espn_dtos.g.dart';

// Miroir fidèle du JSON d'ESPN. Tous les champs sont nullables : une clé
// peut disparaître du jour au lendemain. Aucune règle métier ici.

// --- Scoreboard (`scoreboard?dates=AAAAMMJJ`) ---

/// Les matchs de la période demandée.
@JsonSerializable(createToJson: false)
class const EspnScoreboardDto({required final List<EspnEventDto>? events}) {
  factory EspnScoreboardDto.fromJson(Map<String, dynamic> json) =>
      _$EspnScoreboardDtoFromJson(json);
}

/// Un match (`events[]`).
@JsonSerializable(createToJson: false)
class const EspnEventDto({
  required final String? id,
  required final String? date,
  required final EspnStatusDto? status,
  required final List<EspnCompetitionDto>? competitions,
}) {
  factory EspnEventDto.fromJson(Map<String, dynamic> json) =>
      _$EspnEventDtoFromJson(json);
}

/// Le détail du statut (`status.type`).
@JsonSerializable(createToJson: false)
class const EspnTypeDto({
  required final String? name,
  required final String? state,

  /// Gardé car `state: 'post'` ne garantit pas un match allé à son terme :
  /// seul `completed: true` permet de le déclarer terminé.
  required final bool? completed,
}) {
  factory EspnTypeDto.fromJson(Map<String, dynamic> json) =>
      _$EspnTypeDtoFromJson(json);
}

/// Le statut d'un match (`events[].status`).
@JsonSerializable(createToJson: false)
class const EspnStatusDto({required final EspnTypeDto? type}) {
  factory EspnStatusDto.fromJson(Map<String, dynamic> json) =>
      _$EspnStatusDtoFromJson(json);
}

/// La rencontre elle-même (`events[].competitions[]`).
@JsonSerializable(createToJson: false)
class const EspnCompetitionDto({
  required final List<EspnCompetitorDto>? competitors,
}) {
  factory EspnCompetitionDto.fromJson(Map<String, dynamic> json) =>
      _$EspnCompetitionDtoFromJson(json);
}

/// Une équipe (`competitors[].team`, `entries[].team`).
@JsonSerializable(createToJson: false)
class const EspnTeamDto({
  required final String? id,
  required final String? displayName,
}) {
  factory EspnTeamDto.fromJson(Map<String, dynamic> json) =>
      _$EspnTeamDtoFromJson(json);
}

/// Un des deux camps d'un match (`competitions[].competitors[]`).
@JsonSerializable(createToJson: false)
class const EspnCompetitorDto({
  required final String? homeAway,
  required final String? score,
  required final EspnTeamDto? team,
}) {
  factory EspnCompetitorDto.fromJson(Map<String, dynamic> json) =>
      _$EspnCompetitorDtoFromJson(json);
}

// --- Classement (`standings?season=AAAA`) ---
// Réponse → groupes → tableau → lignes → équipe. Les `stats` des lignes
// viendront avec l'écran du classement.

/// La réponse du classement.
@JsonSerializable(createToJson: false)
class const EspnStandingsDto({
  required final List<EspnStandingsGroupDto>? children,
}) {
  factory EspnStandingsDto.fromJson(Map<String, dynamic> json) =>
      _$EspnStandingsDtoFromJson(json);
}

/// Un groupe du classement (`children[]`) : le Top 14 entier, ou une poule.
@JsonSerializable(createToJson: false)
class const EspnStandingsGroupDto({
  required final EspnStandingsTableDto? standings,
}) {
  factory EspnStandingsGroupDto.fromJson(Map<String, dynamic> json) =>
      _$EspnStandingsGroupDtoFromJson(json);
}

/// Le tableau d'un groupe (`children[].standings`).
@JsonSerializable(createToJson: false)
class const EspnStandingsTableDto({
  required final List<EspnStandingEntryDto>? entries,
}) {
  factory EspnStandingsTableDto.fromJson(Map<String, dynamic> json) =>
      _$EspnStandingsTableDtoFromJson(json);
}

/// Une ligne du tableau (`standings.entries[]`) : une équipe.
@JsonSerializable(createToJson: false)
class const EspnStandingEntryDto({required final EspnTeamDto? team}) {
  factory EspnStandingEntryDto.fromJson(Map<String, dynamic> json) =>
      _$EspnStandingEntryDtoFromJson(json);
}

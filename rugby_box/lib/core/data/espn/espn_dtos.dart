import 'package:json_annotation/json_annotation.dart';

part 'espn_dtos.g.dart';

// DTO : miroir fidèle du JSON d'ESPN, défauts compris.
// Tous les champs sont nullables : une clé peut manquer du jour au lendemain.
// Aucune règle métier ici ; les conversions vont dans le mapper.

/// Les matchs de la période demandée comme l'ESPN la décrit.
@JsonSerializable(createToJson: false)
class const EspnScoreboardDto({required final List<EspnEventDto>? events}) {
  factory EspnScoreboardDto.fromJson(Map<String, dynamic> json) =>
      _$EspnScoreboardDtoFromJson(json);
}

/// Un match tel que l'ESPN le décrit.
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

/// Le type de statut du match selon l'ESPN
@JsonSerializable(createToJson: false)
class const EspnTypeDto({
  required final String? name,
  required final String? state,
  required final bool? completed,
}) {
  factory EspnTypeDto.fromJson(Map<String, dynamic> json) =>
      _$EspnTypeDtoFromJson(json);
}

/// Le statut du match selon l'ESPN
@JsonSerializable(createToJson: false)
class const EspnStatusDto({required final EspnTypeDto? type}) {
  factory EspnStatusDto.fromJson(Map<String, dynamic> json) =>
      _$EspnStatusDtoFromJson(json);
}

/// La competition selon l'ESPN
@JsonSerializable(createToJson: false)
class const EspnCompetitionDto({
  required final List<EspnCompetitorDto>? competitors,
}) {
  factory EspnCompetitionDto.fromJson(Map<String, dynamic> json) =>
      _$EspnCompetitionDtoFromJson(json);
}

/// Une équipe telle qu'ESPN la décrit (`competitors[].team`).
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

// Du plus haut au plus bas : réponse → groupes → tableau → lignes → équipe.
// Les `stats` de chaque ligne seront ajoutées avec l'écran du classement.

/// La réponse du classement d'une compétition, telle qu'ESPN la décrit.
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

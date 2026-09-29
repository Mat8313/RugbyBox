// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'espn_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EspnScoreboardDto _$EspnScoreboardDtoFromJson(Map<String, dynamic> json) =>
    EspnScoreboardDto(
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => EspnEventDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

EspnEventDto _$EspnEventDtoFromJson(Map<String, dynamic> json) => EspnEventDto(
  id: json['id'] as String?,
  date: json['date'] as String?,
  status: json['status'] == null
      ? null
      : EspnStatusDto.fromJson(json['status'] as Map<String, dynamic>),
  competitions: (json['competitions'] as List<dynamic>?)
      ?.map((e) => EspnCompetitionDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

EspnTypeDto _$EspnTypeDtoFromJson(Map<String, dynamic> json) => EspnTypeDto(
  name: json['name'] as String?,
  state: json['state'] as String?,
  completed: json['completed'] as bool?,
);

EspnStatusDto _$EspnStatusDtoFromJson(Map<String, dynamic> json) =>
    EspnStatusDto(
      type: json['type'] == null
          ? null
          : EspnTypeDto.fromJson(json['type'] as Map<String, dynamic>),
    );

EspnCompetitionDto _$EspnCompetitionDtoFromJson(Map<String, dynamic> json) =>
    EspnCompetitionDto(
      competitors: (json['competitors'] as List<dynamic>?)
          ?.map((e) => EspnCompetitorDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

EspnTeamDto _$EspnTeamDtoFromJson(Map<String, dynamic> json) => EspnTeamDto(
  id: json['id'] as String?,
  displayName: json['displayName'] as String?,
);

EspnCompetitorDto _$EspnCompetitorDtoFromJson(Map<String, dynamic> json) =>
    EspnCompetitorDto(
      homeAway: json['homeAway'] as String?,
      score: json['score'] as String?,
      team: json['team'] == null
          ? null
          : EspnTeamDto.fromJson(json['team'] as Map<String, dynamic>),
    );

EspnStandingsDto _$EspnStandingsDtoFromJson(Map<String, dynamic> json) =>
    EspnStandingsDto(
      children: (json['children'] as List<dynamic>?)
          ?.map(
            (e) => EspnStandingsGroupDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

EspnStandingsGroupDto _$EspnStandingsGroupDtoFromJson(
  Map<String, dynamic> json,
) => EspnStandingsGroupDto(
  standings: json['standings'] == null
      ? null
      : EspnStandingsTableDto.fromJson(
          json['standings'] as Map<String, dynamic>,
        ),
);

EspnStandingsTableDto _$EspnStandingsTableDtoFromJson(
  Map<String, dynamic> json,
) => EspnStandingsTableDto(
  entries: (json['entries'] as List<dynamic>?)
      ?.map((e) => EspnStandingEntryDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

EspnStandingEntryDto _$EspnStandingEntryDtoFromJson(
  Map<String, dynamic> json,
) => EspnStandingEntryDto(
  team: json['team'] == null
      ? null
      : EspnTeamDto.fromJson(json['team'] as Map<String, dynamic>),
);

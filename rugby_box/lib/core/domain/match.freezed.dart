// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Match {


/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchCopyWith<Match> get copyWith => _$MatchCopyWithImpl<Match>(this as Match, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Match;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Match&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.competition, _this.competition) || other.competition == _this.competition)&&(identical(other.kickoffUtc, _this.kickoffUtc) || other.kickoffUtc == _this.kickoffUtc)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.homeTeam, _this.homeTeam) || other.homeTeam == _this.homeTeam)&&(identical(other.awayTeam, _this.awayTeam) || other.awayTeam == _this.awayTeam)&&(identical(other.homeScore, _this.homeScore) || other.homeScore == _this.homeScore)&&(identical(other.awayScore, _this.awayScore) || other.awayScore == _this.awayScore));
}


@override
int get hashCode {
  final _this = this as Match;
  return Object.hash(runtimeType,_this.id,_this.competition,_this.kickoffUtc,_this.status,_this.homeTeam,_this.awayTeam,_this.homeScore,_this.awayScore);
}

@override
String toString() {
  final _this = this as Match;
  return 'Match(id: ${_this.id}, competition: ${_this.competition}, kickoffUtc: ${_this.kickoffUtc}, status: ${_this.status}, homeTeam: ${_this.homeTeam}, awayTeam: ${_this.awayTeam}, homeScore: ${_this.homeScore}, awayScore: ${_this.awayScore})';
}


}

/// @nodoc
abstract mixin class $MatchCopyWith<$Res>  {
  factory $MatchCopyWith(Match value, $Res Function(Match) _then) = _$MatchCopyWithImpl;
@useResult
$Res call({
 String id, Competition competition, DateTime kickoffUtc, MatchStatus status, Team homeTeam, Team awayTeam, int? homeScore, int? awayScore
});


$CompetitionCopyWith<$Res> get competition;$TeamCopyWith<$Res> get homeTeam;$TeamCopyWith<$Res> get awayTeam;

}
/// @nodoc
class _$MatchCopyWithImpl<$Res>
    implements $MatchCopyWith<$Res> {
  _$MatchCopyWithImpl(this._self, this._then);

  final Match _self;
  final $Res Function(Match) _then;

/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? competition = null,Object? kickoffUtc = null,Object? status = null,Object? homeTeam = null,Object? awayTeam = null,Object? homeScore = freezed,Object? awayScore = freezed,}) {
  return _then(Match(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,competition: null == competition ? _self.competition : competition // ignore: cast_nullable_to_non_nullable
as Competition,kickoffUtc: null == kickoffUtc ? _self.kickoffUtc : kickoffUtc // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MatchStatus,homeTeam: null == homeTeam ? _self.homeTeam : homeTeam // ignore: cast_nullable_to_non_nullable
as Team,awayTeam: null == awayTeam ? _self.awayTeam : awayTeam // ignore: cast_nullable_to_non_nullable
as Team,homeScore: freezed == homeScore ? _self.homeScore : homeScore // ignore: cast_nullable_to_non_nullable
as int?,awayScore: freezed == awayScore ? _self.awayScore : awayScore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompetitionCopyWith<$Res> get competition {
  
  return $CompetitionCopyWith<$Res>(_self.competition, (value) {
    return _then(_self.copyWith(competition: value));
  });
}/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamCopyWith<$Res> get homeTeam {
  
  return $TeamCopyWith<$Res>(_self.homeTeam, (value) {
    return _then(_self.copyWith(homeTeam: value));
  });
}/// Create a copy of Match
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamCopyWith<$Res> get awayTeam {
  
  return $TeamCopyWith<$Res>(_self.awayTeam, (value) {
    return _then(_self.copyWith(awayTeam: value));
  });
}
}



// dart format on

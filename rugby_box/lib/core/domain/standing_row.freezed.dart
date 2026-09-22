// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'standing_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StandingRow {


/// Create a copy of StandingRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StandingRowCopyWith<StandingRow> get copyWith => _$StandingRowCopyWithImpl<StandingRow>(this as StandingRow, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StandingRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StandingRow&&(identical(other.team, _this.team) || other.team == _this.team)&&(identical(other.season, _this.season) || other.season == _this.season)&&(identical(other.rank, _this.rank) || other.rank == _this.rank)&&(identical(other.won, _this.won) || other.won == _this.won)&&(identical(other.drawn, _this.drawn) || other.drawn == _this.drawn)&&(identical(other.lost, _this.lost) || other.lost == _this.lost)&&(identical(other.pointsFor, _this.pointsFor) || other.pointsFor == _this.pointsFor)&&(identical(other.pointsAgainst, _this.pointsAgainst) || other.pointsAgainst == _this.pointsAgainst)&&(identical(other.tryBonus, _this.tryBonus) || other.tryBonus == _this.tryBonus)&&(identical(other.losingBonus, _this.losingBonus) || other.losingBonus == _this.losingBonus)&&(identical(other.points, _this.points) || other.points == _this.points));
}


@override
int get hashCode {
  final _this = this as StandingRow;
  return Object.hash(runtimeType,_this.team,_this.season,_this.rank,_this.won,_this.drawn,_this.lost,_this.pointsFor,_this.pointsAgainst,_this.tryBonus,_this.losingBonus,_this.points);
}

@override
String toString() {
  final _this = this as StandingRow;
  return 'StandingRow(team: ${_this.team}, season: ${_this.season}, rank: ${_this.rank}, won: ${_this.won}, drawn: ${_this.drawn}, lost: ${_this.lost}, pointsFor: ${_this.pointsFor}, pointsAgainst: ${_this.pointsAgainst}, tryBonus: ${_this.tryBonus}, losingBonus: ${_this.losingBonus}, points: ${_this.points})';
}


}

/// @nodoc
abstract mixin class $StandingRowCopyWith<$Res>  {
  factory $StandingRowCopyWith(StandingRow value, $Res Function(StandingRow) _then) = _$StandingRowCopyWithImpl;
@useResult
$Res call({
 Team team, String season, int rank, int won, int drawn, int lost, int pointsFor, int pointsAgainst, int tryBonus, int losingBonus, int points
});


$TeamCopyWith<$Res> get team;

}
/// @nodoc
class _$StandingRowCopyWithImpl<$Res>
    implements $StandingRowCopyWith<$Res> {
  _$StandingRowCopyWithImpl(this._self, this._then);

  final StandingRow _self;
  final $Res Function(StandingRow) _then;

/// Create a copy of StandingRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? team = null,Object? season = null,Object? rank = null,Object? won = null,Object? drawn = null,Object? lost = null,Object? pointsFor = null,Object? pointsAgainst = null,Object? tryBonus = null,Object? losingBonus = null,Object? points = null,}) {
  return _then(StandingRow(
team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as Team,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,won: null == won ? _self.won : won // ignore: cast_nullable_to_non_nullable
as int,drawn: null == drawn ? _self.drawn : drawn // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,pointsFor: null == pointsFor ? _self.pointsFor : pointsFor // ignore: cast_nullable_to_non_nullable
as int,pointsAgainst: null == pointsAgainst ? _self.pointsAgainst : pointsAgainst // ignore: cast_nullable_to_non_nullable
as int,tryBonus: null == tryBonus ? _self.tryBonus : tryBonus // ignore: cast_nullable_to_non_nullable
as int,losingBonus: null == losingBonus ? _self.losingBonus : losingBonus // ignore: cast_nullable_to_non_nullable
as int,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of StandingRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TeamCopyWith<$Res> get team {
  
  return $TeamCopyWith<$Res>(_self.team, (value) {
    return _then(_self.copyWith(team: value));
  });
}
}



// dart format on

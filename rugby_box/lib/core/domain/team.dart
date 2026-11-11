import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';

/// Une équipe de rugby (club ou sélection nationale).
@freezed
class const Team({
  /// Id ESPN de l'équipe (`'25986'` pour Toulon).
  required final String id,

  /// Nom complet (`'RC Toulon'`).
  required final String name,

  /// Sigle, pour les tableaux (`'RCT'`).
  required final String shortName,
}) with _$Team;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';

/// Une équipe de rugby (club ou sélection nationale).
///
/// Objet du domaine : du Dart pur, immuable, sans Flutter, ni HTTP, ni JSON.
@freezed
class const Team({
  /// Identifiant stable venant de la source de données (ex. `'rct'`, `'42'`).
  required final String id,

  /// Nom complet, pour les écrans qui ont de la place (ex. `'RC Toulon'`).
  required final String name,

  /// Nom court, pour les tableaux de classement (ex. `'TLN'`).
  required final String shortName,
}) with _$Team;

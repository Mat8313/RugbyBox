import 'package:freezed_annotation/freezed_annotation.dart';

part 'competition.freezed.dart';

/// Une compétition suivie par le boîtier (Top 14, Champions Cup…).
///
/// Objet du domaine : du Dart pur, immuable, sans Flutter, ni HTTP, ni JSON.

enum Format { league, pools }

@freezed
class const Competition({
  required final String id,
  required final String name,
  required final String shortName,
  required final Format format,
}) with _$Competition;

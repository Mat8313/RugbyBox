import '../../domain/match.dart';
import 'espn_dtos.dart';

// Mapper : traduit les DTO ESPN en objets du domaine.
// Stratégie : un match abîmé est écarté, jamais le lot entier.

/// Un match écarté par le mapper, et pourquoi.
class const EspnRejection({
  /// Identifiant ESPN du match écarté.
  required final String? eventId,

  /// Raison lisible par un humain (ex. « statut inconnu : STATUS_FOO »).
  required final String reason,
});

/// Ce que renvoie le mapper : les matchs valides et les rejets.
class const EspnMappingResult({
  required final List<Match> matches,
  required final List<EspnRejection> rejections,
});

/// Traduit le statut ESPN en [MatchStatus], ou `null` si c'est impossible.
///
/// Le spécifique d'abord (`name` connus), puis le général (`state`).
MatchStatus? mapEspnStatus(EspnTypeDto? type) {
  // 1. Les `name` connus.
  switch (type?.name) {
    case 'STATUS_POSTPONED':
      return MatchStatus.postponed;
    case 'STATUS_CANCELED':
      return MatchStatus.canceled;
  }

  // 2. Repli sur `state` pour les `name` inconnus.
  return switch (type?.state) {
    'pre' => MatchStatus.planned,
    'in' => MatchStatus.inProgress,
    'post' => type?.completed == true ? MatchStatus.finished : null,
    _ => null,
  };
}

/// Lit un score ESPN (`"40"` → 40), ou `null` s'il est absent ou illisible.
///
/// Ne répond qu'à « ce texte est-il un score ? ». Savoir si le match
/// *doit* avoir un score dépend du statut, et se décide ailleurs.
int? parseEspnScore(String? raw) {
  if (raw == null) return null;
  final score = int.tryParse(raw);
  if (score == null || score < 0) return null;
  return score;
}

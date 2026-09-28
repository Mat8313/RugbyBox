import '../../domain/match.dart';
import '../../domain/team.dart';
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

/// Lit une date ESPN (`"2026-09-20T19:05Z"`) en UTC, ou `null` si c'est
/// impossible.
///
/// Refuse une date sans fuseau : elle serait lue en heure locale.
DateTime? parseEspnDate(String? raw) {
  if (raw == null) return null;
  final date = DateTime.tryParse(raw);

  if (date == null || !date.isUtc) return null;
  return date;
}

/// Trouve le camp [side] (`'home'` ou `'away'`) parmi les [competitors].
///
/// Se fie à `homeAway`, jamais à l'ordre de la liste. Renvoie `null` s'il
/// n'y a aucun camp de ce côté, ou plusieurs (ambigu).
EspnCompetitorDto? findEspnSide(
  List<EspnCompetitorDto>? competitors,
  String side,
) {
  return competitors?.where((c) => c.homeAway == side).singleOrNull;
}

/// Noms français d'une équipe : complet et court (ex. « RC Toulon », « RCT »).
typedef EspnTeamNames = ({String name, String shortName});

/// Traduit une équipe ESPN en [Team], ou `null` si c'est impossible.
///
/// Cherche d'abord l'`id` dans [names] ; sinon, repli sur `displayName`.
Team? mapEspnTeam(EspnTeamDto? dto, Map<String, EspnTeamNames> names) {
  final id = dto?.id;
  if (id == null) return null;

  final known = names[id];
  if (known != null) {
    return Team(id: id, name: known.name, shortName: known.shortName);
  }

  // Repli : l'équipe n'est pas dans la table.
  final displayName = dto?.displayName;
  if (displayName == null || displayName.isEmpty) return null;
  return Team(
    id: id,
    name: displayName,
    shortName: _fallbackShortName(displayName),
  );
}

/// Nom court de secours : les 3 premières lettres en majuscules (« Vannes » → « VAN »).
///
/// Imparfait (collisions possibles), mais court : il tient dans une colonne
/// de classement. Le vrai remède est d'ajouter l'équipe à la table.
String _fallbackShortName(String displayName) {
  final end = displayName.length < 3 ? displayName.length : 3;
  return displayName.substring(0, end).toUpperCase();
}

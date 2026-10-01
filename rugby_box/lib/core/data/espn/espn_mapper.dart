import '../../domain/competition.dart';
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

/// Les ids ESPN des équipes présentes au [standings] d'une compétition.
///
/// Parcourt **tous** les groupes (les poules de Champions Cup), et ignore
/// les lignes sans id. Un classement absent donne un ensemble vide.
Set<String> collectEspnTeamIds(EspnStandingsDto? standings) {
  return {
    for (final group in standings?.children ?? const <EspnStandingsGroupDto>[])
      for (final entry
          in group.standings?.entries ?? const <EspnStandingEntryDto>[])
        ?entry.team?.id,
  };
}

/// Vrai si [team] appartient à la compétition, d'après [validTeamIds].
///
/// Arrête les matchs fantômes : un id absent du classement est refusé,
/// même si le nom ressemble à celui d'un vrai club.
bool isEspnTeamInCompetition(EspnTeamDto? team, Set<String> validTeamIds) {
  final id = team?.id;
  return id != null && validTeamIds.contains(id);
}

/// Nom court de secours : les 3 premières lettres en majuscules (« Vannes » → « VAN »).
///
/// Imparfait (collisions possibles), mais court : il tient dans une colonne
/// de classement. Le vrai remède est d'ajouter l'équipe à la table.
String _fallbackShortName(String displayName) {
  final end = displayName.length < 3 ? displayName.length : 3;
  return displayName.substring(0, end).toUpperCase();
}

/// Traduit les réponses ESPN d'**une** compétition en objets du domaine.
///
/// Assemble les règles ci-dessus. Tout ce qui ne change pas d'un appel à
/// l'autre est injecté une fois pour toutes.
class const EspnMatchMapper({
  /// Compétition à laquelle appartiennent tous les matchs traduits.
  required final Competition competition,

  /// Noms français des équipes connues (id ESPN → noms).
  required final Map<String, EspnTeamNames> teamNames,

  /// Ids des équipes du classement : les autres sont des fantômes.
  required final Set<String> validTeamIds,
}) {
  /// Traduit un scoreboard : chaque match abîmé est écarté, jamais le lot.
  EspnMappingResult mapScoreboard(EspnScoreboardDto? scoreboard) {
    final matches = <Match>[];
    final rejections = <EspnRejection>[];

    for (final event in scoreboard?.events ?? const <EspnEventDto>[]) {
      try {
        matches.add(_mapEvent(event));
      } on _Rejected catch (rejected) {
        rejections.add(
          EspnRejection(eventId: event.id, reason: rejected.reason),
        );
      }
    }

    return EspnMappingResult(matches: matches, rejections: rejections);
  }

  /// Traduit un match, ou lève [_Rejected] au premier contrôle qui échoue.
  Match _mapEvent(EspnEventDto event) {
    final id = event.id ?? (throw const _Rejected('identifiant absent'));

    final competitors = event.competitions?.singleOrNull?.competitors;
    final homeDto =
        findEspnSide(competitors, 'home') ??
        (throw const _Rejected('camp à domicile introuvable ou ambigu'));

    final awayDto =
        findEspnSide(competitors, 'away') ??
        (throw const _Rejected("camp à l'extérieur introuvable ou ambigu"));

    // Avant la traduction : le repli de mapEspnTeam sur `displayName`
    // laisserait passer un fantôme au nom plausible.
    if (!isEspnTeamInCompetition(homeDto.team, validTeamIds) ||
        !isEspnTeamInCompetition(awayDto.team, validTeamIds)) {
      throw const _Rejected('équipe absente du classement (match fantôme)');
    }

    final homeTeam =
        mapEspnTeam(homeDto.team, teamNames) ??
        (throw const _Rejected('équipe à domicile sans nom utilisable'));
    final awayTeam =
        mapEspnTeam(awayDto.team, teamNames) ??
        (throw const _Rejected("équipe à l'extérieur sans nom utilisable"));

    final type = event.status?.type;
    final status =
        mapEspnStatus(type) ??
        (throw _Rejected('statut de match inconnu : ${type?.name}'));

    final kickoffUtc =
        parseEspnDate(event.date) ??
        (throw const _Rejected('date illisible ou pas en UTC'));

    final homeScore = status.hasScore
        ? parseEspnScore(homeDto.score) ??
              (throw const _Rejected(
                "score de l'équipe domicile illisible ou absent",
              ))
        : null;
    final awayScore = status.hasScore
        ? parseEspnScore(awayDto.score) ??
              (throw const _Rejected(
                "score de l'équipe extérieur illisible ou absent",
              ))
        : null;

    return Match(
      id: id,
      competition: competition,
      kickoffUtc: kickoffUtc,
      status: status,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeScore: homeScore,
      awayScore: awayScore,
    );
  }
}

/// Sortie de secours interne : un match refusé, et pourquoi.
///
/// Ne sort jamais de [EspnMatchMapper] : elle devient une [EspnRejection].
class const _Rejected(final String reason) implements Exception {}

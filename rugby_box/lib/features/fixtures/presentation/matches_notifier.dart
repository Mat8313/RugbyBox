import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/domain/match.dart';
import '../../../core/time/paris_time.dart';

/// Les matchs du jour, avec leur état de chargement.
///
/// L'écran lit `ref.watch(matchesProvider)` et reçoit un `AsyncValue` :
/// chargement, données ou erreur.
final matchesProvider = AsyncNotifierProvider<MatchesNotifier, List<Match>>(
  MatchesNotifier.new,
  retry: retryMatches,
);

/// Règle de réessai de [matchesProvider], appelée par Riverpod après chaque
/// échec de `build`.
///
/// [retryCount] vaut 0 au premier échec, puis 1, 2… Rendre une `Duration`
/// relance `build` après ce délai ; rendre `null` abandonne pour de bon.
Duration? retryMatches(int retryCount, Object error) {
  // Panne prévue (réseau, ESPN, classement absent) : elle finira par passer.
  // Un bug (Error) ne se réglera pas tout seul : on le laisse visible.
  if (error is Exception) {
    return const Duration(minutes: 1);
  }
  return null;
}

/// Rythme de rafraîchissement quand un match est en cours.
const liveRefresh = Duration(seconds: 30);

/// Rythme quand un match commence bientôt (ou aurait dû commencer).
const soonRefresh = Duration(minutes: 5);

/// Rythme le reste du temps.
const idleRefresh = Duration(minutes: 30);

/// En deçà de ce délai avant le coup d'envoi, un match « commence bientôt ».
const soonWindow = Duration(hours: 1);

/// Au-delà de ce délai après le coup d'envoi, un match encore `planned` est
/// considéré comme oublié par ESPN (annulé sans être mis à jour).
const forgottenAfter = Duration(hours: 3);

/// Délai avant de redemander les matchs, selon ce qu'ils deviennent.
///
/// Plus il se passe de choses, plus on redemande souvent : inutile de
/// solliciter ESPN toutes les 30 s un mardi sans match.
Duration refreshDelay(List<Match> matches, DateTime nowUtc) {
  final isLive = matches.any((match) => match.status == MatchStatus.inProgress);
  if (isLive) return liveRefresh;

  // Un coup d'envoi passé (différence négative) compte aussi : on attend
  // qu'ESPN passe le match en `inProgress`, souvent avec du retard.
  final startsSoon = matches.any((match) {
    final untilKickoff = match.kickoffUtc.difference(nowUtc);
    return match.status == MatchStatus.planned &&
        untilKickoff < soonWindow &&
        untilKickoff > -forgottenAfter;
  });
  if (startsSoon) return soonRefresh;

  return idleRefresh;
}

/// Va chercher les matchs du jour auprès du repository, puis se relance tout
/// seul au rythme de [refreshDelay].
class MatchesNotifier extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() async {
    final repository = ref.watch(rugbyRepositoryProvider);
    final nowUtc = repository.now();

    // Heure fausse au démarrage : on ne demande rien, `retryMatches` relance
    // dans 1 min, le temps que NTP mette l'horloge à l'heure.
    if (!isClockPlausible(nowUtc)) throw ClockNotSyncedException(nowUtc);

    final matches = await repository.fetchMatches(parisDay(nowUtc));

    // Relance `build` plus tard. Si le provider est détruit ou relancé
    // avant, le minuteur est annulé : jamais deux minuteurs à la fois.
    final timer = Timer(refreshDelay(matches, nowUtc), ref.invalidateSelf);
    ref.onDispose(timer.cancel);

    return matches;
  }
}

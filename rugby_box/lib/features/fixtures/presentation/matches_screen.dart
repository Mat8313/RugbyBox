import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/match.dart';
import 'matches_notifier.dart';

/// La liste des matchs du jour, avec chargement et erreur.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);

    // Pas de `.when` : pendant un réessai, Riverpod 3 rend un `AsyncLoading`
    // qui porte l'erreur, et `.when` n'afficherait que la roue.
    return switch (matches) {
      // Liste vide : jour sans match (trêve, semaine sans journée). Sans ce
      // cas, l'écran resterait noir et ferait croire à une panne.
      AsyncValue(value: []) => const _CenteredMessage(
        'Pas de match aujourd’hui.',
      ),
      // Des matchs, même anciens : on les montre (erreur douce).
      AsyncValue(:final value?) => ListView(
        children: [for (final match in value) MatchTile(match)],
      ),
      // Une panne prévue est relancée par `retryMatches`, pas un bug : on ne
      // promet un nouvel essai que s'il aura vraiment lieu.
      AsyncValue(:final error?) => _CenteredMessage(
        error is Exception
            ? 'Matchs indisponibles pour le moment.\n'
                  'Nouvel essai dans 1 minute.'
            : 'Un problème est survenu.\nRedémarrez le boîtier.',
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Un message centré, lisible sur fond noir.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 22),
      ),
    );
  }
}

/// Une ligne de match : « RCT 28 - 10 VAN », ou « RCT - VAN » sans score.
class MatchTile extends StatelessWidget {
  const MatchTile(this.match, {super.key});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final home = match.homeTeam.shortName;
    final away = match.awayTeam.shortName;
    final score = match.status.hasScore
        ? '${match.homeScore} - ${match.awayScore}'
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '$home $score $away',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

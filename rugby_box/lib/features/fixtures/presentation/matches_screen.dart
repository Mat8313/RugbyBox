import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/match.dart';
import '../../../core/time/paris_time.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/centered_message.dart';
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
      AsyncValue(value: []) => const CenteredMessage(
        'Pas de match aujourd’hui.',
      ),
      // Des matchs, même anciens : on les montre (erreur douce).
      AsyncValue(:final value?) => ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (_, i) => MatchTile(value[i]),
      ),
      // Une panne prévue est relancée par `retryMatches`, pas un bug : on ne
      // promet un nouvel essai que s'il aura vraiment lieu.
      AsyncValue(:final error?) => CenteredMessage(
        error is Exception
            ? 'Matchs indisponibles pour le moment.\n'
                  'Nouvel essai dans 1 minute.'
            : 'Un problème est survenu.\nRedémarrez le boîtier.',
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Une carte de match : « RCT  28 - 10  VAN », avec en dessous l'état du
/// match (« 2e mi-temps », « Terminé »…). Avant le coup d'envoi, l'heure de
/// Paris prend la place du score.
class MatchTile extends StatelessWidget {
  const MatchTile(this.match, {super.key});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final homeScore = match.homeScore ?? 0;
    final awayScore = match.awayScore ?? 0;
    // Le perdant d'un match terminé passe en gris : on lit le résultat sans
    // comparer les chiffres.
    final isFinished = match.status == MatchStatus.finished;
    final homeLost = isFinished && homeScore < awayScore;
    final awayLost = isFinished && awayScore < homeScore;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _TeamName(
              match.homeTeam.shortName,
              dimmed: homeLost,
              align: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  match.status.hasScore
                      ? '$homeScore - $awayScore'
                      : _formatTime(parisTime(match.kickoffUtc)),
                  style: TextStyle(
                    color: match.status.hasScore
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFeatures: tabularFigures,
                  ),
                ),
                _StatusLabel(match),
              ],
            ),
          ),
          Expanded(
            child: _TeamName(
              match.awayTeam.shortName,
              dimmed: awayLost,
              align: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  /// « 16:35 ».
  static String _formatTime(DateTime time) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
  }
}

class _TeamName extends StatelessWidget {
  const _TeamName(this.name, {required this.dimmed, required this.align});

  final String name;
  final bool dimmed;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      textAlign: align,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: dimmed ? AppColors.textMuted : AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// La petite ligne sous le score. En direct : un point rouge et la phase.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel(this.match);

  final Match match;

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == MatchStatus.inProgress;
    final label = switch (match.status) {
      MatchStatus.planned => 'À venir',
      MatchStatus.inProgress => switch (match.phase) {
        MatchPhase.firstHalf => '1re mi-temps',
        MatchPhase.halftime => 'Mi-temps',
        MatchPhase.secondHalf => '2e mi-temps',
        null => 'En direct',
      },
      MatchStatus.finished => 'Terminé',
      MatchStatus.postponed => 'Reporté',
      MatchStatus.canceled => 'Annulé',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLive) ...[
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.highlight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            color: isLive ? AppColors.highlight : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isLive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

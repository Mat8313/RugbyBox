import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/standing_row.dart';
import '../../../core/ui/app_colors.dart';
import '../../../core/ui/centered_message.dart';
import 'standings_notifier.dart';

/// Équipe mise en avant, en attendant le réglage « équipe favorite ».
const highlightedTeamId = '25986'; // RC Toulon

/// Le classement : rang, équipe, matchs joués, différence, points.
class StandingsScreen extends ConsumerWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider);

    // Même ordre que l'écran des matchs (pas de `.when`) : valeur d'abord,
    // même ancienne, puis erreur, puis roue.
    return switch (standings) {
      AsyncValue(value: []) => const CenteredMessage(
        'Classement pas encore publié.',
      ),
      AsyncValue(:final value?) => _StandingsTable(value),
      AsyncValue(:final error?) => CenteredMessage(
        error is Exception
            ? 'Classement indisponible pour le moment.\n'
                  'Nouvel essai dans 1 minute.'
            : 'Un problème est survenu.\nRedémarrez le boîtier.',
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// L'en-tête (avec la saison réellement affichée) et les lignes.
///
/// Chaque ligne est un `Expanded` : la hauteur disponible est partagée en
/// parts égales, et le classement entier tient sans défiler, en paysage
/// comme en portrait.
class _StandingsTable extends StatelessWidget {
  const _StandingsTable(this.rows);

  final List<StandingRow> rows;

  @override
  Widget build(BuildContext context) {
    // La saison vient des lignes : en août, c'est celle d'avant (repli), et
    // l'écran le dit au lieu de faire passer l'ancien classement pour neuf.
    final season = rows.first.season;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RowLayout(
          rank: '',
          team: 'Saison ${season - 1}-${season % 100}',
          played: 'J',
          difference: 'Diff',
          points: 'Pts',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        for (final row in rows) Expanded(child: StandingTile(row)),
      ],
    );
  }
}

/// Une ligne du classement : « ▌1  RC Toulon  10  +45  47 ».
class StandingTile extends StatelessWidget {
  const StandingTile(this.row, {super.key});

  final StandingRow row;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = row.team.id == highlightedTeamId;
    final difference = row.pointsDifference;
    final zone = _zoneColor(row.rank);

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.highlight.withValues(alpha: 0.25)
            : null,
        borderRadius: BorderRadius.circular(4),
        // Liseré de zone à gauche : qualifiés, barragiste, relégué.
        border: Border(
          left: BorderSide(color: zone ?? Colors.transparent, width: 3),
        ),
      ),
      alignment: Alignment.center,
      child: _RowLayout(
        rank: '${row.rank}',
        team: row.team.name,
        played: '${row.played}',
        // Signe explicite : « +12 » se lit mieux que « 12 » à côté de « -8 ».
        difference: difference > 0 ? '+$difference' : '$difference',
        points: '${row.points}',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// Zones du Top 14 : 1-2 en demi-finale, 3-6 en barrage, 13e en barrage
  /// d'accession, 14e relégué. À déplacer dans `Competition` quand l'app
  /// suivra d'autres compétitions.
  static Color? _zoneColor(int rank) => switch (rank) {
    1 || 2 => AppColors.zoneSemiFinal,
    >= 3 && <= 6 => AppColors.zonePlayoff,
    13 => AppColors.zoneRelegationPlayoff,
    14 => AppColors.zoneRelegation,
    _ => null,
  };
}

/// Les colonnes, partagées par l'en-tête et les lignes : largeurs fixes et
/// chiffres tabulaires pour que tout reste aligné d'une ligne à l'autre.
class _RowLayout extends StatelessWidget {
  const _RowLayout({
    required this.rank,
    required this.team,
    required this.played,
    required this.difference,
    required this.points,
    required this.style,
  });

  final String rank;
  final String team;
  final String played;
  final String difference;
  final String points;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final numbers = style.copyWith(fontFeatures: tabularFigures);
    // Matchs joués et différence en retrait : l'œil va d'abord aux points.
    final secondary = numbers.copyWith(color: AppColors.textSecondary);

    Widget cell(String text, double width, TextStyle style) => SizedBox(
      width: width,
      child: Text(text, textAlign: TextAlign.right, style: style),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          cell(rank, 22, numbers),
          const SizedBox(width: 12),
          Expanded(
            child: Text(team, overflow: TextOverflow.ellipsis, style: style),
          ),
          cell(played, 28, secondary),
          cell(difference, 48, secondary),
          cell(points, 40, numbers.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

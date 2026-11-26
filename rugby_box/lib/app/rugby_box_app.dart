import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/ui/app_colors.dart';
import '../core/ui/panel.dart';
import '../features/fixtures/presentation/matches_screen.dart';
import '../features/standings/presentation/standings_screen.dart';
import 'touch_scroll_behavior.dart';

/// Racine de l'interface.
class RugbyBoxApp extends StatelessWidget {
  const RugbyBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RugbyBox',
      scrollBehavior: const TouchScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.highlight,
          surface: AppColors.surface,
        ),
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(),
                SizedBox(height: 8),
                Expanded(child: _HomeLayout()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Matchs et classement, côte à côte si l'écran est plus large que haut,
/// sinon empilés.
///
/// On regarde la place réellement disponible, pas un réglage : le jour où
/// l'orientation viendra des réglages, il suffira de faire pivoter l'écran.
class _HomeLayout extends StatelessWidget {
  const _HomeLayout();

  static const _matches = Panel(
    title: 'Matchs du jour',
    child: MatchesScreen(),
  );
  static const _standings = Panel(
    title: 'Classement',
    child: StandingsScreen(),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        // En paysage, les noms complets du classement demandent un peu plus
        // de largeur. En portrait, moitié-moitié : les lignes du classement
        // se resserrent pour laisser de la place aux matchs.
        return Flex(
          direction: isLandscape ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(flex: 5, child: _matches),
            const SizedBox(width: 8, height: 8),
            Expanded(flex: isLandscape ? 6 : 5, child: _standings),
          ],
        );
      },
    );
  }
}

/// Bandeau du haut : la compétition, et un rappel en mode données fictives.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: AppColors.highlight,
            margin: const EdgeInsets.only(right: 8),
          ),
          const Text(
            'TOP 14',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          if (config.useMockData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textMuted),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Données fictives',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

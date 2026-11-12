import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../features/fixtures/presentation/matches_screen.dart';
import 'touch_scroll_behavior.dart';

/// Racine de l'interface.
class RugbyBoxApp extends StatelessWidget {
  const RugbyBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'RugbyBox',
      scrollBehavior: TouchScrollBehavior(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _Header(),
              Expanded(child: MatchesScreen()),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Text(
            'TOP 14',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (config.useMockData)
            const Text(
              'Données fictives',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
        ],
      ),
    );
  }
}

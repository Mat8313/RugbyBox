import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration de l'application, choisie une seule fois au démarrage.
class AppConfig {
  const AppConfig({required this.useMockData});

  /// true : données fictives (fichiers JSON locaux), false : vraie API.
  final bool useMockData;
}

/// Donne accès à la configuration partout dans l'app.
///
/// Volontairement sans valeur par défaut : elle doit être fournie par
/// `bootstrap()` (ou par un test) via `overrideWithValue`.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider doit être fourni via ProviderScope(overrides: ...)',
  ),
);

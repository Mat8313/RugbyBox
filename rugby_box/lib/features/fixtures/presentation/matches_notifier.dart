import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/domain/match.dart';

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

/// Va chercher les matchs du jour auprès du repository.
class MatchesNotifier extends AsyncNotifier<List<Match>> {
  @override
  Future<List<Match>> build() async {
    final repository = ref.watch(rugbyRepositoryProvider);
    return repository.fetchMatches(repository.now());
  }
}

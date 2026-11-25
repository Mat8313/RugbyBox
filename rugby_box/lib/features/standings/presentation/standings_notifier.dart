import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/domain/standing_row.dart';
import '../../../core/time/paris_time.dart';
import '../../fixtures/presentation/matches_notifier.dart';

/// Le classement de la saison en cours, trié du 1er au dernier.
///
/// Même règle de réessai que les matchs : une panne prévue est relancée
/// toutes les minutes, un bug reste visible.
final standingsProvider =
    AsyncNotifierProvider<StandingsNotifier, List<StandingRow>>(
      StandingsNotifier.new,
      retry: retryMatches,
    );

/// Lit le classement auprès du repository, et le relit chaque fois que les
/// matchs se rafraîchissent : c'est `fetchMatches` qui met le cache à jour
/// quand un match se termine.
class StandingsNotifier extends AsyncNotifier<List<StandingRow>> {
  @override
  Future<List<StandingRow>> build() async {
    final repository = ref.watch(rugbyRepositoryProvider);
    final nowUtc = repository.now();

    // Heure fausse au démarrage : mauvaise saison, on attend NTP.
    if (!isClockPlausible(nowUtc)) throw ClockNotSyncedException(nowUtc);

    // Seule une AsyncData des matchs FINIE est nouvelle : pendant un
    // rafraîchissement, Riverpod émet une AsyncData(isLoading: true) qui
    // garde l'ancienne valeur. Une erreur du scoreboard ne doit pas toucher
    // un classement en cache valide.
    ref.listen(matchesProvider, (previous, next) {
      if (next is AsyncData && !next.isLoading) ref.invalidateSelf();
    });

    return await repository.fetchStandings(parisDay(nowUtc));
  }
}

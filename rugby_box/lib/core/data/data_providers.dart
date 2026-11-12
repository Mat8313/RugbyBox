import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/competition.dart';
import 'espn/espn_data_source.dart';
import 'rugby_repository.dart';

/// Le Top 14, seule compétition suivie pour l'instant.
const top14 = Competition(
  id: '270559',
  name: 'Top 14',
  shortName: 'TOP14',
  format: CompetitionFormat.league,
);

/// La source ESPN (fichiers locaux ou réseau).
///
/// Volontairement sans valeur par défaut, comme `appConfigProvider` : elle
/// est fournie par `bootstrap()` (ou par un test) via `overrideWithValue`.
final espnDataSourceProvider = Provider<EspnDataSource>(
  (ref) => throw UnimplementedError(
    'espnDataSourceProvider doit être fourni via ProviderScope(overrides: ...)',
  ),
);

/// Le repository du Top 14. Une seule instance pour toute la vie de l'app :
/// c'est elle qui garde le cache des classements.
final rugbyRepositoryProvider = Provider<RugbyRepository>((ref) {
  return RugbyRepository(
    dataSource: ref.watch(espnDataSourceProvider),
    competition: top14,
  );
});

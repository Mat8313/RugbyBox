import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/data_providers.dart';
import 'package:rugby_box/core/data/rugby_repository.dart';
import 'package:rugby_box/features/fixtures/presentation/matches_notifier.dart';

import '../../../support/fixture_data_source.dart';

void main() {
  group('retryMatches', () {
    test('relance une panne prévue', () {
      expect(
        retryMatches(0, const StandingsUnavailableException(2027)),
        isNotNull,
      );
      expect(retryMatches(0, Exception('réseau coupé')), isNotNull);
    });

    test('ne se lasse jamais d’une panne prévue', () {
      expect(retryMatches(1000, Exception('ESPN en panne')), isNotNull);
    });

    test('abandonne sur un bug', () {
      expect(retryMatches(0, StateError('null inattendu')), isNull);
    });
  });

  group('MatchesNotifier', () {
    test('rend les matchs du repository', () async {
      final container = ProviderContainer.test(
        overrides: [
          espnDataSourceProvider.overrideWithValue(
            const FixtureDataSource(
              scoreboardFile: 'scoreboard_top14_2026-09-20.json',
              standingsFile: 'standings_top14_2027.json',
            ),
          ),
        ],
      );

      final matches = await container.read(matchesProvider.future);

      expect(matches, isNotEmpty);
      expect(container.read(matchesProvider).hasValue, isTrue);
    });
  });
}

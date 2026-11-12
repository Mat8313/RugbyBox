import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/data_providers.dart';

import '../../support/fixture_data_source.dart';

void main() {
  group('rugbyRepositoryProvider', () {
    test('rend toujours la même instance, qui garde donc son cache', () {
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

      final first = container.read(rugbyRepositoryProvider);
      final second = container.read(rugbyRepositoryProvider);

      expect(identical(first, second), isTrue);
      expect(first.competition, top14);
    });

    test('échoue clairement si la source n’a pas été fournie', () {
      final container = ProviderContainer.test();

      expect(() => container.read(rugbyRepositoryProvider), throwsA(anything));
    });
  });
}

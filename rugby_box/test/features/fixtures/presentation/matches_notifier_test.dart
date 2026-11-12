import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/data_providers.dart';
import 'package:rugby_box/core/data/rugby_repository.dart';
import 'package:rugby_box/core/domain/match.dart';
import 'package:rugby_box/core/domain/team.dart';
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

  group('refreshDelay', () {
    final nowUtc = DateTime.utc(2026, 9, 26, 16);

    test('rafraîchit vite pendant un match en cours', () {
      final matches = [
        _match(MatchStatus.finished, nowUtc),
        _match(MatchStatus.inProgress, nowUtc),
      ];

      expect(refreshDelay(matches, nowUtc), liveRefresh);
    });

    test('se prépare quand un match commence dans moins d’une heure', () {
      final kickoff = nowUtc.add(const Duration(minutes: 40));

      expect(
        refreshDelay([_match(MatchStatus.planned, kickoff)], nowUtc),
        soonRefresh,
      );
    });

    test('attend le direct d’ESPN quand le coup d’envoi est passé', () {
      final kickoff = nowUtc.subtract(const Duration(minutes: 5));

      expect(
        refreshDelay([_match(MatchStatus.planned, kickoff)], nowUtc),
        soonRefresh,
      );
    });

    test('oublie un match jamais lancé par ESPN après trois heures', () {
      final kickoff = nowUtc.subtract(const Duration(hours: 4));

      expect(
        refreshDelay([_match(MatchStatus.planned, kickoff)], nowUtc),
        idleRefresh,
      );
    });

    test('ralentit quand le prochain match est loin', () {
      final kickoff = nowUtc.add(const Duration(hours: 3));

      expect(
        refreshDelay([_match(MatchStatus.planned, kickoff)], nowUtc),
        idleRefresh,
      );
    });

    test('ralentit sans aucun match', () {
      expect(refreshDelay([], nowUtc), idleRefresh);
    });

    test('ignore un match reporté, même à l’heure prévue', () {
      expect(
        refreshDelay([_match(MatchStatus.postponed, nowUtc)], nowUtc),
        idleRefresh,
      );
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

/// Un match minimal : seuls [status] et [kickoffUtc] comptent pour le rythme.
Match _match(MatchStatus status, DateTime kickoffUtc) => Match(
  id: '1',
  competition: top14,
  kickoffUtc: kickoffUtc,
  status: status,
  homeTeam: const Team(id: '25986', name: 'RC Toulon', shortName: 'RCT'),
  awayTeam: const Team(id: '1', name: 'Vannes', shortName: 'VAN'),
);

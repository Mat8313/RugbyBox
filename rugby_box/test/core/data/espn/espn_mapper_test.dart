import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/espn/espn_dtos.dart';
import 'package:rugby_box/core/data/espn/espn_mapper.dart';
import 'package:rugby_box/core/domain/match.dart';

void main() {
  group('mapEspnStatus', () {
    test('Un match reporté est reconnu comme tel (report en post)', () {
      const type = EspnTypeDto(
        name: 'STATUS_POSTPONED',
        state: 'post',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.postponed);
    });

    test('Un match annulé est reconnu comme tel', () {
      const type = EspnTypeDto(
        name: 'STATUS_CANCELED',
        state: 'post',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.canceled);
    });

    test('Un match prévu est reconnu comme tel', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'pre',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.planned);
    });

    test('Un match en cours est reconnu comme tel', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'in',
        completed: false,
      );

      expect(mapEspnStatus(type), MatchStatus.inProgress);
    });

    test(
      'Un match passé et dit fini (completed: true) est reconnu comme tel',
      () {
        const type = EspnTypeDto(
          name: 'STATUS_UNKNOWN',
          state: 'post',
          completed: true,
        );

        expect(mapEspnStatus(type), MatchStatus.finished);
      },
    );

    test('Un match passé et dit non fini (completed: false) est rejeter', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'post',
        completed: false,
      );

      expect(mapEspnStatus(type), isNull);
    });

    test('Un match passé et fin inconnu (completed: null) est rejeter', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'post',
        completed: null,
      );

      expect(mapEspnStatus(type), isNull);
    });

    test('Un match avec des informations fausses sur son état est rejeter', () {
      const type = EspnTypeDto(
        name: 'STATUS_UNKNOWN',
        state: 'xyz',
        completed: true,
      );

      expect(mapEspnStatus(type), isNull);
    });

    test('Un match sans information sur son état est rejeter', () {
      expect(mapEspnStatus(null), isNull);
    });
  });
}

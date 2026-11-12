import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/time/paris_time.dart';

void main() {
  group('lastSundayAt1hUtc', () {
    test('trouve les changements d’heure de 2026 et 2027', () {
      expect(lastSundayAt1hUtc(2026, 3), DateTime.utc(2026, 3, 29, 1));
      expect(lastSundayAt1hUtc(2026, 10), DateTime.utc(2026, 10, 25, 1));
      expect(lastSundayAt1hUtc(2027, 3), DateTime.utc(2027, 3, 28, 1));
      expect(lastSundayAt1hUtc(2027, 10), DateTime.utc(2027, 10, 31, 1));
    });
  });

  group('isClockPlausible', () {
    test('refuse une horloge restée en 1970', () {
      expect(isClockPlausible(DateTime.utc(1970)), isFalse);
    });

    test('accepte une heure récente', () {
      expect(isClockPlausible(DateTime.utc(2026, 11, 12, 20)), isTrue);
    });
  });

  group('parisDay', () {
    test('en hiver, 23 h 30 UTC est déjà le lendemain à Paris', () {
      expect(
        parisDay(DateTime.utc(2026, 12, 5, 23, 30)),
        DateTime.utc(2026, 12, 6),
      );
    });

    test('en hiver, 22 h 30 UTC est encore le même jour à Paris', () {
      expect(
        parisDay(DateTime.utc(2026, 12, 5, 22, 30)),
        DateTime.utc(2026, 12, 5),
      );
    });

    test('en été, 22 h 30 UTC est déjà le lendemain à Paris', () {
      expect(
        parisDay(DateTime.utc(2026, 9, 26, 22, 30)),
        DateTime.utc(2026, 9, 27),
      );
    });

    test('suit le passage à l’heure d’été de mars', () {
      // 29/03/2026 : à 1 h UTC, Paris passe de 2 h à 3 h.
      final before = DateTime.utc(2026, 3, 28, 22, 30); // 23 h 30 à Paris
      final after = DateTime.utc(2026, 3, 29, 22, 30); // 0 h 30 le 30/03

      expect(parisDay(before), DateTime.utc(2026, 3, 28));
      expect(parisDay(after), DateTime.utc(2026, 3, 30));
    });

    test('suit le retour à l’heure d’hiver d’octobre', () {
      // 25/10/2026 : à 1 h UTC, Paris repasse de 3 h à 2 h.
      final before = DateTime.utc(2026, 10, 24, 22, 30); // 0 h 30 le 25/10
      final after = DateTime.utc(2026, 10, 25, 22, 30); // 23 h 30 le 25/10

      expect(parisDay(before), DateTime.utc(2026, 10, 25));
      expect(parisDay(after), DateTime.utc(2026, 10, 25));
    });

    test('passe le réveillon', () {
      expect(parisDay(DateTime.utc(2026, 12, 31, 23, 30)), DateTime.utc(2027));
    });
  });
}

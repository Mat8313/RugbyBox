import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_box/core/data/retry_schedule.dart';

void main() {
  const minute = Duration(minutes: 1);
  final t0 = DateTime.utc(2026, 9, 26, 16, 30);

  group('RetrySchedule', () {
    test("Rien n'est dû avant le démarrage", () {
      expect(RetrySchedule([minute]).isDue(t0), isFalse);
    });

    test('Suit les délais puis termine la série', () {
      final schedule = RetrySchedule([minute, minute * 2])..start(t0);

      expect(schedule.isDue(t0.add(const Duration(seconds: 59))), isFalse);
      expect(schedule.isDue(t0.add(minute)), isTrue);

      schedule.advance(t0.add(minute));
      expect(schedule.isDue(t0.add(minute * 2)), isFalse);
      expect(schedule.isDue(t0.add(minute * 3)), isTrue);

      schedule.advance(t0.add(minute * 3));
      expect(schedule.isDue(t0.add(const Duration(days: 1))), isFalse);
    });

    test('Un nouveau départ en pleine série repart du premier délai', () {
      final schedule = RetrySchedule([minute, minute * 30])..start(t0);
      schedule.advance(t0.add(minute)); // prochain essai à t0 + 31 min

      final restart = t0.add(minute * 2);
      schedule.start(restart);

      expect(schedule.isDue(restart.add(minute)), isTrue);
    });
  });
}

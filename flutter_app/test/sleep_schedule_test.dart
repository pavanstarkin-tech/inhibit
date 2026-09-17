import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/services/sleep_schedule.dart';

void main() {
  group('SleepSchedule Tests', () {
    test('Overnight sleep window 22:00 to 07:00', () {
      const schedule = SleepSchedule(
        startMinute: 22 * 60, // 1320 (10:00 PM)
        endMinute: 7 * 60,    // 420  (7:00 AM)
        enabled: true,
      );

      // Active at 23:30
      expect(schedule.isActive(DateTime(2026, 1, 1, 23, 30)), isTrue);
      // Active at 02:00
      expect(schedule.isActive(DateTime(2026, 1, 1, 2, 0)), isTrue);
      // Active at 06:59
      expect(schedule.isActive(DateTime(2026, 1, 1, 6, 59)), isTrue);
      // Inactive at 07:01
      expect(schedule.isActive(DateTime(2026, 1, 1, 7, 1)), isFalse);
      // Inactive at 15:00
      expect(schedule.isActive(DateTime(2026, 1, 1, 15, 0)), isFalse);
    });

    test('Disabled schedule always returns false', () {
      const schedule = SleepSchedule(
        startMinute: 22 * 60,
        endMinute: 7 * 60,
        enabled: false,
      );
      expect(schedule.isActive(DateTime(2026, 1, 1, 23, 30)), isFalse);
    });

    test('Formats time correctly', () {
      const schedule = SleepSchedule(
        startMinute: 22 * 60 + 30,
        endMinute: 7 * 60,
        enabled: true,
      );

      expect(schedule.formatTime(22 * 60 + 30), '10:30 PM');
      expect(schedule.formatTime(7 * 60), '7:00 AM');
      expect(schedule.formatTime(0), '12:00 AM');
    });
  });
}

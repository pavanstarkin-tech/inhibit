class SleepSchedule {
  final int startMinute; // Minutes from midnight (e.g. 22:00 -> 1320)
  final int endMinute;   // Minutes from midnight (e.g. 07:00 -> 420)
  final bool enabled;
  final List<int> weekdays; // 1 = Monday, 7 = Sunday (empty = everyday)

  const SleepSchedule({
    required this.startMinute,
    required this.endMinute,
    required this.enabled,
    this.weekdays = const [],
  });

  bool isActive(DateTime now) {
    if (!enabled) return false;

    if (weekdays.isNotEmpty && !weekdays.contains(now.weekday)) {
      return false;
    }

    final currentMinute = now.hour * 60 + now.minute;

    if (startMinute < endMinute) {
      // Same day (e.g. 13:00 to 15:00)
      return currentMinute >= startMinute && currentMinute < endMinute;
    } else {
      // Overnight (e.g. 22:00 to 07:00)
      return currentMinute >= startMinute || currentMinute < endMinute;
    }
  }

  String formatTime(int totalMinutes) {
    final h = (totalMinutes ~/ 60) % 24;
    final m = totalMinutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final displayM = m.toString().padLeft(2, '0');
    return '$displayH:$displayM $period';
  }

  String get formattedStart => formatTime(startMinute);
  String get formattedEnd => formatTime(endMinute);

  Duration timeUntilNextChange(DateTime now) {
    final active = isActive(now);
    final targetMin = active ? endMinute : startMinute;
    final currentMin = now.hour * 60 + now.minute;

    int diffMin = targetMin - currentMin;
    if (diffMin < 0) diffMin += 24 * 60;

    return Duration(minutes: diffMin, seconds: 60 - now.second);
  }
}

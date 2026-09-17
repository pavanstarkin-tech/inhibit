import 'dart:math' as math;

enum LifeBandKind {
  past,
  sleep,
  work,
  hygiene,
  scrolling,
  free,
}

class LifeBand {
  final LifeBandKind kind;
  final double years;
  final int weeks;

  const LifeBand({
    required this.kind,
    required this.years,
    required this.weeks,
  });

  int get roundedYears => years.round();
}

class LifeAssumptions {
  final double lifeExpectancy;
  final double sleepHoursPerDay;
  final double workHoursPerDay;
  final double hygieneHoursPerDay;

  const LifeAssumptions({
    this.lifeExpectancy = 90.0,
    this.sleepHoursPerDay = 8.0,
    this.workHoursPerDay = 8.0,
    this.hygieneHoursPerDay = 3.0,
  });

  double get freeHoursPerDay =>
      math.max(0.0, 24.0 - sleepHoursPerDay - workHoursPerDay - hygieneHoursPerDay);
}

class LifeInWeeks {
  final int age;
  final double scrollHoursPerDay;
  final LifeAssumptions assumptions;
  final List<LifeBand> bands;
  final int totalWeeks;
  final double scrollShare;

  LifeInWeeks({
    required int age,
    required double scrollHoursPerDay,
    this.assumptions = const LifeAssumptions(),
  })  : age = math.min(math.max(age, 1), assumptions.lifeExpectancy.toInt() - 1),
        scrollHoursPerDay = math.max(0.0, scrollHoursPerDay),
        scrollShare = _computeScrollShare(
          math.max(0.0, scrollHoursPerDay),
          assumptions.freeHoursPerDay,
        ),
        bands = _computeBands(
          math.min(math.max(age, 1), assumptions.lifeExpectancy.toInt() - 1),
          math.max(0.0, scrollHoursPerDay),
          assumptions,
        ),
        totalWeeks = _computeTotalWeeks(
          math.min(math.max(age, 1), assumptions.lifeExpectancy.toInt() - 1),
          math.max(0.0, scrollHoursPerDay),
          assumptions,
        );

  static double _computeScrollShare(double scrollHours, double freeHours) {
    if (freeHours <= 0) return 1.0;
    return math.min(1.0, scrollHours / freeHours);
  }

  static List<LifeBand> _computeBands(
    int clampedAge,
    double scrollHours,
    LifeAssumptions assumptions,
  ) {
    final remaining = assumptions.lifeExpectancy - clampedAge.toDouble();
    const day = 24.0;

    final sleepYears = remaining * (assumptions.sleepHoursPerDay / day);
    final workYears = remaining * (assumptions.workHoursPerDay / day);
    final hygieneYears = remaining * (assumptions.hygieneHoursPerDay / day);
    final freeYears = math.max(0.0, remaining - sleepYears - workYears - hygieneYears);

    final freeHours = assumptions.freeHoursPerDay;
    final share = freeHours > 0 ? math.min(1.0, scrollHours / freeHours) : 1.0;

    final scrollingYears = freeYears * share;
    final leftoverYears = freeYears - scrollingYears;

    const weeksPerYear = 52.0;
    int toWeeks(double years) => (years * weeksPerYear).round();

    return [
      LifeBand(kind: LifeBandKind.past, years: clampedAge.toDouble(), weeks: toWeeks(clampedAge.toDouble())),
      LifeBand(kind: LifeBandKind.sleep, years: sleepYears, weeks: toWeeks(sleepYears)),
      LifeBand(kind: LifeBandKind.work, years: workYears, weeks: toWeeks(workYears)),
      LifeBand(kind: LifeBandKind.hygiene, years: hygieneYears, weeks: toWeeks(hygieneYears)),
      LifeBand(kind: LifeBandKind.scrolling, years: scrollingYears, weeks: toWeeks(scrollingYears)),
      LifeBand(kind: LifeBandKind.free, years: leftoverYears, weeks: toWeeks(leftoverYears)),
    ];
  }

  static int _computeTotalWeeks(
    int clampedAge,
    double scrollHours,
    LifeAssumptions assumptions,
  ) {
    final b = _computeBands(clampedAge, scrollHours, assumptions);
    return b.fold(0, (sum, item) => sum + item.weeks);
  }

  int get scrollPercent => (scrollShare * 100).round();

  double get yearsLostToScrolling {
    for (final band in bands) {
      if (band.kind == LifeBandKind.scrolling) return band.years;
    }
    return 0.0;
  }

  LifeBandKind kindForWeek(int index) {
    var cursor = 0;
    for (final band in bands) {
      cursor += band.weeks;
      if (index < cursor) return band.kind;
    }
    return LifeBandKind.free;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/models/life_in_weeks.dart';

void main() {
  group('LifeInWeeks Arithmetic Tests', () {
    test('Calculates accurate bands at age 18 with 4.8h scroll', () {
      final life = LifeInWeeks(age: 18, scrollHoursPerDay: 4.8);

      expect(life.age, 18);
      expect(life.scrollPercent, 96); // 4.8 / 5.0 free hours = 96%
      expect(life.bands.length, 6);

      // Check band kinds
      expect(life.bands[0].kind, LifeBandKind.past);
      expect(life.bands[0].years, 18.0);
      expect(life.bands[0].weeks, 936); // 18 * 52

      expect(life.bands[1].kind, LifeBandKind.sleep);
      expect(life.bands[2].kind, LifeBandKind.work);
      expect(life.bands[3].kind, LifeBandKind.hygiene);
      expect(life.bands[4].kind, LifeBandKind.scrolling);
      expect(life.bands[5].kind, LifeBandKind.free);

      // Total weeks should match sum of weeks
      final sumWeeks = life.bands.fold(0, (sum, b) => sum + b.weeks);
      expect(life.totalWeeks, sumWeeks);
    });

    test('Clamps age boundaries cleanly', () {
      final lifeYoung = LifeInWeeks(age: -5, scrollHoursPerDay: 2.0);
      expect(lifeYoung.age, 1);

      final lifeOld = LifeInWeeks(age: 100, scrollHoursPerDay: 2.0);
      expect(lifeOld.age, 89);
    });

    test('Scroll share is capped at 100%', () {
      final lifeExcess = LifeInWeeks(age: 25, scrollHoursPerDay: 12.0);
      expect(lifeExcess.scrollShare, 1.0);
      expect(lifeExcess.scrollPercent, 100);
    });
  });
}

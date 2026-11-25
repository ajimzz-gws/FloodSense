import 'package:floodsense/data/stations_data.dart';
import 'package:floodsense/models/flood_level.dart';
import 'package:floodsense/services/alert_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Drawbridge thresholds (0670341WL)', () {
    final st = buildStations().first;

    test('real reading -0.30 m is Normal', () {
      expect(st.id, '0670341WL');
      expect(st.level, FloodLevel.normal);
    });

    test('levels classify at and around each threshold', () {
      expect(st.classify(0.30), FloodLevel.normal);
      expect(st.classify(1.39), FloodLevel.normal);
      expect(st.classify(1.40), FloodLevel.alert);
      expect(st.classify(1.59), FloodLevel.alert);
      expect(st.classify(1.60), FloodLevel.warning);
      expect(st.classify(1.79), FloodLevel.warning);
      expect(st.classify(1.80), FloodLevel.danger);
      expect(st.classify(3.00), FloodLevel.danger);
    });
  });

  group('AlertEngine', () {
    AlertDecision d(FloodLevel cur, FloodLevel last, bool inZone) =>
        AlertEngine.decide(current: cur, lastNotified: last, inZone: inZone);

    test('rising into Alert inside the zone notifies', () {
      final r = d(FloodLevel.alert, FloodLevel.normal, true);
      expect(r.notify, isTrue);
      expect(r.lastNotified, FloodLevel.alert);
    });

    test('no repeat while the level stays the same', () {
      expect(d(FloodLevel.warning, FloodLevel.warning, true).notify, isFalse);
    });

    test('each step up notifies again', () {
      expect(d(FloodLevel.warning, FloodLevel.alert, true).notify, isTrue);
      expect(d(FloodLevel.danger, FloodLevel.warning, true).notify, isTrue);
    });

    test('jumping straight from Normal to Danger notifies once', () {
      final r = d(FloodLevel.danger, FloodLevel.normal, true);
      expect(r.notify, isTrue);
      expect(r.lastNotified, FloodLevel.danger);
    });

    test('outside the zone: no alert, and nothing remembered', () {
      final r = d(FloodLevel.danger, FloodLevel.normal, false);
      expect(r.notify, isFalse);
      expect(r.lastNotified, FloodLevel.normal);
    });

    test('walking into the zone later still alerts', () {
      expect(d(FloodLevel.danger, FloodLevel.normal, true).notify, isTrue);
    });

    test('falling water resets memory so a second rise alerts', () {
      final down = d(FloodLevel.alert, FloodLevel.danger, true);
      expect(down.notify, isFalse);
      expect(down.lastNotified, FloodLevel.alert);
      expect(d(FloodLevel.danger, down.lastNotified, true).notify, isTrue);
    });

    test('Normal never notifies', () {
      expect(d(FloodLevel.normal, FloodLevel.normal, true).notify, isFalse);
    });
  });
}

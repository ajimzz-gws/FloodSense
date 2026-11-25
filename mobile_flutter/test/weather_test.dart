import 'package:floodsense/models/weather.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('translateForecast (MET Malaysia phrases seen in the API)', () {
    final cases = {
      'Tiada Hujan': 'No rain',
      'Hujan': 'Rain',
      'Hujan di beberapa tempat': 'Scattered rain',
      'Hujan di beberapa tempat di kawasan pantai': 'Scattered rain (coastal areas)',
      'Hujan di beberapa tempat di kawasan pedalaman': 'Scattered rain (inland areas)',
      'Hujan di kebanyakan tempat': 'Rain in most places',
      'Hujan di kebanyakan tempat di kawasan pedalaman': 'Rain in most places (inland areas)',
      'Hujan menyeluruh': 'Widespread rain',
      'Ribut petir': 'Thunderstorms',
      'Ribut petir di beberapa tempat': 'Scattered thunderstorms',
      'Ribut petir di beberapa tempat di kawasan pantai': 'Scattered thunderstorms (coastal areas)',
      'Ribut petir di kebanyakan tempat': 'Thunderstorms in most places',
      'Ribut petir menyeluruh': 'Widespread thunderstorms',
      'Ribut petir di satu dua tempat': 'Isolated thunderstorms',
    };
    cases.forEach((ms, en) {
      test(ms, () => expect(translateForecast(ms), en));
    });

    test('unknown phrase is left in Malay', () {
      expect(translateForecast('Sesuatu yang baharu'), 'Sesuatu yang baharu');
    });
  });

  test('translateWhen', () {
    expect(translateWhen('Sepanjang Hari'), 'All day');
    expect(translateWhen('Pagi'), 'Morning');
    expect(translateWhen('Petang dan Malam'), 'Afternoon and night');
  });

  test('rain severity', () {
    expect(rainSeverityOf('Tiada Hujan'), RainSeverity.none);
    expect(rainSeverityOf('Hujan di beberapa tempat'), RainSeverity.light);
    expect(rainSeverityOf('Hujan menyeluruh'), RainSeverity.heavy);
    expect(rainSeverityOf('Hujan di kebanyakan tempat'), RainSeverity.heavy);
    expect(rainSeverityOf('Ribut petir di beberapa tempat'), RainSeverity.heavy);
  });
}

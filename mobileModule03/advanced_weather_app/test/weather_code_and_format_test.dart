// Мелкие чистые функции: коды погоды и форматирование.
//
// ВАЖНО: тесты не запускались (см. docs/02-ex02.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_weather_app/models/coordinates.dart';
import 'package:advanced_weather_app/models/place.dart';
import 'package:advanced_weather_app/models/weather_code.dart';
import 'package:advanced_weather_app/ui/formatters.dart';

void main() {
  group('describeWeatherCode', () {
    test('известные коды', () {
      expect(describeWeatherCode(0), 'Clear sky');
      expect(describeWeatherCode(3), 'Overcast');
      expect(describeWeatherCode(61), 'Slight rain');
      expect(describeWeatherCode(95), 'Thunderstorm');
      expect(describeWeatherCode(99), 'Thunderstorm with heavy hail');
    });

    test('незнакомый код не роняет программу', () {
      expect(describeWeatherCode(42), 'Unknown weather');
      expect(describeWeatherCode(-1), 'Unknown weather');
    });
  });

  group('форматирование', () {
    test('температура: одна цифра после запятой, без «-0.0»', () {
      expect(formatTemperature(12.34), '12.3°C');
      expect(formatTemperature(-5), '-5.0°C');
      expect(formatTemperature(-0.04), '0.0°C');
    });

    test('ветер', () {
      expect(formatWind(10), '10.0 km/h');
      expect(formatWind(3.26), '3.3 km/h');
    });

    test('время и дата с ведущими нулями', () {
      expect(formatHour(DateTime(2026, 11, 28, 7, 5)), '07:05');
      expect(formatDate(DateTime(2026, 3, 4)), '2026-03-04');
    });
  });

  group('дни недели и ось графика', () {
    test('названия дней: 30 ноября 2026 понедельник, дальше по порядку', () {
      final List<String> names = [
        for (int d = 30; d <= 36; d++) formatWeekday(DateTime(2026, 11, d)), // 31-36 переходят в декабрь
      ];
      expect(names, ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']);
    });

    test('28 ноября 2026 это суббота (проверено по календарю)', () {
      expect(formatWeekday(DateTime(2026, 11, 28)), 'Saturday');
      expect(formatWeekdayShort(DateTime(2026, 11, 28)), 'Sat');
    });

    test('подпись оси температур: целое со значком градуса', () {
      expect(formatAxisTemperature(12.6), '13°');
      expect(formatAxisTemperature(-4.6), '-5°');
      expect(formatAxisTemperature(-0.4), '0°');
      expect(formatAxisTemperature(0), '0°');
    });
  });

  group('Place', () {
    test('subtitle: регион и страна, пропуская отсутствующие', () {
      const c = Coordinates(0, 0);
      expect(const Place(name: 'A', coordinates: c, region: 'R', country: 'C').subtitle, 'R, C');
      expect(const Place(name: 'A', coordinates: c, country: 'C').subtitle, 'C');
      expect(const Place(name: 'A', coordinates: c).subtitle, isEmpty);
    });

    test('atCoordinates: имя это сами координаты', () {
      expect(Place.atCoordinates(const Coordinates(41.3874, 2.1686)).name, '41.3874, 2.1686');
    });
  });
}

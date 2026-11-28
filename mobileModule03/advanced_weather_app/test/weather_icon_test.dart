// Иконки по кодам погоды: у каждого известного кода должна быть своя осмысленная
// иконка, у неизвестного «знак вопроса», а не падение.
//
// ВАЖНО: тесты не запускались (см. docs/03-ex02.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_weather_app/models/weather_code.dart';
import 'package:advanced_weather_app/ui/weather_icon.dart';

void main() {
  // Все коды, которые знает describeWeatherCode (таблица WMO у Open-Meteo).
  const List<int> knownCodes = [
    0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67,
    71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 97, 99,
  ];

  test('у каждого известного кода есть иконка, не «знак вопроса»', () {
    for (final int code in knownCodes) {
      expect(weatherIcon(code), isNot(Icons.help_outline), reason: 'код $code');
      expect(describeWeatherCode(code), isNot('Unknown weather'), reason: 'код $code');
    }
  });

  test('неизвестный код: знак вопроса', () {
    expect(weatherIcon(42), Icons.help_outline);
    expect(weatherIcon(-1), Icons.help_outline);
  });

  test('день и ночь различаются только у ясного неба', () {
    expect(weatherIcon(0), Icons.wb_sunny);
    expect(weatherIcon(0, isDay: false), Icons.nights_stay);
    expect(weatherIcon(1, isDay: false), Icons.nights_stay);
    expect(weatherIcon(61, isDay: false), weatherIcon(61));
    expect(weatherIcon(3, isDay: false), weatherIcon(3));
  });

  test('семейства: дождь, снег, гроза, туман, морось', () {
    expect(weatherIcon(63), Icons.water_drop);
    expect(weatherIcon(81), Icons.water_drop);
    expect(weatherIcon(73), Icons.ac_unit);
    expect(weatherIcon(86), Icons.ac_unit);
    expect(weatherIcon(95), Icons.thunderstorm);
    expect(weatherIcon(45), Icons.foggy);
    expect(weatherIcon(53), Icons.grain);
  });

  test('цвета: солнце жёлтое, луна бледная, остальное светлое', () {
    expect(weatherIconColor(0), const Color(0xFFFFC857));
    expect(weatherIconColor(0, isDay: false), const Color(0xFFCFD8FF));
    expect(weatherIconColor(61), const Color(0xFFE8F1FF));
  });
}

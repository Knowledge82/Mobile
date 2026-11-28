// Тесты разбора прогноза Open-Meteo. Ответ собран вручную по документации
// (https://open-meteo.com/en/docs), форма та же, что у настоящего.
//
// ВАЖНО: тесты не запускались (см. docs/02-ex02.md).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:advanced_weather_app/failures.dart';
import 'package:advanced_weather_app/models/weather_report.dart';
import 'package:advanced_weather_app/services/weather_service.dart';

import 'fakes.dart';

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

String two(int v) => v.toString().padLeft(2, '0');

// Прогноз на 2 суток по часам (48 значений) и 7 суток по дням.
// «Сейчас» 28 ноября 14:15. Часть чисел целые: так бывает в настоящих ответах.
Map<String, dynamic> forecastJson() {
  final List<String> hourTimes = [
    for (final int day in [28, 29])
      for (int h = 0; h < 24; h++) '2026-11-$day' 'T${two(h)}:00',
  ];
  return {
    'latitude': 41.4,
    'longitude': 2.2,
    'timezone': 'Europe/Madrid',
    'current': {
      'time': '2026-11-28T14:15',
      'interval': 900,
      'temperature_2m': 12.3,
      'weather_code': 2,
      'wind_speed_10m': 10, // целое число!
      'is_day': 1,
    },
    'hourly': {
      'time': hourTimes,
      'temperature_2m': List.generate(48, (int i) => i), // целые
      'weather_code': List.filled(48, 3),
      'wind_speed_10m': List.generate(48, (int i) => i * 0.5),
      // ночь с 20:00 до 06:59, день остальное время
      'is_day': List.generate(48, (int i) => (i % 24 >= 7 && i % 24 < 20) ? 1 : 0),
    },
    'daily': {
      'time': [for (int d = 28; d <= 30; d++) '2026-11-$d', '2026-12-01', '2026-12-02', '2026-12-03', '2026-12-04'],
      'weather_code': [0, 1, 2, 3, 61, 63, 95],
      'temperature_2m_max': [14.0, 13.5, 12.0, 11.0, 10.0, 9.0, 8.5],
      'temperature_2m_min': [6.0, 5.5, 5.0, 4.0, 3.0, 2.0, 1.5],
    },
  };
}

void main() {
  test('разбирает сейчас, сегодня по часам и неделю по дням', () async {
    final service = OpenMeteoWeatherService(
      MockClient((_) async => jsonResponse(forecastJson())),
    );

    final WeatherReport report = await service.fetch(barcelona);

    // сейчас
    expect(report.place, barcelona);
    expect(report.current.temperature, 12.3);
    expect(report.current.windSpeed, 10.0); // 10 (int) стало 10.0
    expect(report.current.description, 'Partly cloudy');
    expect(report.current.isDay, isTrue);

    // по часам: из 48 значений остаётся ровно «сегодня» (24)
    expect(report.hourly, hasLength(24));
    expect(report.hourly.first.time, DateTime(2026, 11, 28, 0));
    expect(report.hourly.last.time, DateTime(2026, 11, 28, 23));
    expect(report.hourly[5].temperature, 5.0);
    expect(report.hourly[5].windSpeed, 2.5);
    expect(report.hourly[5].description, 'Overcast');

    // по дням
    expect(report.daily, hasLength(7));
    expect(report.daily.first.date, DateTime(2026, 11, 28));
    expect(report.daily.first.maxTemperature, 14.0);
    expect(report.daily.first.minTemperature, 6.0);
    expect(report.daily.first.description, 'Clear sky');
    expect(report.daily.last.description, 'Thunderstorm');
  });

  test('строит правильный запрос: координаты, переменные, единицы, пояс', () async {
    late Uri url;
    final service = OpenMeteoWeatherService(
      MockClient((http.Request request) async {
        url = request.url;
        return jsonResponse(forecastJson());
      }),
    );

    await service.fetch(barcelona);

    final Map<String, String> q = url.queryParameters;
    expect(url.host, 'api.open-meteo.com');
    expect(url.path, '/v1/forecast');
    expect(q['latitude'], '41.38879');
    expect(q['longitude'], '2.15899');
    expect(q['current'], 'temperature_2m,weather_code,wind_speed_10m,is_day');
    expect(q['hourly'], 'temperature_2m,weather_code,wind_speed_10m,is_day');
    expect(q['daily'], 'weather_code,temperature_2m_max,temperature_2m_min');
    expect(q['timezone'], 'auto');
    expect(q['temperature_unit'], 'celsius');
    expect(q['wind_speed_unit'], 'kmh');
  });

  test('is_day: ночные часы помечены, день и ночь различаются', () async {
    final service = OpenMeteoWeatherService(
      MockClient((_) async => jsonResponse(forecastJson())),
    );

    final WeatherReport report = await service.fetch(barcelona);

    expect(report.hourly[3].isDay, isFalse); // 03:00
    expect(report.hourly[12].isDay, isTrue); // 12:00
    expect(report.hourly[22].isDay, isFalse); // 22:00
  });

  test('нет поля is_day: это украшение, поэтому ошибки нет, считаем днём', () async {
    final json = forecastJson();
    (json['current'] as Map<String, dynamic>).remove('is_day');
    (json['hourly'] as Map<String, dynamic>).remove('is_day');
    final service = OpenMeteoWeatherService(
      MockClient((_) async => jsonResponse(json)),
    );

    final WeatherReport report = await service.fetch(barcelona);

    expect(report.current.isDay, isTrue);
    expect(report.hourly.every((HourlyWeather h) => h.isDay), isTrue);
  });

  test('нет блока current: ServerFailure', () async {
    final json = forecastJson()..remove('current');
    final service = OpenMeteoWeatherService(
      MockClient((_) async => jsonResponse(json)),
    );

    await expectLater(service.fetch(barcelona), throwsA(isA<ServerFailure>()));
  });

  test('null вместо температуры: ServerFailure', () async {
    final json = forecastJson();
    (json['hourly'] as Map<String, dynamic>)['temperature_2m'] = List<Object?>.filled(48, null);
    final service = OpenMeteoWeatherService(
      MockClient((_) async => jsonResponse(json)),
    );

    await expectLater(service.fetch(barcelona), throwsA(isA<ServerFailure>()));
  });

  test('400 с причиной: ServerFailure', () async {
    final service = OpenMeteoWeatherService(
      MockClient(
        (_) async => jsonResponse({'error': true, 'reason': 'Invalid variable'}, 400),
      ),
    );

    await expectLater(
      service.fetch(barcelona),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'код', 400)),
    );
  });

  test('нет сети: ConnectionFailure', () async {
    final service = OpenMeteoWeatherService(
      MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(service.fetch(barcelona), throwsA(isA<ConnectionFailure>()));
  });
}

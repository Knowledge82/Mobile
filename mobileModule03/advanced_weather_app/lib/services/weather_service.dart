import 'package:http/http.dart' as http;

import '../models/place.dart';
import '../models/weather_report.dart';
import 'http_json.dart';

// «Место => прогноз».
abstract interface class WeatherService {
  // Бросает ConnectionFailure или ServerFailure.
  Future<WeatherReport> fetch(Place place);
}

// Weather Forecast API от Open-Meteo: https://open-meteo.com/en/docs
final class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService(this._client);

  final http.Client _client;

  @override
  Future<WeatherReport> fetch(Place place) async {
    final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${place.coordinates.latitude}',
      'longitude': '${place.coordinates.longitude}',
      'current': 'temperature_2m,weather_code,wind_speed_10m,is_day',
      'hourly': 'temperature_2m,weather_code,wind_speed_10m,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      // auto: часовой пояс самого места. Без него daily не работает, а часы
      // были бы по Гринвичу.
      'timezone': 'auto',
      'forecast_days': '7',
      // По умолчанию и так °C и км/ч, но явное лучше неявного.
      'temperature_unit': 'celsius',
      'wind_speed_unit': 'kmh',
    });

    final Map<String, dynamic> json = await getJson(_client, uri);
    return parseResponse(() => _parse(place, json));
  }

  WeatherReport _parse(Place place, Map<String, dynamic> json) {
    // --- сейчас ---
    final Map<String, dynamic> current = json['current'] as Map<String, dynamic>;
    final DateTime now = DateTime.parse(current['time'] as String);

    // --- по часам: в ответе 7 суток подряд (168 значений), нам нужен «сегодня» ---
    final Map<String, dynamic> hourly = json['hourly'] as Map<String, dynamic>;
    final List<Object?> hourTimes = hourly['time'] as List<Object?>;
    final List<Object?> hourTemps = hourly['temperature_2m'] as List<Object?>;
    final List<Object?> hourCodes = hourly['weather_code'] as List<Object?>;
    final List<Object?> hourWinds = hourly['wind_speed_10m'] as List<Object?>;
    // is_day: необязательное «украшение» (иконка), поэтому его отсутствие не ошибка.
    final List<Object?>? hourDay = hourly['is_day'] as List<Object?>?;

    final List<HourlyWeather> today = [];
    for (int i = 0; i < hourTimes.length; i++) {
      final DateTime time = DateTime.parse(hourTimes[i] as String);
      // «Сегодня» определяем по ТЕКУЩЕМУ времени места (current.time),
      // а не по часам телефона: в Токио и в Барселоне «сегодня» разное.
      if (time.year == now.year && time.month == now.month && time.day == now.day) {
        today.add(
          HourlyWeather(
            time: time,
            temperature: _number(hourTemps[i]),
            weatherCode: _integer(hourCodes[i]),
            windSpeed: _number(hourWinds[i]),
            isDay: _isDay(hourDay?[i]),
          ),
        );
      }
    }

    // --- по дням ---
    final Map<String, dynamic> daily = json['daily'] as Map<String, dynamic>;
    final List<Object?> dayDates = daily['time'] as List<Object?>;
    final List<Object?> dayCodes = daily['weather_code'] as List<Object?>;
    final List<Object?> dayMax = daily['temperature_2m_max'] as List<Object?>;
    final List<Object?> dayMin = daily['temperature_2m_min'] as List<Object?>;

    return WeatherReport(
      place: place,
      current: CurrentWeather(
        temperature: _number(current['temperature_2m']),
        weatherCode: _integer(current['weather_code']),
        windSpeed: _number(current['wind_speed_10m']),
        isDay: _isDay(current['is_day']),
      ),
      hourly: today,
      daily: [
        for (int i = 0; i < dayDates.length; i++)
          DailyWeather(
            date: DateTime.parse(dayDates[i] as String),
            minTemperature: _number(dayMin[i]),
            maxTemperature: _number(dayMax[i]),
            weatherCode: _integer(dayCodes[i]),
          ),
      ],
    );
  }

  // JSON-число может прийти и как 12 (int), и как 12.5 (double): приводим через num.
  // null (нет данных) даст TypeError и станет ServerFailure.
  double _number(Object? value) => (value as num).toDouble();

  int _integer(Object? value) => (value as num).toInt();

  // 1 = день, 0 = ночь. Нет значения или оно странное: считаем днём (иконка солнца
  // лучше, чем падение экрана из-за украшения).
  bool _isDay(Object? value) => value is num ? value != 0 : true;
}

import 'place.dart';
import 'weather_code.dart';

// Погода «сейчас»: температура в °C, ветер в км/ч (единицы мы просим у API явно).
class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    this.isDay = true,
  });

  final double temperature;
  final int weatherCode;
  final double windSpeed;

  // Сейчас там день? (поле is_day API). Нужно иконке: ночью вместо солнца луна.
  final bool isDay;

  String get description => describeWeatherCode(weatherCode);
}

// Один час сегодняшнего дня.
class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    this.isDay = true,
  });

  // Местное время ТОГО места, для которого запрошена погода (не время телефона).
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final bool isDay;

  String get description => describeWeatherCode(weatherCode);
}

// Один день недели.
class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.weatherCode,
  });

  final DateTime date;
  final double minTemperature;
  final double maxTemperature;
  final int weatherCode;

  String get description => describeWeatherCode(weatherCode);
}

// Всё, что нужно трём вкладкам, одним объектом: место + три среза погоды.
class WeatherReport {
  const WeatherReport({
    required this.place,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final Place place;
  final CurrentWeather current;
  final List<HourlyWeather> hourly; // только сегодня, до 24 записей
  final List<DailyWeather> daily; // до 7 дней
}

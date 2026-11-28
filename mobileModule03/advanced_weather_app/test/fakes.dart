// Подделки сервисов для тестов: без сети, без GPS, мгновенные и управляемые.

import 'package:advanced_weather_app/failures.dart';
import 'package:advanced_weather_app/models/coordinates.dart';
import 'package:advanced_weather_app/models/place.dart';
import 'package:advanced_weather_app/models/weather_report.dart';
import 'package:advanced_weather_app/services/geocoding_service.dart';
import 'package:advanced_weather_app/services/location_service.dart';
import 'package:advanced_weather_app/services/reverse_geocoding_service.dart';
import 'package:advanced_weather_app/services/weather_service.dart';
import 'package:advanced_weather_app/state/weather_controller.dart';

const Place paris = Place(
  name: 'Paris',
  region: 'Île-de-France',
  country: 'France',
  coordinates: Coordinates(48.85341, 2.3488),
);

const Place parma = Place(
  name: 'Parma',
  region: 'Emilia-Romagna',
  country: 'Italy',
  coordinates: Coordinates(44.80266, 10.32898),
);

const Place barcelona = Place(
  name: 'Barcelona',
  region: 'Catalonia',
  country: 'Spain',
  coordinates: Coordinates(41.38879, 2.15899),
);

const Coordinates deviceCoordinates = Coordinates(41.3874, 2.1686);

// result: либо Coordinates, либо WeatherFailure (его подделка выбросит).
class FakeLocationService implements LocationService {
  FakeLocationService([this.result = deviceCoordinates]);

  Object result;
  int calls = 0;

  @override
  Future<Coordinates> currentCoordinates() async {
    calls++;
    final Object r = result;
    if (r is WeatherFailure) throw r;
    return r as Coordinates;
  }
}

class FakeGeocodingService implements GeocodingService {
  FakeGeocodingService([this.database = const [paris, parma, barcelona]]);

  final List<Place> database;
  WeatherFailure? failure;
  final List<String> queries = [];

  @override
  Future<List<Place>> search(String query, {int count = 5}) async {
    queries.add(query);
    final WeatherFailure? f = failure;
    if (f != null) throw f;
    final String q = query.toLowerCase();
    return database
        .where((Place p) => p.name.toLowerCase().startsWith(q))
        .take(count)
        .toList();
  }
}

class FakeReverseGeocodingService implements ReverseGeocodingService {
  FakeReverseGeocodingService([this.result = barcelona]);

  // Place или WeatherFailure.
  Object result;

  @override
  Future<Place> lookup(Coordinates coordinates) async {
    final Object r = result;
    if (r is WeatherFailure) throw r;
    return r as Place;
  }
}

class FakeWeatherService implements WeatherService {
  WeatherFailure? failure;
  final List<Place> requested = [];

  // Если задан, подделка отдаёт ЭТОТ отчёт вместо sampleReport (для особых случаев:
  // ночь, пустой список часов и т. п.).
  WeatherReport Function(Place place)? reportBuilder;

  @override
  Future<WeatherReport> fetch(Place place) async {
    requested.add(place);
    final WeatherFailure? f = failure;
    if (f != null) throw f;
    return (reportBuilder ?? sampleReport)(place);
  }
}

// Правдоподобный отчёт: 24 часа, 7 дней, температура зависит от номера часа/дня,
// чтобы строки в списках отличались друг от друга.
WeatherReport sampleReport(Place place) => WeatherReport(
  place: place,
  current: const CurrentWeather(temperature: 12.3, weatherCode: 2, windSpeed: 10.5),
  hourly: [
    for (int h = 0; h < 24; h++)
      HourlyWeather(
        time: DateTime(2026, 11, 28, h),
        temperature: 5.0 + h / 2,
        weatherCode: h < 12 ? 3 : 61,
        windSpeed: 4.0 + h,
        isDay: h >= 7 && h < 18,
      ),
  ],
  daily: [
    for (int d = 0; d < 7; d++)
      DailyWeather(
        date: DateTime(2026, 11, 28 + d),
        minTemperature: 3.0 + d,
        maxTemperature: 11.0 + d,
        weatherCode: d.isEven ? 0 : 63,
      ),
  ],
);

// Набор подделок и контроллер на них, одной строкой.
class Rig {
  Rig({
    Duration debounce = const Duration(milliseconds: 300),
    Duration retry = const Duration(seconds: 10),
    List<Place> cities = const [paris, parma, barcelona],
  }) : geocoding = FakeGeocodingService(cities) {
    controller = WeatherController(
      location: location,
      geocoding: geocoding,
      reverseGeocoding: reverse,
      weather: weather,
      suggestDebounce: debounce,
      retryInterval: retry,
    );
  }

  final FakeLocationService location = FakeLocationService();
  final FakeGeocodingService geocoding;
  final FakeReverseGeocodingService reverse = FakeReverseGeocodingService();
  final FakeWeatherService weather = FakeWeatherService();
  late final WeatherController controller;
}

// Геокодер, который игнорирует count и всегда возвращает ВСЁ, что есть:
// проверяет, что приложение само не покажет больше пяти подсказок.
class GreedyGeocodingService implements GeocodingService {
  GreedyGeocodingService(this.database);

  final List<Place> database;

  @override
  Future<List<Place>> search(String query, {int count = 5}) async => database;
}

// Много городов для проверки «не больше пяти подсказок».
final List<Place> springfields = [
  for (int i = 1; i <= 8; i++)
    Place(
      name: 'Springfield $i',
      region: 'State $i',
      country: 'Country $i',
      coordinates: Coordinates(30.0 + i, -90.0 - i),
    ),
];

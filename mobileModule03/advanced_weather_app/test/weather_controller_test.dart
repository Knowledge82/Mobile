// Тесты контроллера на подделках: вся логика приложения без сети, GPS и экрана.
// Таймеры здесь настоящие, но короткие (миллисекунды): debounce и повтор.
//
// ВАЖНО: тесты не запускались (см. docs/02-ex00.md ... docs/02-ex03.md (логика унаследована от модуля 02)).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_weather_app/failures.dart';
import 'package:advanced_weather_app/models/place.dart';
import 'package:advanced_weather_app/models/weather_report.dart';
import 'package:advanced_weather_app/services/weather_service.dart';
import 'package:advanced_weather_app/state/weather_controller.dart';
import 'package:advanced_weather_app/state/weather_state.dart';

import 'fakes.dart';

Future<void> pause([int milliseconds = 60]) =>
    Future<void>.delayed(Duration(milliseconds: milliseconds));

// Создаёт набор подделок и гарантирует dispose контроллера в конце теста.
Rig makeRig({int debounceMs = 10, int retryMs = 30}) {
  final Rig rig = Rig(
    debounce: Duration(milliseconds: debounceMs),
    retry: Duration(milliseconds: retryMs),
  );
  addTearDown(rig.controller.dispose);
  return rig;
}

// Подделка, которая отвечает, только когда тест разрешит (для проверки гонок).
class ManualWeatherService implements WeatherService {
  final Map<String, Completer<WeatherReport>> pending = {};

  @override
  Future<WeatherReport> fetch(Place place) {
    final Completer<WeatherReport> completer = Completer();
    pending[place.name] = completer;
    return completer.future;
  }
}

void main() {
  group('ex00: геолокация', () {
    test('в начале состояния нет', () {
      final Rig rig = makeRig();
      expect(rig.controller.state, isA<WeatherIdle>());
    });

    test('GPS разрешён: Loading, затем Loaded с названием места', () async {
      final Rig rig = makeRig();
      final List<Type> seen = [];
      rig.controller.addListener(() => seen.add(rig.controller.state.runtimeType));

      await rig.controller.useCurrentLocation();

      expect(seen, [WeatherLoading, WeatherLoaded]);
      final WeatherLoaded loaded = rig.controller.state as WeatherLoaded;
      expect(loaded.report.place, barcelona); // название от обратного геокодера
      expect(rig.weather.requested.single, barcelona);
    });

    test('разрешение отклонено: понятная ошибка, приложение живо', () async {
      final Rig rig = makeRig();
      rig.location.result = const LocationDeniedFailure();

      await rig.controller.useCurrentLocation();

      final WeatherFailed failed = rig.controller.state as WeatherFailed;
      expect(failed.failure, isA<LocationDeniedFailure>());
      expect(failed.failure.message, contains('No access to your location'));
      expect(rig.weather.requested, isEmpty);
    });

    test('после отказа поиск по городу работает', () async {
      final Rig rig = makeRig();
      rig.location.result = const LocationDeniedFailure();
      await rig.controller.useCurrentLocation();

      await rig.controller.search('Paris');

      final WeatherLoaded loaded = rig.controller.state as WeatherLoaded;
      expect(loaded.report.place, paris);
    });

    test('любая из ошибок геолокации превращается в состояние, а не в падение', () async {
      for (final WeatherFailure failure in const [
        LocationDeniedFailure(),
        LocationDeniedForeverFailure(),
        LocationServiceDisabledFailure(),
        LocationUnavailableFailure(),
      ]) {
        final Rig rig = makeRig();
        rig.location.result = failure;

        await rig.controller.useCurrentLocation();

        expect((rig.controller.state as WeatherFailed).failure, same(failure));
      }
    });
  });

  group('ex01: поиск и подсказки', () {
    test('обратный геокодер не ответил: вместо названия координаты', () async {
      final Rig rig = makeRig();
      rig.reverse.result = const ServerFailure();

      await rig.controller.useCurrentLocation();

      final WeatherLoaded loaded = rig.controller.state as WeatherLoaded;
      expect(loaded.report.place.name, deviceCoordinates.toString());
    });

    test('search берёт первый найденный город (count = 1)', () async {
      final Rig rig = makeRig();

      await rig.controller.search('Par');

      expect((rig.controller.state as WeatherLoaded).report.place, paris);
    });

    test('search обрезает пробелы', () async {
      final Rig rig = makeRig();

      await rig.controller.search('  Paris \n');

      expect(rig.geocoding.queries, ['Paris']);
    });

    test('пустой запрос игнорируется', () async {
      final Rig rig = makeRig();

      await rig.controller.search('   ');

      expect(rig.controller.state, isA<WeatherIdle>());
      expect(rig.geocoding.queries, isEmpty);
    });

    test('select загружает погоду для выбранного места без поиска', () async {
      final Rig rig = makeRig();

      await rig.controller.select(parma);

      expect(rig.geocoding.queries, isEmpty);
      expect((rig.controller.state as WeatherLoaded).report.place, parma);
    });

    test('подсказки появляются после паузы в наборе', () async {
      final Rig rig = makeRig();

      rig.controller.queryChanged('Par');
      expect(rig.controller.suggestions, isEmpty); // ещё не успели
      await pause();

      expect(rig.controller.suggestions, [paris, parma]);
    });

    test('быстрый набор даёт ОДИН запрос (debounce)', () async {
      final Rig rig = makeRig(debounceMs: 30);

      rig.controller.queryChanged('Pa');
      rig.controller.queryChanged('Par');
      rig.controller.queryChanged('Pari');
      await pause(100);

      expect(rig.geocoding.queries, ['Pari']);
      expect(rig.controller.suggestions, [paris]);
    });

    test('один символ не ищем', () async {
      final Rig rig = makeRig();

      rig.controller.queryChanged('P');
      await pause();

      expect(rig.geocoding.queries, isEmpty);
    });

    test('стёрли текст: подсказки пропадают', () async {
      final Rig rig = makeRig();
      rig.controller.queryChanged('Par');
      await pause();
      expect(rig.controller.suggestions, isNotEmpty);

      rig.controller.queryChanged('');

      expect(rig.controller.suggestions, isEmpty);
    });

    test('выбор и поиск убирают подсказки и отменяют ожидающий запрос', () async {
      final Rig rig = makeRig(debounceMs: 40);
      rig.controller.queryChanged('Par');

      await rig.controller.select(paris); // раньше, чем истёк debounce
      await pause(100);

      expect(rig.geocoding.queries, isEmpty);
      expect(rig.controller.suggestions, isEmpty);
    });

    test('даже если геокодер вернул больше пяти, подсказок не больше пяти', () async {
      final Rig rig = makeRig();
      final controller = WeatherController(
        location: rig.location,
        geocoding: GreedyGeocodingService(springfields), // игнорирует count, отдаёт все 8
        reverseGeocoding: rig.reverse,
        weather: rig.weather,
        suggestDebounce: const Duration(milliseconds: 10),
      );
      addTearDown(controller.dispose);

      controller.queryChanged('Spring');
      await pause();

      expect(controller.suggestions, hasLength(5));
      expect(controller.suggestions, springfields.take(5).toList());
    });

    test('ошибка подсказок молчаливая: список пуст, состояние не трогаем', () async {
      final Rig rig = makeRig();
      rig.geocoding.failure = const ConnectionFailure();

      rig.controller.queryChanged('Par');
      await pause();

      expect(rig.controller.suggestions, isEmpty);
      expect(rig.controller.state, isA<WeatherIdle>());
    });
  });

  group('ex02: гонки запросов', () {
    test('медленный старый ответ не затирает новый', () async {
      final ManualWeatherService manual = ManualWeatherService();
      final Rig rig = makeRig();
      final controller = controllerWith(rig, manual);
      addTearDown(controller.dispose);

      final Future<void> first = controller.select(paris);
      final Future<void> second = controller.select(parma);
      // ответы приходят в обратном порядке: сначала новый, потом старый
      manual.pending['Parma']!.complete(sampleReport(parma));
      manual.pending['Paris']!.complete(sampleReport(paris));
      await Future.wait([first, second]);

      expect((controller.state as WeatherLoaded).report.place, parma);
    });
  });

  group('ex03: ошибки и повтор', () {
    test('города нет: CityNotFound с введённым текстом, и сообщение остаётся', () async {
      final Rig rig = makeRig();

      await rig.controller.search('Atlantis');
      await pause(100);

      final WeatherFailed failed = rig.controller.state as WeatherFailed;
      expect(failed.failure, isA<CityNotFoundFailure>());
      expect((failed.failure as CityNotFoundFailure).query, 'Atlantis');
    });

    test('верный город после ошибки убирает сообщение', () async {
      final Rig rig = makeRig();
      await rig.controller.search('Atlantis');

      await rig.controller.search('Paris');

      expect(rig.controller.state, isA<WeatherLoaded>());
    });

    test('обрыв связи: сообщение остаётся, а при восстановлении исчезает само', () async {
      final Rig rig = makeRig();
      final List<Type> seen = [];
      rig.controller.addListener(() => seen.add(rig.controller.state.runtimeType));
      rig.weather.failure = const ConnectionFailure();

      await rig.controller.search('Paris');
      expect((rig.controller.state as WeatherFailed).failure, isA<ConnectionFailure>());

      rig.weather.failure = null; // «интернет вернулся»
      await pause(120); // дольше интервала повтора

      expect(rig.controller.state, isA<WeatherLoaded>());
      // между ошибкой и данными НЕ было индикатора загрузки: сообщение не мигало
      expect(seen.where((Type t) => t == WeatherLoading), hasLength(1));
    });

    test('пока связи нет, повторы идут, а сообщение не пропадает', () async {
      final Rig rig = makeRig();
      rig.weather.failure = const ConnectionFailure();

      await rig.controller.search('Paris');
      final int before = rig.weather.requested.length;
      await pause(150);

      expect(rig.weather.requested.length, greaterThan(before)); // повторяли
      expect(rig.controller.state, isA<WeatherFailed>());
    });

    test('новый запрос отменяет ожидающий повтор', () async {
      final Rig rig = makeRig(retryMs: 50);
      rig.weather.failure = const ConnectionFailure();
      await rig.controller.search('Paris');

      rig.weather.failure = null;
      await rig.controller.select(parma); // раньше, чем сработал повтор
      await pause(150);

      expect((rig.controller.state as WeatherLoaded).report.place, parma);
    });

    test('ServerFailure не повторяется сам', () async {
      final Rig rig = makeRig();
      rig.weather.failure = const ServerFailure(statusCode: 500);

      await rig.controller.search('Paris');
      final int before = rig.weather.requested.length;
      await pause(150);

      expect(rig.weather.requested.length, before);
    });

    test('dispose во время ожидания повтора не бросает исключений', () async {
      final Rig rig = Rig(retry: const Duration(milliseconds: 20));
      rig.weather.failure = const ConnectionFailure();
      await rig.controller.search('Paris');

      rig.controller.dispose();
      await pause(100); // таймеры отменены, нового ничего не происходит
    });

    test('потеря связи при геолокации: GPS не опрашивается заново на повторе', () async {
      final Rig rig = makeRig();
      rig.weather.failure = const ConnectionFailure();

      await rig.controller.useCurrentLocation();
      rig.weather.failure = null;
      await pause(120);

      expect(rig.controller.state, isA<WeatherLoaded>());
      expect(rig.location.calls, 1);
    });
  });
}

// Контроллер на подделках из Rig, но с подменённым сервисом погоды.
WeatherController controllerWith(Rig rig, WeatherService weather) =>
    WeatherController(
      location: rig.location,
      geocoding: rig.geocoding,
      reverseGeocoding: rig.reverse,
      weather: weather,
    );

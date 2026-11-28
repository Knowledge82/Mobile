import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';

import '../failures.dart';
import '../models/coordinates.dart';

// «Где мы?» в виде интерфейса: контроллер знает только это, а не пакет geolocator.
// В тестах подставляется подделка (FakeLocationService), на телефоне настоящий GPS.
abstract interface class LocationService {
  // Бросает наследников WeatherFailure (нет разрешения, выключена геолокация...).
  Future<Coordinates> currentCoordinates();
}

final class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService({this.timeout = const Duration(seconds: 15)});

  // Сколько ждать координаты. Без таймаута «вечная» загрузка при плохом приёме.
  final Duration timeout;

  @override
  Future<Coordinates> currentCoordinates() async {
    try {
      // 1. Включена ли геолокация в системе (шторка, «Местоположение»).
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationServiceDisabledFailure();
      }

      // 2. Есть ли разрешение. Если ещё не спрашивали (denied), спрашиваем:
      //    на экране появится системный диалог.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 3. Разбираем ВСЕ варианты ответа (switch по enum обязан быть полным).
      switch (permission) {
        case LocationPermission.denied:
          throw const LocationDeniedFailure();
        case LocationPermission.deniedForever:
          throw const LocationDeniedForeverFailure();
        case LocationPermission.unableToDetermine:
          throw const LocationUnavailableFailure();
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break; // можно получать координаты
      }

      // 4. Сами координаты. Для погоды города хватает низкой точности: быстрее,
      //    экономнее по батарее и работает даже с «примерным» разрешением.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeout,
        ),
      );
      return Coordinates(position.latitude, position.longitude);
    } on WeatherFailure {
      rethrow; // наши собственные, уже готовые
    } on TimeoutException {
      throw const LocationUnavailableFailure();
    } on LocationServiceDisabledException {
      throw const LocationServiceDisabledFailure();
    } on PermissionDeniedException {
      throw const LocationDeniedFailure();
    } on Exception catch (error) {
      // Всё остальное (например, нет записи в AndroidManifest.xml:
      // PermissionDefinitionsNotFoundException). Приложение не падает,
      // а причина остаётся в логе для разработчика.
      debugPrint('Geolocation failed: $error');
      throw const LocationUnavailableFailure();
    }
  }
}

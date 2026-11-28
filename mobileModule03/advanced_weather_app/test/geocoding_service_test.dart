// Тесты поиска города (Open-Meteo Geocoding) на подставном HTTP-клиенте.
// Сети нет: MockClient получает запрос и возвращает заранее приготовленный ответ.
//
// ВАЖНО: тесты не запускались (см. docs/02-ex01.md).

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:advanced_weather_app/failures.dart';
import 'package:advanced_weather_app/models/place.dart';
import 'package:advanced_weather_app/services/geocoding_service.dart';

// Ответ в UTF-8 с правильным заголовком, как у настоящего сервера.
http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('разбирает список мест: название, регион, страна, координаты', () async {
    final service = OpenMeteoGeocodingService(
      MockClient(
        (_) async => jsonResponse({
          'results': [
            {
              'id': 2988507,
              'name': 'Paris',
              'latitude': 48.85341,
              'longitude': 2.3488,
              'country': 'France',
              'admin1': 'Île-de-France',
            },
            {
              // нет admin1, а координаты целые числа
              'id': 4717560,
              'name': 'Paris',
              'latitude': 33,
              'longitude': -95,
              'country': 'United States',
            },
          ],
        }),
      ),
    );

    final List<Place> places = await service.search('Paris');

    expect(places, hasLength(2));
    expect(places[0].name, 'Paris');
    expect(places[0].region, 'Île-de-France'); // UTF-8 не испорчен
    expect(places[0].country, 'France');
    expect(places[0].coordinates.latitude, 48.85341);
    expect(places[1].region, isNull);
    expect(places[1].subtitle, 'United States');
    expect(places[1].coordinates.latitude, 33.0);
  });

  test('строит правильный запрос и экранирует название', () async {
    late Uri url;
    final service = OpenMeteoGeocodingService(
      MockClient((http.Request request) async {
        url = request.url;
        return jsonResponse({});
      }),
    );

    await service.search('São Paulo, Brazil', count: 3);

    expect(url.host, 'geocoding-api.open-meteo.com');
    expect(url.path, '/v1/search');
    expect(url.queryParameters['name'], 'São Paulo, Brazil');
    expect(url.queryParameters['count'], '3');
    expect(url.queryParameters['language'], 'en');
  });

  test('нет ключа results: пустой список', () async {
    final service = OpenMeteoGeocodingService(
      MockClient((_) async => jsonResponse({'generationtime_ms': 0.5})),
    );

    expect(await service.search('Atlantis'), isEmpty);
  });

  test('400 (недопустимое название): тоже «ничего не найдено»', () async {
    final service = OpenMeteoGeocodingService(
      MockClient(
        (_) async => jsonResponse({'error': true, 'reason': 'bad name'}, 400),
      ),
    );

    expect(await service.search('x' * 500), isEmpty);
  });

  test('500: ServerFailure с кодом', () async {
    final service = OpenMeteoGeocodingService(
      MockClient((_) async => jsonResponse({}, 500)),
    );

    await expectLater(
      service.search('Paris'),
      throwsA(isA<ServerFailure>().having((f) => f.statusCode, 'код', 500)),
    );
  });

  test('нет сети (ClientException): ConnectionFailure', () async {
    final service = OpenMeteoGeocodingService(
      MockClient((_) async => throw http.ClientException('no network')),
    );

    await expectLater(
      service.search('Paris'),
      throwsA(isA<ConnectionFailure>()),
    );
  });

  test('таймаут: ConnectionFailure', () async {
    final service = OpenMeteoGeocodingService(
      MockClient((_) async => throw TimeoutException('too slow')),
    );

    await expectLater(
      service.search('Paris'),
      throwsA(isA<ConnectionFailure>()),
    );
  });

  test('не JSON: ServerFailure', () async {
    final service = OpenMeteoGeocodingService(
      MockClient((_) async => http.Response('<html>oops</html>', 200)),
    );

    await expectLater(service.search('Paris'), throwsA(isA<ServerFailure>()));
  });

  test('JSON не той формы: ServerFailure', () async {
    final service = OpenMeteoGeocodingService(
      MockClient(
        (_) async => jsonResponse({
          'results': [
            {'name': 42, 'latitude': 'north', 'longitude': 2},
          ],
        }),
      ),
    );

    await expectLater(service.search('Paris'), throwsA(isA<ServerFailure>()));
  });
}

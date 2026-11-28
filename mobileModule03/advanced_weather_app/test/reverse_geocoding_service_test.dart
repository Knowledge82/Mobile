// Тесты «координаты => место» (BigDataCloud) на подставном HTTP-клиенте.
//
// ВАЖНО: тесты не запускались (см. docs/02-ex01.md).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:advanced_weather_app/failures.dart';
import 'package:advanced_weather_app/models/coordinates.dart';
import 'package:advanced_weather_app/services/reverse_geocoding_service.dart';

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const Coordinates here = Coordinates(41.3874, 2.1686);

void main() {
  test('город, регион, страна', () async {
    late Uri url;
    final service = BigDataCloudReverseGeocodingService(
      MockClient((http.Request request) async {
        url = request.url;
        return jsonResponse({
          'city': 'Barcelona',
          'locality': 'Ciutat Vella',
          'principalSubdivision': 'Catalonia',
          'countryName': 'Spain',
        });
      }),
    );

    final place = await service.lookup(here);

    expect(place.name, 'Barcelona');
    expect(place.region, 'Catalonia');
    expect(place.country, 'Spain');
    expect(place.coordinates, here);
    expect(url.host, 'api.bigdatacloud.net');
    expect(url.path, '/data/reverse-geocode-client');
    expect(url.queryParameters['latitude'], '41.3874');
    expect(url.queryParameters['longitude'], '2.1686');
  });

  test('city пустой: берём locality', () async {
    final service = BigDataCloudReverseGeocodingService(
      MockClient(
        (_) async => jsonResponse({
          'city': '',
          'locality': 'Ciutat Vella',
          'principalSubdivision': 'Catalonia',
          'countryName': 'Spain',
        }),
      ),
    );

    expect((await service.lookup(here)).name, 'Ciutat Vella');
  });

  test('нет ни city, ни locality: ServerFailure (контроллер подставит координаты)', () async {
    final service = BigDataCloudReverseGeocodingService(
      MockClient(
        (_) async => jsonResponse({'city': '', 'locality': '', 'countryName': 'X'}),
      ),
    );

    await expectLater(service.lookup(here), throwsA(isA<ServerFailure>()));
  });

  test('402 (бан по IP у этого сервиса): ServerFailure', () async {
    final service = BigDataCloudReverseGeocodingService(
      MockClient((_) async => jsonResponse({}, 402)),
    );

    await expectLater(service.lookup(here), throwsA(isA<ServerFailure>()));
  });

  test('нет сети: ConnectionFailure', () async {
    final service = BigDataCloudReverseGeocodingService(
      MockClient((_) async => throw http.ClientException('no network')),
    );

    await expectLater(service.lookup(here), throwsA(isA<ConnectionFailure>()));
  });
}

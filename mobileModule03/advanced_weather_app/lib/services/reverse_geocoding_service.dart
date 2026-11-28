import 'package:http/http.dart' as http;

import '../failures.dart';
import '../models/coordinates.dart';
import '../models/place.dart';
import 'http_json.dart';

// «Координаты => место»: какой это город.
// У Open-Meteo такого запроса НЕТ (их геокодер ищет только по названию),
// поэтому берём отдельный сервис.
abstract interface class ReverseGeocodingService {
  Future<Place> lookup(Coordinates coordinates);
}

// BigDataCloud, бесплатный «client-side» запрос без ключа:
// https://www.bigdatacloud.com/docs/api/free-reverse-geocode-to-city-api
// Условия: вызывать надо с устройства пользователя для ЕГО текущего места
// (ровно наш случай), не с сервера и не пакетами.
final class BigDataCloudReverseGeocodingService
    implements ReverseGeocodingService {
  BigDataCloudReverseGeocodingService(this._client);

  final http.Client _client;

  @override
  Future<Place> lookup(Coordinates coordinates) async {
    final Uri uri = Uri.https(
      'api.bigdatacloud.net',
      '/data/reverse-geocode-client',
      {
        'latitude': '${coordinates.latitude}',
        'longitude': '${coordinates.longitude}',
        'localityLanguage': 'en',
      },
    );

    final Map<String, dynamic> json = await getJson(_client, uri);

    return parseResponse(() {
      // city бывает пустой строкой (не null!), тогда берём locality.
      final String name = _firstNotEmpty(json['city'], json['locality']);
      if (name.isEmpty) {
        throw const FormatException('no city name'); // станет ServerFailure
      }
      return Place(
        name: name,
        region: _firstNotEmpty(json['principalSubdivision']),
        country: _firstNotEmpty(json['countryName']),
        coordinates: coordinates,
      );
    });
  }

  // Первая непустая строка из кандидатов, иначе ''.
  String _firstNotEmpty(Object? a, [Object? b]) {
    for (final Object? value in [a, b]) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}

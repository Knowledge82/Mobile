import 'package:http/http.dart' as http;

import '../failures.dart';
import '../models/coordinates.dart';
import '../models/place.dart';
import 'http_json.dart';

// «Название => места»: поиск города по тексту.
abstract interface class GeocodingService {
  // Возвращает до [count] подходящих мест (пустой список = ничего не нашлось).
  // Бросает ConnectionFailure или ServerFailure.
  Future<List<Place>> search(String query, {int count = 5});
}

// Geocoding API от Open-Meteo: https://open-meteo.com/en/docs/geocoding-api
final class OpenMeteoGeocodingService implements GeocodingService {
  OpenMeteoGeocodingService(this._client);

  final http.Client _client;

  @override
  Future<List<Place>> search(String query, {int count = 5}) async {
    // Uri.https сам экранирует параметры: «São Paulo, Brazil» уйдёт как надо.
    final Uri uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '$count',
      'language': 'en',
      'format': 'json',
    });

    final Map<String, dynamic> json;
    try {
      json = await getJson(_client, uri);
    } on ServerFailure catch (failure) {
      // 400 здесь значит «эти параметры недопустимы» (например, слишком
      // длинное название). Для пользователя это «такого города нет».
      if (failure.statusCode == 400) {
        return const [];
      }
      rethrow;
    }

    // Если ничего не найдено, ключа `results` в ответе просто нет.
    final Object? results = json['results'];
    if (results == null) {
      return const [];
    }

    return parseResponse(
      () => [
        for (final Object? item in results as List<Object?>)
          _placeFrom(item as Map<String, dynamic>),
      ],
    );
  }

  Place _placeFrom(Map<String, dynamic> json) => Place(
    name: json['name'] as String,
    region: json['admin1'] as String?,
    country: json['country'] as String?,
    coordinates: Coordinates(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    ),
  );
}

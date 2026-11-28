// Пара «широта, долгота» в градусах (система WGS84, как у GPS и у Open-Meteo).
//
// Свой маленький класс вместо Position из geolocator: так вся остальная
// программа не зависит от пакета геолокации (и тесты работают без него).
class Coordinates {
  const Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  // «41.3874, 2.1686»: 4 знака после запятой это примерно 10 метров, для города с головой.
  @override
  String toString() =>
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  // Равенство по значению: нужно тестам (expect(a, b)) и сравнению состояний.
  @override
  bool operator ==(Object other) =>
      other is Coordinates &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

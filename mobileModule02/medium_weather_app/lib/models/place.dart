import 'coordinates.dart';

// Место на карте: то, что пользователь видит как «город, регион, страна».
class Place {
  const Place({
    required this.name,
    required this.coordinates,
    this.region,
    this.country,
  });

  // Место, про которое известны только координаты (обратный геокодер не ответил).
  // Погоду по координатам получить всё равно можно, а на экране будет «41.3874, 2.1686».
  factory Place.atCoordinates(Coordinates coordinates) =>
      Place(name: coordinates.toString(), coordinates: coordinates);

  final String name;
  final String? region; // admin1 у Open-Meteo: область, провинция, штат...
  final String? country;
  final Coordinates coordinates;

  // «Île-de-France, France»: всё, что есть, кроме названия. Пусто, если ничего нет.
  String get subtitle => [
    if (region != null && region!.isNotEmpty) region!,
    if (country != null && country!.isNotEmpty) country!,
  ].join(', ');

  @override
  String toString() => subtitle.isEmpty ? name : '$name, $subtitle';
}

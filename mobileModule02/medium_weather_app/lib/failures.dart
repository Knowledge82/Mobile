// Всё, что может пойти не так, как ТИПЫ (а не как «строка с ошибкой»).
//
// sealed: список вариантов закрыт, поэтому любой switch по WeatherFailure
// компилятор заставит довести до конца. Забыть показать новую ошибку нельзя.
//
// `implements Exception`: это именно исключения, их бросают (throw) сервисы,
// а ловит контроллер. До интерфейса они доходят уже как данные (WeatherFailed).
sealed class WeatherFailure implements Exception {
  const WeatherFailure();

  // Текст для пользователя (английский: язык интерфейса приложения).
  String get message;
}

// --- геолокация ---

// Пользователь нажал «Запретить» (можно спросить ещё раз).
final class LocationDeniedFailure extends WeatherFailure {
  const LocationDeniedFailure();

  @override
  String get message =>
      'No access to your location: permission was denied. '
      'Enter a city name in the search bar to get the weather.';
}

// «Больше не спрашивать» (или запрет через настройки): системный диалог уже не появится.
final class LocationDeniedForeverFailure extends WeatherFailure {
  const LocationDeniedForeverFailure();

  @override
  String get message =>
      'No access to your location: permission is blocked. '
      'Allow it in the app settings or enter a city name in the search bar.';
}

// В шторке выключена геолокация.
final class LocationServiceDisabledFailure extends WeatherFailure {
  const LocationServiceDisabledFailure();

  @override
  String get message =>
      'Location services are turned off on this device. '
      'Turn them on or enter a city name in the search bar.';
}

// Не смогли определить место: таймаут, нет спутников, странная ошибка плагина.
final class LocationUnavailableFailure extends WeatherFailure {
  const LocationUnavailableFailure();

  @override
  String get message =>
      'Could not determine your location. '
      'Try the geolocation button again or enter a city name.';
}

// --- поиск и сеть ---

// Такого города нет (сервис вернул пустой список).
final class CityNotFoundFailure extends WeatherFailure {
  const CityNotFoundFailure(this.query);

  final String query;

  @override
  String get message =>
      'City "$query" was not found. Check the name and try again.';
}

// Нет связи с сервером: нет интернета, таймаут, обрыв.
final class ConnectionFailure extends WeatherFailure {
  const ConnectionFailure();

  @override
  String get message =>
      'Connection problem: the weather service is unreachable. '
      'Check your internet connection (retrying automatically).';
}

// Сервер ответил, но не то, что мы ждали: код не 200 или непонятный JSON.
final class ServerFailure extends WeatherFailure {
  const ServerFailure({this.statusCode});

  final int? statusCode;

  @override
  String get message =>
      'The weather service returned an unexpected answer. '
      'Please try again later.';
}

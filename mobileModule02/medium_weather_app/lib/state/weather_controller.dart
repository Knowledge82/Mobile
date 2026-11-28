import 'dart:async';

import 'package:flutter/foundation.dart';

import '../failures.dart';
import '../models/coordinates.dart';
import '../models/place.dart';
import '../models/weather_report.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/reverse_geocoding_service.dart';
import '../services/weather_service.dart';
import 'weather_state.dart';

// «Мозг» приложения: хранит состояние (что показывать и какие есть подсказки),
// умеет четыре действия (геолокация, поиск по тексту, выбор подсказки,
// набор текста) и сообщает экрану об изменениях (ChangeNotifier).
//
// Виджеты ничего не знают про сеть и GPS: они зовут методы и перерисовываются.
class WeatherController extends ChangeNotifier {
  WeatherController({
    required LocationService location,
    required GeocodingService geocoding,
    required ReverseGeocodingService reverseGeocoding,
    required WeatherService weather,
    this.suggestDebounce = const Duration(milliseconds: 300),
    this.retryInterval = const Duration(seconds: 10),
  }) : _location = location,
       _geocoding = geocoding,
       _reverse = reverseGeocoding,
       _weather = weather;

  final LocationService _location;
  final GeocodingService _geocoding;
  final ReverseGeocodingService _reverse;
  final WeatherService _weather;

  // Пауза после последнего символа, прежде чем идти за подсказками.
  final Duration suggestDebounce;

  // Через сколько повторять запрос после потери связи.
  final Duration retryInterval;

  // ---------------------------------------------------------------- состояние

  WeatherState _state = const WeatherIdle();
  WeatherState get state => _state;

  List<Place> _suggestions = const [];
  List<Place> get suggestions => _suggestions;

  // «Номерки» запросов: ответ принимается, только если номерок ещё последний.
  // Так медленный старый ответ не затрёт новый (гонка запросов).
  int _requestId = 0;
  int _suggestId = 0;

  Timer? _retryTimer;
  Timer? _debounceTimer;
  bool _disposed = false;

  // ----------------------------------------------------------------- действия

  // Погода по GPS. Зовётся при старте и по кнопке геолокации.
  Future<void> useCurrentLocation() {
    _clearSuggestions();
    Coordinates? known; // запомним координаты, чтобы при повторе не просить GPS заново
    return _run(() async {
      final Coordinates coordinates = known ??= await _location.currentCoordinates();
      final Place place = await _placeAt(coordinates);
      return _weather.fetch(place);
    });
  }

  // Поиск «без выбора из списка»: берём первое, что нашёл геокодер.
  Future<void> search(String text) {
    final String query = text.trim();
    _clearSuggestions();
    if (query.isEmpty) {
      return Future.value(); // пустой запрос игнорируем: экран остаётся как был
    }
    return _run(() async {
      final List<Place> found = await _geocoding.search(query, count: 1);
      if (found.isEmpty) {
        throw CityNotFoundFailure(query);
      }
      return _weather.fetch(found.first);
    });
  }

  // Пользователь выбрал город из списка подсказок.
  Future<void> select(Place place) {
    _clearSuggestions();
    return _run(() => _weather.fetch(place));
  }

  // Пользователь печатает: обновляем подсказки (с задержкой, см. suggestDebounce).
  void queryChanged(String text) {
    _debounceTimer?.cancel();
    final String query = text.trim();
    final int id = ++_suggestId;

    // Геокодер на 0 и 1 символ ничего не возвращает: не тратим запросы.
    if (query.length < 2) {
      _setSuggestions(const []);
      return;
    }
    _debounceTimer = Timer(suggestDebounce, () => _loadSuggestions(query, id));
  }

  // --------------------------------------------------------------- внутренняя кухня

  // Единая «обвязка» любого запроса погоды: загрузка, результат, ошибка, повтор.
  Future<void> _run(Future<WeatherReport> Function() job, {bool silent = false}) async {
    final int id = ++_requestId; // новый запрос обесценивает все старые
    _retryTimer?.cancel();
    if (!silent) {
      _emit(const WeatherLoading());
    }

    try {
      final WeatherReport report = await job();
      if (id != _requestId) return; // пока ждали, началось что-то новее
      _emit(WeatherLoaded(report));
    } on WeatherFailure catch (failure) {
      if (id != _requestId) return;
      _emit(WeatherFailed(failure));
      // Потеряли связь: сообщение остаётся на экране, а мы тихо пробуем снова.
      // Как только получится, _emit(WeatherLoaded) заменит сообщение данными.
      if (failure is ConnectionFailure && !_disposed) {
        _retryTimer = Timer(retryInterval, () => _run(job, silent: true));
      }
    } on Object catch (error, stack) {
      // Страховка: непредвиденная ошибка не должна оставить экран в вечной загрузке.
      debugPrint('Unexpected error: $error\n$stack');
      if (id != _requestId) return;
      _emit(const WeatherFailed(ServerFailure()));
    }
  }

  // Название места по координатам. Если геокодер «поломался», не страшно:
  // погоду можно получить и по координатам, а показать их цифрами.
  // А вот потеря связи (ConnectionFailure) пробрасывается дальше: повторим всё.
  Future<Place> _placeAt(Coordinates coordinates) async {
    try {
      return await _reverse.lookup(coordinates);
    } on ServerFailure {
      return Place.atCoordinates(coordinates);
    }
  }

  Future<void> _loadSuggestions(String query, int id) async {
    try {
      final List<Place> found = await _geocoding.search(query, count: 5);
      if (id != _suggestId) return; // устарело: пользователь уже напечатал дальше
      _setSuggestions(found);
    } on WeatherFailure {
      // Подсказки это удобство, а не функция: при ошибке просто прячем список.
      // Сообщение об ошибке пользователь увидит при самом поиске.
      if (id != _suggestId) return;
      _setSuggestions(const []);
    }
  }

  void _clearSuggestions() {
    _debounceTimer?.cancel();
    _suggestId++; // обесценить уже летящие запросы подсказок
    _setSuggestions(const []);
  }

  void _setSuggestions(List<Place> places) {
    if (_suggestions.isEmpty && places.isEmpty) return; // менять нечего
    _suggestions = places;
    _notify();
  }

  void _emit(WeatherState state) {
    _state = state;
    _notify();
  }

  // После dispose() notifyListeners() бросает ошибку, а ответы из сети
  // могут прийти позже. Поэтому всё, что рассылает изменения, идёт через этот метод.
  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

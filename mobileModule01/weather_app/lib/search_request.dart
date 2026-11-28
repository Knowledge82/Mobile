// «Что именно искали»: либо текст из поля, либо геолокация.
//
// sealed (Dart 3): наследники известны компилятору только из этого файла,
// поэтому switch по SearchRequest обязан разобрать ВСЕ случаи. Появится
// третий вариант (например, выбор города из списка) — компилятор сам покажет
// все места, которые надо дополнить.
sealed class SearchRequest {
  const SearchRequest();

  // Что показываем на вкладках. switch-выражение: каждая ветка — значение.
  String get label => switch (this) {
    TextSearch(:final query) => query,
    GeolocationSearch() => 'Geolocation',
  };
}

// Поиск по тексту. query уже обрезан по краям и не пуст (см. SearchAppBar).
final class TextSearch extends SearchRequest {
  const TextSearch(this.query);

  final String query;
}

// Поиск по геолокации. Данных пока нет: координаты появятся в модуле 02.
final class GeolocationSearch extends SearchRequest {
  const GeolocationSearch();
}

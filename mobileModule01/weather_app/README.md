# weather_app

Погодное приложение (Piscine Mobile, модуль 01: «Structure and Logic»).
Это один проект на два упражнения: ex00 (нижняя панель вкладок) и ex01
(верхняя панель: поиск и геолокация). В репозитории лежит состояние после ex01.

- Разбор по слоям: [docs/01-ex00.md](../../docs/01-ex00.md) и [docs/01-ex01.md](../../docs/01-ex01.md).
- Платформенные папки (`android/`, `web/` и т. д.) создаёт `flutter create`, подробности в разборе ex00, раздел 6.

## Файлы

| Файл | Что внутри |
|---|---|
| `lib/main.dart` | `main`, `WeatherApp` (MaterialApp, тема) |
| `lib/home_page.dart` | `HomePage`: состояние «что искали», каркас Scaffold, вкладки |
| `lib/search_app_bar.dart` | `SearchAppBar`: поле поиска + кнопка геолокации |
| `lib/tab_page.dart` | `TabPage`: содержимое вкладки |
| `lib/weather_tab.dart` | `WeatherTab`: enum вкладок (название, иконка) |
| `lib/search_request.dart` | `SearchRequest`: sealed-класс «текст или геолокация» |
| `test/widget_test.dart` | виджет-тесты |

## Запуск

    flutter pub get
    flutter analyze
    flutter test
    flutter run

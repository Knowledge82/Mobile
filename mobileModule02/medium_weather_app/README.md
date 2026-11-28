# medium_weather_app

Погодное приложение с настоящими данными (Piscine Mobile, модуль 02: «API and Data Management»).
Один проект на четыре упражнения: ex00 (геолокация по GPS), ex01 (поиск города и подсказки),
ex02 (данные на вкладках), ex03 (ошибки). В репозитории лежит состояние после ex03.

Проект продолжает [weather_app](../../mobileModule01/weather_app) из модуля 01 (по сабжу его
копируют в новый проект).

- Разбор по слоям: [ex00](../../docs/02-ex00.md), [ex01](../../docs/02-ex01.md),
  [ex02](../../docs/02-ex02.md), [ex03](../../docs/02-ex03.md).
- Платформенные папки (`android/`, `web/`), разрешения Android и скрипт для них: в разборе ex00, раздел 6.

## Устройство

    lib/
      main.dart                 сборка: настоящие сервисы -> контроллер -> экран
      failures.dart             все ошибки как sealed-класс (с текстами для пользователя)
      models/                   Coordinates, Place, WeatherReport, коды погоды
      services/                 GPS, геокодер, обратный геокодер, прогноз (интерфейс + реализация)
      state/                    WeatherState (sealed) и WeatherController (ChangeNotifier)
      ui/                       экраны и виджеты
    test/                       сервисы на MockClient, контроллер на подделках, виджет-тесты

## Запуск

    flutter pub get
    flutter analyze
    flutter test
    flutter run -d <устройство>

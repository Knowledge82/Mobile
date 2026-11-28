# advanced_weather_app

Погодное приложение с оформлением (Piscine Mobile, модуль 03: «Design»).
Один проект на пять упражнений: ex00 (строка поиска), ex01 (фон), ex02 (вкладка Currently),
ex03 (вкладка Today с графиком), ex04 (вкладка Weekly с графиком). В репозитории лежит
состояние после ex04.

Проект продолжает [medium_weather_app](../../mobileModule02/medium_weather_app) из модуля 02
(по сабжу его копируют в новую папку). Логика (GPS, поиск, прогноз, ошибки) осталась прежней;
изменилось оформление и добавились иконки, графики и дни недели.

- Разбор по слоям: [ex00](../../docs/03-ex00.md), [ex01](../../docs/03-ex01.md),
  [ex02](../../docs/03-ex02.md), [ex03](../../docs/03-ex03.md), [ex04](../../docs/03-ex04.md).
- Платформенные папки (`android/`, `web/`), разрешения Android и скрипт для них: в разборе
  [02-ex00](../../docs/02-ex00.md), раздел 6 (те же шаги, только имя проекта другое).

## Что нового по сравнению с модулем 02

    lib/
      config.dart               maxSuggestions = 5 (одно место для «не больше 5 подсказок»)
      ui/
        app_background.dart     фон: ОДИН раз, в MaterialApp.builder, под всеми экранами
        glass_card.dart         полупрозрачная тёмная плашка («стекло») для читаемости
        weather_icon.dart       код погоды WMO (+ день/ночь) -> иконка и её цвет
        line_chart.dart         свой линейный график (CustomPainter), 1 или 2 кривые
        chart_math.dart         арифметика графика (красивые деления оси, подписи, координаты)
        chart_list_page.dart    каркас Today/Weekly: шапка + график + прокручиваемый список
        search_app_bar.dart     яркое поле, крестик, заметная кнопка геолокации
        suggestions_list.dart   подсказки: белая карточка, до 5 штук
        current_view.dart / today_view.dart / weekly_view.dart   вкладки
    assets/images/background.jpg  фон (сгенерирован скриптом tools/make_background.py)

## Запуск

    flutter pub get
    flutter analyze
    flutter test
    flutter run -d <устройство>

Красоту автоматически проверить нельзя: после `flutter test` обязательно посмотрите приложение
глазами на телефоне (список проверок есть в каждом разборе, раздел «Запуск и проверка»).

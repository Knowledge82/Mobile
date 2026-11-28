// Тесты оформления модуля 03 по упражнениям: что именно требует сабж и как
// это можно проверить без глаз (наличие, количество, положение, прокрутка).
// Красоту тестом не проверить: см. «ручную проверку» в docs/03-ex0*.md.
//
// ВАЖНО: тесты не запускались (см. docs/03-ex00.md ... docs/03-ex04.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_weather_app/config.dart';
import 'package:advanced_weather_app/models/coordinates.dart';
import 'package:advanced_weather_app/models/place.dart';
import 'package:advanced_weather_app/models/weather_report.dart';
import 'package:advanced_weather_app/ui/app_background.dart';
import 'package:advanced_weather_app/ui/line_chart.dart';
import 'package:advanced_weather_app/ui/suggestions_list.dart';
import 'package:advanced_weather_app/ui/today_view.dart';
import 'package:advanced_weather_app/ui/weekly_view.dart';

import 'fakes.dart';
import 'helpers.dart';

// Размер окна в логических пикселях (devicePixelRatio = 1).
void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Finder onPage(Finder finder) => find.descendant(of: find.byType(TabBarView), matching: finder);

Future<void> openTab(WidgetTester tester, String title) async {
  await tester.tap(barTab(title));
  await tester.pumpAndSettle();
}

void main() {
  group('ex00: строка поиска', () {
    testWidgets('понятно, что здесь ищут: подсказка в поле и значок лупы', (tester) async {
      await pumpApp(tester);

      expect(find.text('Search for a city...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('поле заметное: белое и непрозрачное почти полностью', (tester) async {
      await pumpApp(tester);

      final TextField field = tester.widget(find.byType(TextField));
      final Color? fill = field.decoration?.fillColor;
      expect(field.decoration?.filled, isTrue);
      expect(fill, isNotNull);
      expect(fill!.a, greaterThan(0.9)); // почти без прозрачности: контраст на любом фоне
    });

    testWidgets('кнопка геолокации видна, подписана и достаточно крупная', (tester) async {
      await pumpApp(tester);

      final Finder button = find.byTooltip('Use my location');
      expect(button, findsOneWidget);
      final Size size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(40)); // нажимать пальцем
      expect(size.height, greaterThanOrEqualTo(40));
    });

    testWidgets('крестик есть только когда есть текст и стирает его вместе с подсказками', (tester) async {
      await pumpApp(tester);
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.enterText(find.byType(TextField), 'Par');
      await settle(tester, const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byType(SuggestionsList), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await settle(tester);

      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(find.byType(SuggestionsList), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('подсказок не больше пяти, даже если городов гораздо больше', (tester) async {
      final Rig rig = Rig(cities: springfields); // 8 городов «Springfield N»
      await pumpApp(tester, rig: rig);

      await tester.enterText(find.byType(TextField), 'Spring');
      await settle(tester, const Duration(milliseconds: 400));

      final Finder rows = find.descendant(
        of: find.byType(SuggestionsList),
        matching: find.byType(ListTile),
      );
      expect(rows, findsNWidgets(maxSuggestions));
    });

    testWidgets('название города в подсказке жирнее региона и страны', (tester) async {
      await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'Par');
      await settle(tester, const Duration(milliseconds: 400));

      final Text name = tester.widget(find.text('Paris'));
      final Text subtitle = tester.widget(find.text('Île-de-France, France'));
      expect(name.style?.fontWeight, FontWeight.w700);
      expect(subtitle.style?.fontWeight, isNot(FontWeight.w700));
      expect(name.style!.fontSize!, greaterThan(subtitle.style?.fontSize ?? 14));
    });
  });

  group('ex01: фон', () {
    testWidgets('фон один на всё приложение и это картинка из assets', (tester) async {
      await pumpApp(tester);

      expect(find.byType(AppBackground), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      final Image image = tester.widget(find.byType(Image));
      expect((image.image as AssetImage).assetName, backgroundAsset);
    });

    testWidgets('фон закрывает весь экран', (tester) async {
      setScreen(tester, const Size(390, 844));
      await pumpApp(tester);

      expect(tester.getSize(find.byType(AppBackground)), const Size(390, 844));
      expect(tester.getSize(find.byType(Image)), const Size(390, 844));
      final Image image = tester.widget(find.byType(Image));
      expect(image.fit, BoxFit.cover);
    });

    testWidgets('интерфейс лежит ПОВЕРХ фона, а сам Scaffold прозрачный', (tester) async {
      await pumpApp(tester);

      expect(
        find.descendant(of: find.byType(AppBackground), matching: find.byType(Scaffold)),
        findsOneWidget,
      );
      final Scaffold scaffold = tester.widget(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.transparent);
    });

    testWidgets('при переключении вкладок фон тот же самый (не пересоздаётся)', (tester) async {
      await pumpApp(tester);
      final Element before = tester.element(find.byType(AppBackground));
      final Element imageBefore = tester.element(find.byType(Image));

      for (final String title in ['Today', 'Weekly', 'Currently']) {
        await openTab(tester, title);
        expect(find.byType(AppBackground), findsOneWidget);
        expect(find.byType(Image), findsOneWidget); // не дублируется
        expect(identical(tester.element(find.byType(AppBackground)), before), isTrue);
        expect(identical(tester.element(find.byType(Image)), imageBefore), isTrue);
      }
    });

    testWidgets('фон переживает и поиск, и ошибку', (tester) async {
      await pumpApp(tester);
      final Element before = tester.element(find.byType(AppBackground));

      await typeAndSubmit(tester, 'Paris');
      await typeAndSubmit(tester, 'Atlantis'); // нет такого города: сообщение об ошибке

      expect(find.byType(Image), findsOneWidget);
      expect(identical(tester.element(find.byType(AppBackground)), before), isTrue);
    });
  });

  group('ex02: Currently', () {
    testWidgets('вся информация сразу на экране без прокрутки', (tester) async {
      setScreen(tester, const Size(390, 844));
      await pumpApp(tester);

      final Rect screen = const Offset(0, 0) & const Size(390, 844);
      for (final Finder finder in [
        onPage(find.text('Barcelona')), // город
        onPage(find.text('Catalonia, Spain')), // регион и страна
        onPage(find.byIcon(Icons.wb_cloudy)), // иконка погоды (код 2)
        onPage(find.text('12.3°C')), // температура
        onPage(find.text('Partly cloudy')), // описание
        onPage(find.text('Wind: 10.5 km/h')), // ветер
      ]) {
        expect(finder, findsOneWidget);
        expect(screen.contains(tester.getCenter(finder)), isTrue);
      }
    });

    testWidgets('иерархия: температура крупнее описания, описание крупнее ветра', (tester) async {
      await pumpApp(tester);

      double size(String text) =>
          tester.widget<Text>(onPage(find.text(text))).style!.fontSize!;
      expect(size('12.3°C'), greaterThan(size('Partly cloudy')));
      expect(size('Partly cloudy'), greaterThan(size('Wind: 10.5 km/h')));
    });

    testWidgets('ночью вместо солнца луна', (tester) async {
      final Rig rig = Rig();
      rig.weather.reportBuilder = (place) => WeatherReport(
        place: place,
        current: const CurrentWeather(temperature: -3, weatherCode: 0, windSpeed: 5, isDay: false),
        hourly: const [],
        daily: const [],
      );
      await pumpApp(tester, rig: rig);

      expect(onPage(find.byIcon(Icons.nights_stay)), findsOneWidget);
      expect(onPage(find.byIcon(Icons.wb_sunny)), findsNothing);
      expect(onPage(find.text('-3.0°C')), findsOneWidget);
    });

    testWidgets('места нет в регионе и стране: показываем только название', (tester) async {
      final Rig rig = Rig();
      rig.reverse.result = const Place(name: 'Nowhere', coordinates: Coordinates(0, 0));
      await pumpApp(tester, rig: rig);

      expect(onPage(find.text('Nowhere')), findsOneWidget);
    });
  });

  group('ex03: Today', () {
    testWidgets('график температуры за день: одна кривая, 24 часа, подписи часов', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Today');

      final LineChart chart = tester.widget(onPage(find.byType(LineChart)));
      expect(chart.series, hasLength(1));
      expect(chart.series.single.values, hasLength(24));
      expect(chart.series.single.values.first, 5.0);
      expect(chart.xLabels.first, '00:00');
      expect(chart.xLabels.last, '23:00');
      expect(chart.formatY(12.4), '12°');
    });

    testWidgets('в каждой строке: время, температура, погода (иконка и текст), ветер', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Today');

      expect(onPage(find.text('00:00  Overcast')), findsOneWidget); // время и описание
      expect(onPage(find.text('5.0°C')), findsOneWidget); // температура
      expect(onPage(find.text('Wind: 4.0 km/h')), findsOneWidget); // ветер
      expect(onPage(find.byIcon(Icons.cloud)), findsWidgets); // иконка пасмурно
    });

    testWidgets('высокий экран: график остаётся на месте, прокручивается только список', (tester) async {
      setScreen(tester, const Size(390, 844));
      await pumpApp(tester);
      await openTab(tester, 'Today');

      final Offset chartBefore = tester.getTopLeft(onPage(find.byType(LineChart)));
      final Finder list = find.descendant(of: find.byType(TodayView), matching: find.byType(ListView));
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(onPage(find.byType(LineChart))), chartBefore); // график не уехал
      expect(onPage(find.text('00:00  Overcast')), findsNothing); // первые строки прокручены
    });

    testWidgets('весь день доступен прокруткой: от 00:00 до 23:00', (tester) async {
      setScreen(tester, const Size(390, 844));
      await pumpApp(tester);
      await openTab(tester, 'Today');

      await tester.scrollUntilVisible(
        find.text('23:00  Slight rain'),
        300,
        scrollable: find.descendant(of: find.byType(TodayView), matching: find.byType(Scrollable)),
      );

      expect(find.text('23:00  Slight rain'), findsOneWidget);
    });

    testWidgets('тесное окно (ландшафт): прокручивается всё, и график тоже', (tester) async {
      setScreen(tester, const Size(640, 300));
      await pumpApp(tester);
      await openTab(tester, 'Today');

      final Offset chartBefore = tester.getTopLeft(onPage(find.byType(LineChart)));
      await tester.drag(
        find.descendant(of: find.byType(TodayView), matching: find.byType(ListView)),
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(onPage(find.byType(LineChart))).dy, lessThan(chartBefore.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('нет почасовых данных: экран живой и без ошибок', (tester) async {
      final Rig rig = Rig();
      rig.weather.reportBuilder = (place) => WeatherReport(
        place: place,
        current: const CurrentWeather(temperature: 1, weatherCode: 3, windSpeed: 1),
        hourly: const [],
        daily: const [],
      );
      await pumpApp(tester, rig: rig);
      await openTab(tester, 'Today');

      expect(tester.takeException(), isNull);
      expect(onPage(find.text('Barcelona')), findsOneWidget);
    });
  });

  group('ex04: Weekly', () {
    testWidgets('график с двумя кривыми: максимум и минимум на 7 дней, подписи дней недели', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Weekly');

      final LineChart chart = tester.widget(onPage(find.byType(LineChart)));
      expect(chart.series, hasLength(2));
      expect(chart.series.map((ChartSeries s) => s.label), ['Max', 'Min']);
      expect(chart.series[0].values, [11, 12, 13, 14, 15, 16, 17]); // sampleReport: 11 + d
      expect(chart.series[1].values, [3, 4, 5, 6, 7, 8, 9]); // 3 + d
      expect(chart.xLabels, ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']);
      expect(chart.series[0].color, isNot(chart.series[1].color)); // кривые различимы
    });

    testWidgets('легенда подписывает кривые', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Weekly');

      expect(onPage(find.text('Max')), findsOneWidget);
      expect(onPage(find.text('Min')), findsOneWidget);
    });

    testWidgets('в списке 7 дней недели по порядку, с min, max и погодой', (tester) async {
      setScreen(tester, const Size(390, 844));
      await pumpApp(tester);
      await openTab(tester, 'Weekly');

      final Finder scrollable = find.descendant(
        of: find.byType(WeeklyView),
        matching: find.byType(Scrollable),
      );
      for (final String day in [
        'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      ]) {
        await tester.scrollUntilVisible(find.text(day), 200, scrollable: scrollable);
        expect(find.text(day), findsOneWidget);
      }
      // последняя строка (пятница, d = 6): min 9, max 17, чётный день: ясное небо
      expect(find.text('min 9.0°C\nmax 17.0°C'), findsOneWidget);
      expect(find.text('Clear sky'), findsWidgets);
      expect(find.byIcon(Icons.wb_sunny), findsWidgets);
    });

    testWidgets('высокий экран: график на месте, список прокручивается', (tester) async {
      setScreen(tester, const Size(390, 844));
      await pumpApp(tester);
      await openTab(tester, 'Weekly');

      final Offset chartBefore = tester.getTopLeft(onPage(find.byType(LineChart)));
      await tester.drag(
        find.descendant(of: find.byType(WeeklyView), matching: find.byType(ListView)),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(onPage(find.byType(LineChart))), chartBefore);
    });

    testWidgets('после нового поиска остаёмся на Weekly, график и список новые', (tester) async {
      await pumpApp(tester);
      await openTab(tester, 'Weekly');

      await typeAndSubmit(tester, 'Paris');

      expect(selectedIndex(tester), 2);
      expect(onPage(find.text('Paris')), findsOneWidget);
      expect(onPage(find.byType(LineChart)), findsOneWidget);
    });
  });

  group('все вкладки при разных размерах и крупном шрифте', () {
    const Map<String, Size> sizes = {
      'узкий телефон': Size(320, 480),
      'телефон': Size(390, 844),
      'ландшафт': Size(844, 390),
      'низкий ландшафт': Size(640, 280),
      'планшет': Size(1024, 768),
      'широкий веб': Size(1600, 900),
    };

    sizes.forEach((String name, Size size) {
      testWidgets('$name: без overflow', (tester) async {
        setScreen(tester, size);
        await pumpApp(tester);

        for (final String title in ['Today', 'Weekly', 'Currently']) {
          await openTab(tester, title);
          expect(tester.takeException(), isNull, reason: '$name / $title');
        }
      });
    });

    testWidgets('крупный шрифт ×2 на телефоне', (tester) async {
      setScreen(tester, const Size(360, 640));
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpApp(tester);

      for (final String title in ['Today', 'Weekly', 'Currently']) {
        await openTab(tester, title);
        expect(tester.takeException(), isNull, reason: title);
      }
    });
  });
}

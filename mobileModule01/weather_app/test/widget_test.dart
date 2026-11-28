// Тесты weather_app (модуль 01, ex00 + ex01).
//
// ВАЖНО: на момент написания эти тесты не запускались (в среде, где они
// писались, нет Flutter). Первый прогон: `flutter test`. Если какой-то тест
// красный, сначала разберитесь, кто неправ: тест или код. См. docs/01-ex01.md.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:weather_app/main.dart';
import 'package:weather_app/search_request.dart';
import 'package:weather_app/weather_tab.dart';

// Текст именно на странице вкладки (а не в нижней панели, где те же слова).
Finder pageText(String text) => find.descendant(
  of: find.byType(TabBarView),
  matching: find.text(text),
);

// Кнопка вкладки в нижней панели.
Finder barTab(String title) => find.descendant(
  of: find.byType(TabBar),
  matching: find.text(title),
);

// Индекс выбранной вкладки у TabController.
int selectedIndex(WidgetTester tester) =>
    DefaultTabController.of(tester.element(find.byType(TabBarView))).index;

void main() {
  group('модель', () {
    test('label у SearchRequest', () {
      expect(const TextSearch('Paris').label, 'Paris');
      expect(const GeolocationSearch().label, 'Geolocation');
    });

    test('вкладки: три штуки, в нужном порядке и с нужными именами', () {
      expect(
        WeatherTab.values.map((WeatherTab t) => t.title),
        ['Currently', 'Today', 'Weekly'],
      );
    });
  });

  group('ex00: нижняя панель', () {
    testWidgets('на старте выбрана первая вкладка Currently', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      expect(selectedIndex(tester), 0);
      expect(pageText('Currently'), findsOneWidget);
    });

    testWidgets('в панели три вкладки с названиями и иконками', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      expect(find.byType(Tab), findsNWidgets(3));
      for (final WeatherTab tab in WeatherTab.values) {
        expect(barTab(tab.title), findsOneWidget);
        expect(find.byIcon(tab.icon), findsOneWidget);
      }
    });

    testWidgets('нажатие на вкладку меняет страницу', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      await tester.tap(barTab('Today'));
      await tester.pumpAndSettle();
      expect(selectedIndex(tester), 1);
      expect(pageText('Today'), findsOneWidget);

      await tester.tap(barTab('Weekly'));
      await tester.pumpAndSettle();
      expect(selectedIndex(tester), 2);
      expect(pageText('Weekly'), findsOneWidget);
    });

    testWidgets('свайп влево и вправо тоже меняет страницу', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      await tester.fling(find.byType(TabBarView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(selectedIndex(tester), 1);
      expect(pageText('Today'), findsOneWidget);

      await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();
      expect(selectedIndex(tester), 0);
      expect(pageText('Currently'), findsOneWidget);
    });
  });

  group('ex00: мышь (Chrome)', () {
    testWidgets('перетаскивание мышью листает вкладки', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      final TestGesture mouse = await tester.startGesture(
        tester.getCenter(find.byType(TabBarView)),
        kind: PointerDeviceKind.mouse,
      );
      await mouse.moveBy(const Offset(-300, 0));
      await mouse.up();
      await tester.pumpAndSettle();

      expect(selectedIndex(tester), 1);
    });
  });

  group('ex01: верхняя панель', () {
    testWidgets('введённый текст виден на всех вкладках', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      expect(pageText('Currently'), findsOneWidget);
      expect(pageText('Paris'), findsOneWidget);

      await tester.tap(barTab('Today'));
      await tester.pumpAndSettle();
      expect(pageText('Today'), findsOneWidget);
      expect(pageText('Paris'), findsOneWidget);

      await tester.tap(barTab('Weekly'));
      await tester.pumpAndSettle();
      expect(pageText('Weekly'), findsOneWidget);
      expect(pageText('Paris'), findsOneWidget);
    });

    testWidgets('кнопка геолокации показывает Geolocation', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();
      expect(pageText('Currently'), findsOneWidget);
      expect(pageText('Geolocation'), findsOneWidget);

      await tester.tap(barTab('Weekly'));
      await tester.pumpAndSettle();
      expect(pageText('Weekly'), findsOneWidget);
      expect(pageText('Geolocation'), findsOneWidget);
    });

    testWidgets('геолокация очищает поле, новый текст её заменяет', (
      tester,
    ) async {
      await tester.pumpWidget(const WeatherApp());

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pump();

      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(pageText('Paris'), findsNothing);
      expect(pageText('Geolocation'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Rome');
      await tester.pump();
      expect(pageText('Rome'), findsOneWidget);
      expect(pageText('Geolocation'), findsNothing);
    });

    testWidgets('пустое и пробельное поле = ничего не искали', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump();
      expect(pageText('Paris'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(pageText('Paris'), findsNothing);
      expect(pageText('Currently'), findsOneWidget);
    });

    testWidgets('текст обрезается по краям', (tester) async {
      await tester.pumpWidget(const WeatherApp());

      await tester.enterText(find.byType(TextField), '  Paris  ');
      await tester.pump();
      expect(pageText('Paris'), findsOneWidget);
    });
  });

  group('адаптивность: ни одного overflow', () {
    const Map<String, Size> sizes = {
      'узкий телефон': Size(320, 480),
      'телефон': Size(390, 844),
      'телефон в ландшафте': Size(844, 390),
      'низкий ландшафт': Size(640, 280),
      'планшет': Size(1024, 768),
      'широкий веб': Size(1600, 900),
    };

    sizes.forEach((String name, Size size) {
      testWidgets(name, (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const WeatherApp());
        await tester.enterText(find.byType(TextField), 'Saint-Petersburg');
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(pageText('Saint-Petersburg'), findsOneWidget);
      });
    });

    testWidgets('крупный шрифт и очень длинный текст', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(const WeatherApp());
      await tester.enterText(find.byType(TextField), 'Very long name ' * 20);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

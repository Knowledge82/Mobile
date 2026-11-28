// Виджет-тесты всего экрана на подделках сервисов: то, что видит пользователь.
// Время в тестах поддельное: tester.pump(Duration) «перематывает» таймеры.
//
// ВАЖНО: тесты не запускались (см. docs/02-ex0*.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medium_weather_app/failures.dart';
import 'package:medium_weather_app/main.dart';
import 'package:medium_weather_app/ui/suggestions_list.dart';
import 'package:medium_weather_app/ui/today_view.dart';

import 'fakes.dart';

// Текст именно на странице вкладки (а не в нижней панели с теми же словами).
Finder pageText(String text) => find.descendant(
  of: find.byType(TabBarView),
  matching: find.text(text),
);

Finder pageTextContaining(String text) => find.descendant(
  of: find.byType(TabBarView),
  matching: find.textContaining(text),
);

Finder barTab(String title) => find.descendant(
  of: find.byType(TabBar),
  matching: find.text(title),
);

int selectedIndex(WidgetTester tester) =>
    DefaultTabController.of(tester.element(find.byType(TabBarView))).index;

// Дать цепочке async-вызовов дойти до конца и перерисоваться.
Future<void> settle(WidgetTester tester, [Duration time = Duration.zero]) async {
  await tester.pump(time);
  await tester.pump();
}

Future<Rig> pumpApp(WidgetTester tester, {Rig? rig}) async {
  final Rig r = rig ?? Rig();
  addTearDown(r.controller.dispose);
  await tester.pumpWidget(WeatherApp(controller: r.controller));
  await settle(tester);
  return r;
}

Future<void> typeAndSubmit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await settle(tester);
}

void main() {
  group('ex00: геолокация при старте', () {
    testWidgets('GPS разрешён: на Currently видны место и погода', (tester) async {
      await pumpApp(tester);

      expect(selectedIndex(tester), 0);
      expect(pageText('Barcelona'), findsOneWidget);
      expect(pageText('Catalonia, Spain'), findsOneWidget);
      expect(pageText('12.3°C'), findsOneWidget);
      expect(pageText('Partly cloudy'), findsOneWidget);
      expect(pageText('Wind: 10.5 km/h'), findsOneWidget);
    });

    testWidgets('GPS запрещён: приложение живо и сообщает об этом', (tester) async {
      final Rig rig = Rig();
      rig.location.result = const LocationDeniedFailure();
      await pumpApp(tester, rig: rig);

      expect(pageTextContaining('No access to your location'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // поиск доступен
    });

    testWidgets('после отказа можно найти город', (tester) async {
      final Rig rig = Rig();
      rig.location.result = const LocationDeniedFailure();
      await pumpApp(tester, rig: rig);

      await typeAndSubmit(tester, 'Paris');

      expect(pageText('Paris'), findsOneWidget);
      expect(pageTextContaining('No access to your location'), findsNothing);
    });

    testWidgets('кнопка геолокации очищает поле и снова спрашивает GPS', (tester) async {
      final Rig rig = await pumpApp(tester);
      await typeAndSubmit(tester, 'Paris');
      expect(pageText('Paris'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.my_location));
      await settle(tester);

      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(rig.location.calls, 2);
      expect(pageText('Barcelona'), findsOneWidget);
    });
  });

  group('ex01: поиск и подсказки', () {
    testWidgets('набираем Par: появляются подсказки с регионом и страной', (tester) async {
      await pumpApp(tester);

      await tester.enterText(find.byType(TextField), 'Par');
      await settle(tester, const Duration(milliseconds: 400));

      expect(find.byType(SuggestionsList), findsOneWidget);
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('Île-de-France, France'), findsOneWidget);
      expect(find.text('Parma'), findsOneWidget);
      expect(find.text('Emilia-Romagna, Italy'), findsOneWidget);
    });

    testWidgets('выбор подсказки: погода для этого города, поле заполнено, список закрыт', (tester) async {
      final Rig rig = await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'Par');
      await settle(tester, const Duration(milliseconds: 400));

      await tester.tap(find.text('Emilia-Romagna, Italy'));
      await settle(tester);

      expect(find.byType(SuggestionsList), findsNothing);
      expect(pageText('Parma'), findsOneWidget);
      final TextField field = tester.widget(find.byType(TextField));
      expect(field.controller!.text, 'Parma');
      expect(rig.weather.requested.last, parma);
    });

    testWidgets('поиск без выбора из списка (Enter) работает', (tester) async {
      await pumpApp(tester);

      await typeAndSubmit(tester, 'Paris');

      expect(pageText('Paris'), findsOneWidget);
      expect(find.byType(SuggestionsList), findsNothing);
    });
  });

  group('ex02: вкладки', () {
    testWidgets('Today: список по часам с температурой, описанием и ветром', (tester) async {
      await pumpApp(tester);

      await tester.tap(barTab('Today'));
      await tester.pumpAndSettle();

      expect(pageText('Barcelona'), findsOneWidget);
      expect(pageText('00:00  Overcast'), findsOneWidget);
      expect(pageText('5.0°C'), findsOneWidget);
      expect(pageText('Wind: 4.0 km/h'), findsOneWidget);

      // дальше по списку (он прокручивается)
      await tester.scrollUntilVisible(
        find.text('23:00  Slight rain'),
        300,
        scrollable: find.descendant(
          of: find.byType(TodayView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('23:00  Slight rain'), findsOneWidget);
    });

    testWidgets('Weekly: даты, min и max, описание', (tester) async {
      await pumpApp(tester);

      await tester.tap(barTab('Weekly'));
      await tester.pumpAndSettle();

      expect(pageText('2026-11-28'), findsOneWidget);
      expect(pageText('Clear sky'), findsWidgets); // чётные дни: 0, 2, 4, 6
      expect(pageText('min 3.0°C\nmax 11.0°C'), findsOneWidget);
    });

    testWidgets('после поиска остаёмся на той же вкладке, данные новые', (tester) async {
      await pumpApp(tester);
      await tester.tap(barTab('Today'));
      await tester.pumpAndSettle();

      await typeAndSubmit(tester, 'Paris');

      expect(selectedIndex(tester), 1);
      expect(pageText('Paris'), findsOneWidget);
    });

    testWidgets('при переключении вкладок везде данные последнего поиска', (tester) async {
      await pumpApp(tester);
      await typeAndSubmit(tester, 'Paris');

      for (final String title in ['Today', 'Weekly', 'Currently']) {
        await tester.tap(barTab(title));
        await tester.pumpAndSettle();
        expect(pageText('Paris'), findsOneWidget);
      }
    });
  });

  group('ex03: ошибки', () {
    testWidgets('города нет: сообщение висит, пока не введён верный город', (tester) async {
      await pumpApp(tester);

      await typeAndSubmit(tester, 'Atlantis');
      expect(pageTextContaining('"Atlantis" was not found'), findsOneWidget);

      await settle(tester, const Duration(seconds: 60)); // время идёт, сообщение на месте
      expect(pageTextContaining('"Atlantis" was not found'), findsOneWidget);

      // сообщение видно и на других вкладках
      await tester.tap(barTab('Weekly'));
      await tester.pumpAndSettle();
      expect(pageTextContaining('"Atlantis" was not found'), findsOneWidget);

      await typeAndSubmit(tester, 'Paris');
      expect(pageTextContaining('was not found'), findsNothing);
      expect(pageText('Paris'), findsOneWidget);
    });

    testWidgets('нет связи: сообщение висит, а при восстановлении пропадает само', (tester) async {
      final Rig rig = Rig();
      rig.weather.failure = const ConnectionFailure();
      await pumpApp(tester, rig: rig);

      expect(pageTextContaining('Connection problem'), findsOneWidget);
      await settle(tester, const Duration(seconds: 5)); // ещё без связи
      expect(pageTextContaining('Connection problem'), findsOneWidget);

      rig.weather.failure = null; // интернет вернулся
      await settle(tester, const Duration(seconds: 11)); // дольше интервала повтора

      expect(pageTextContaining('Connection problem'), findsNothing);
      expect(pageText('Barcelona'), findsOneWidget);
    });

    testWidgets('поиск при обрыве связи: сообщение о соединении, не о городе', (tester) async {
      final Rig rig = await pumpApp(tester);
      rig.geocoding.failure = const ConnectionFailure();

      await typeAndSubmit(tester, 'Paris');
      expect(pageTextContaining('Connection problem'), findsOneWidget);

      // чтобы в конце теста не остался таймер повтора
      rig.geocoding.failure = null;
      await settle(tester, const Duration(seconds: 11));
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
      testWidgets('$name: все вкладки, подсказки, ошибка', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpApp(tester);
        for (final String title in ['Today', 'Weekly', 'Currently']) {
          await tester.tap(barTab(title));
          await tester.pumpAndSettle();
        }

        await tester.enterText(find.byType(TextField), 'Par');
        await settle(tester, const Duration(milliseconds: 400));
        expect(find.byType(SuggestionsList), findsOneWidget);

        await typeAndSubmit(tester, 'Atlantis'); // сообщение об ошибке

        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('крупный шрифт на всех вкладках', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpApp(tester);
      for (final String title in ['Today', 'Weekly', 'Currently']) {
        await tester.tap(barTab(title));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });
  });
}

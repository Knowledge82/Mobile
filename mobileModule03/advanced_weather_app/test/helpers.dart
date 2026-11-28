// Общие помощники виджет-тестов: поиск текста на странице вкладки, запуск
// приложения на подделках, «напечатать и нажать поиск».

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_weather_app/main.dart';

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

// ex01 (ежедневник): сам виджет календаря, отдельно от базы и страниц.
// Подробности: docs/05-ex01.md.
//
// ВАЖНО: тесты не запускались (см. docs/05-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_diary_app/ui/month_calendar.dart';

import 'helpers.dart';

void main() {
  // Календарь «глупый»: всё, что он показывает, ему присылают. Здесь мы
  // записываем, что он нам прислал обратно.
  late List<DateTime> selectedDays;
  late List<DateTime> monthChanges;
  late int todayTaps;

  Future<void> pumpCalendar(
    WidgetTester tester, {
    DateTime? month,
    DateTime? selected,
    Map<DateTime, int> counts = const {},
  }) async {
    usePhoneScreen(tester);
    selectedDays = [];
    monthChanges = [];
    todayTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthCalendar(
              month: month ?? DateTime(2026, 11),
              selected: selected ?? DateTime(2026, 11, 28),
              today: DateTime(2026, 11, 28),
              entryCounts: counts,
              onMonthChanged: monthChanges.add,
              onDaySelected: selectedDays.add,
              onTodayPressed: () => todayTaps++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('заголовок: месяц и год; подписи дней недели с понедельника', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('November 2026'), findsOneWidget);
    for (final String d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(d), findsOneWidget);
    }
  });

  testWidgets('в сетке ноября 2026 ровно 42 клетки: 26 октября ... 6 декабря', (tester) async {
    await pumpCalendar(tester);

    expect(find.byKey(dayCellKey(DateTime(2026, 10, 26))), findsOneWidget);
    expect(find.byKey(dayCellKey(DateTime(2026, 12, 6))), findsOneWidget);
    expect(find.byKey(dayCellKey(DateTime(2026, 10, 25))), findsNothing);
    expect(find.byKey(dayCellKey(DateTime(2026, 12, 7))), findsNothing);
  });

  testWidgets('нажатие на день присылает именно этот день', (tester) async {
    await pumpCalendar(tester);

    await tester.tap(find.byKey(dayCellKey(DateTime(2026, 11, 12))));

    expect(selectedDays, [DateTime(2026, 11, 12)]);
  });

  testWidgets('серые дни соседних месяцев тоже нажимаются', (tester) async {
    await pumpCalendar(tester);

    await tester.tap(find.byKey(dayCellKey(DateTime(2026, 12, 2))));

    expect(selectedDays, [DateTime(2026, 12, 2)]);
  });

  testWidgets('стрелки просят предыдущий и следующий месяц (первое число)', (tester) async {
    await pumpCalendar(tester);

    await tester.tap(find.byTooltip('Previous month'));
    await tester.tap(find.byTooltip('Next month'));

    expect(monthChanges, [DateTime(2026, 10), DateTime(2026, 12)]);
  });

  testWidgets('в январе стрелка «назад» уходит в декабрь прошлого года', (tester) async {
    await pumpCalendar(tester, month: DateTime(2026, 1), selected: DateTime(2026, 1, 5));

    await tester.tap(find.byTooltip('Previous month'));

    expect(monthChanges, [DateTime(2025, 12)]);
  });

  testWidgets('кнопка Today вызывает колбэк', (tester) async {
    await pumpCalendar(tester);

    await tester.tap(find.text('Today'));

    expect(todayTaps, 1);
  });

  testWidgets('смысл дня озвучивается словами: дата, «сегодня», число записей', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await pumpCalendar(
      tester,
      counts: {DateTime(2026, 11, 28): 2, DateTime(2026, 11, 27): 1},
    );

    String label(DateTime d) => tester.getSemantics(find.byKey(dayCellKey(d))).label;

    expect(label(DateTime(2026, 11, 28)), '28 November 2026, today, 2 entries');
    expect(label(DateTime(2026, 11, 27)), '27 November 2026, 1 entry');
    expect(label(DateTime(2026, 11, 12)), '12 November 2026');
  });

  testWidgets('в узком окне (320 px) ничего не переполняется', (tester) async {
    tester.view.physicalSize = const Size(640, 1200);
    tester.view.devicePixelRatio = 2.0; // 320 x 600
    addTearDown(tester.view.reset);
    selectedDays = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthCalendar(
              month: DateTime(2026, 9), // «September 2026»: длинное название
              selected: DateTime(2026, 9, 1),
              today: DateTime(2026, 11, 28),
              entryCounts: const {},
              onMonthChanged: (_) {},
              onDaySelected: selectedDays.add,
              onTodayPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('September 2026'), findsOneWidget);
  });
}

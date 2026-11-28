// ex01 (ежедневник): страница с календарём в приложении целиком.
// Подробности: docs/05-ex01.md.
//
// ВАЖНО: тесты не запускались (см. docs/05-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_diary_app/models/diary_entry.dart';
import 'package:advanced_diary_app/models/feeling.dart';
import 'package:advanced_diary_app/ui/month_calendar.dart';

import 'fakes.dart';
import 'helpers.dart';

// «Сегодня» в тестах: 28 ноября 2026 (суббота), см. helpers.dart.
List<DiaryEntry> sampleDiary() => [
  sampleEntry(1, title: 'Morning', date: DateTime(2026, 11, 28, 8, 5)),
  sampleEntry(2, title: 'Evening', date: DateTime(2026, 11, 28, 21, 15), feeling: Feeling.dissatisfied),
  sampleEntry(3, title: 'Yesterday', date: DateTime(2026, 11, 27, 12, 0)),
  sampleEntry(4, title: 'Next month', date: DateTime(2026, 12, 2, 10, 30)),
];

Future<Harness> openAgenda(WidgetTester tester, {List<DiaryEntry>? entries}) async {
  usePhoneScreen(tester);
  final Harness h = Harness(
    auth: FakeAuthService(signedIn: alice),
    diary: FakeDiaryRepository(entries: entries ?? sampleDiary()),
  );
  await pumpApp(tester, harness: h);
  await tapAndSettle(tester, agendaTab);
  return h;
}

Finder day(int y, int m, int d) => find.byKey(dayCellKey(DateTime(y, m, d)));

void main() {
  group('открытие страницы', () {
    testWidgets('показывает текущую дату: месяц, выбранный сегодняшний день и его записи', (tester) async {
      await openAgenda(tester);

      expect(find.text('Diary agenda'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('28 November 2026'), findsOneWidget); // заголовок списка
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
      expect(find.text('Yesterday'), findsNothing); // это вчера
    });

    testWidgets('записи дня идут от поздних к ранним, под заголовком время', (tester) async {
      await openAgenda(tester);

      expect(find.text('21:15'), findsOneWidget);
      expect(find.text('08:05'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Evening')).dy,
        lessThan(tester.getTopLeft(find.text('Morning')).dy),
      );
    });

    testWidgets('на вкладке «Ежедневник» нет кнопки новой записи (она только в профиле)', (tester) async {
      await openAgenda(tester);

      expect(newEntryButton, findsNothing);
    });

    testWidgets('дневник пуст: календарь есть, в списке подсказка', (tester) async {
      await openAgenda(tester, entries: []);

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('No entries on this day.'), findsOneWidget);
    });
  });

  group('выбор даты', () {
    testWidgets('выбрали вчера: заголовок и список сменились', (tester) async {
      await openAgenda(tester);

      await tapAndSettle(tester, day(2026, 11, 27));

      expect(find.text('27 November 2026'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Morning'), findsNothing);
    });

    testWidgets('день без записей: «No entries on this day.»', (tester) async {
      await openAgenda(tester);

      await tapAndSettle(tester, day(2026, 11, 20));

      expect(find.text('20 November 2026'), findsOneWidget);
      expect(find.text('No entries on this day.'), findsOneWidget);
    });

    testWidgets('нажали серый день следующего месяца: календарь перелистнулся', (tester) async {
      await openAgenda(tester);

      await tapAndSettle(tester, day(2026, 12, 2)); // виден «хвостом» в сетке ноября

      expect(find.text('December 2026'), findsOneWidget);
      expect(find.text('Next month'), findsOneWidget);
    });

    testWidgets('стрелки листают месяцы; выбранный день при этом не меняется', (tester) async {
      await openAgenda(tester);

      await tapAndSettle(tester, find.byTooltip('Next month'));

      expect(find.text('December 2026'), findsOneWidget);
      expect(find.text('28 November 2026'), findsOneWidget); // выбор остался
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('Today возвращает на сегодня из другого месяца', (tester) async {
      await openAgenda(tester);
      await tapAndSettle(tester, find.byTooltip('Previous month'));
      await tapAndSettle(tester, day(2026, 10, 10));
      expect(find.text('10 October 2026'), findsOneWidget);

      await tapAndSettle(tester, find.text('Today'));

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('28 November 2026'), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
    });

    testWidgets('переключение на профиль и обратно не сбрасывает выбранный день', (tester) async {
      await openAgenda(tester);
      await tapAndSettle(tester, day(2026, 11, 27));

      await tapAndSettle(tester, profileTab);
      expect(find.text('My diary'), findsOneWidget);
      await tapAndSettle(tester, agendaTab);

      expect(find.text('27 November 2026'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
    });
  });

  group('чтение и удаление', () {
    testWidgets('нажатие на запись открывает её', (tester) async {
      await openAgenda(tester);

      await tapAndSettle(tester, find.text('Evening'));

      expect(find.text('Text of day 2.'), findsOneWidget);
      expect(find.text('Sad'), findsOneWidget);
      expect(find.text('2026-11-28 21:15'), findsOneWidget);
    });

    testWidgets('мусорка: вопрос, подтверждение, запись исчезла из списка дня', (tester) async {
      final Harness h = await openAgenda(tester);

      final Finder row = find.widgetWithText(ListTile, 'Morning');
      await tapAndSettle(tester, find.descendant(of: row, matching: find.byTooltip('Delete entry')));
      expect(find.text('Delete this entry?'), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(h.diary.deleted, ['seed1']);
      expect(find.text('Morning'), findsNothing);
      expect(find.text('Evening'), findsOneWidget); // вторая запись дня на месте
    });

    testWidgets('удалили последнюю запись дня: появляется «No entries on this day.»', (tester) async {
      final Harness h = await openAgenda(tester);
      await tapAndSettle(tester, day(2026, 11, 27));

      await tapAndSettle(tester, find.byTooltip('Delete entry'));
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(h.diary.deleted, ['seed3']);
      expect(find.text('No entries on this day.'), findsOneWidget);
    });

    testWidgets('Cancel в вопросе: запись на месте', (tester) async {
      final Harness h = await openAgenda(tester);
      await tapAndSettle(tester, find.byTooltip('Delete entry').first);

      await tapAndSettle(tester, find.text('Cancel'));

      expect(h.diary.deleted, isEmpty);
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('удаление из окна чтения', (tester) async {
      final Harness h = await openAgenda(tester);
      await tapAndSettle(tester, find.text('Morning'));

      await tapAndSettle(tester, find.widgetWithText(TextButton, 'Delete'));
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(h.diary.deleted, ['seed1']);
      expect(find.text('Morning'), findsNothing);
    });
  });

  group('в реальном времени', () {
    testWidgets('запись, пришедшая с другого устройства, появляется в списке дня сама', (tester) async {
      final Harness h = await openAgenda(tester);
      expect(find.text('Surprise'), findsNothing);

      await h.diary.add(
        'u-alice',
        EntryDraft(
          email: 'alice@example.com',
          date: DateTime(2026, 11, 28, 22, 0),
          title: 'Surprise',
          feeling: Feeling.verySatisfied,
          content: 'From another phone.',
        ),
      );
      await tester.pump();

      expect(find.text('Surprise'), findsOneWidget);
    });

    testWidgets('под днями с записями видны отметки (по озвучке: «N entries»)', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      await openAgenda(tester);

      String label(int d) => tester.getSemantics(day(2026, 11, d)).label;

      expect(label(28), '28 November 2026, today, 2 entries');
      expect(label(27), '27 November 2026, 1 entry');
      expect(label(26), '26 November 2026');
    });
  });

  group('экран', () {
    testWidgets('телефон в ландшафте: ничего не переполняется, список достижим прокруткой', (tester) async {
      useLandscapeScreen(tester);
      final Harness h = Harness(
        auth: FakeAuthService(signedIn: alice),
        diary: FakeDiaryRepository(entries: sampleDiary()),
      );
      await pumpApp(tester, harness: h);
      await tapAndSettle(tester, agendaTab);

      await tester.scrollUntilVisible(find.text('Evening'), 200, scrollable: find.byType(Scrollable).first);

      expect(tester.takeException(), isNull);
      expect(find.text('Evening'), findsOneWidget);
    });
  });
}

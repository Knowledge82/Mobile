// ex00 (профиль): имя, выход, последние 2 записи, всего, проценты, новая запись.
// Подробности: docs/05-ex00.md.
//
// ВАЖНО: тесты не запускались (см. docs/05-ex00.md).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_diary_app/app.dart';
import 'package:advanced_diary_app/config.dart';
import 'package:advanced_diary_app/models/app_user.dart';
import 'package:advanced_diary_app/models/diary_entry.dart';
import 'package:advanced_diary_app/models/feeling.dart';
import 'package:advanced_diary_app/services/diary_repository.dart';

import 'fakes.dart';
import 'helpers.dart';

// Профиль уже вошедшего пользователя; записи лежат в подделке базы.
Future<Harness> openProfile(
  WidgetTester tester, {
  FakeDiaryRepository? diary,
  AppUser? user,
}) async {
  usePhoneScreen(tester);
  final Harness h = Harness(
    auth: FakeAuthService(signedIn: user ?? alice),
    diary: diary ?? FakeDiaryRepository(),
  );
  return pumpApp(tester, harness: h);
}

Finder get titleField => find.widgetWithText(TextFormField, 'Title');
Finder get contentField => find.widgetWithText(TextFormField, 'Dear diary...');

void main() {
  group('шапка', () {
    testWidgets('имя и почта пользователя, кнопка выхода', (tester) async {
      await openProfile(tester);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.byTooltip('Log out'), findsOneWidget);
      expect(find.text('A'), findsOneWidget); // «аватарка»: первая буква имени
    });

    testWidgets('нет имени и почты: показываем uid, почту отдельно не дублируем', (tester) async {
      await openProfile(tester, user: noMail, diary: FakeDiaryRepository(owner: 'u-gh'));

      expect(find.text('u-gh'), findsOneWidget);
    });

    testWidgets('нет имени, есть почта: почта в роли имени и не показывается дважды', (tester) async {
      const AppUser onlyMail = AppUser(uid: 'u-m', email: 'm@x.org');
      await openProfile(tester, user: onlyMail, diary: FakeDiaryRepository(owner: 'u-m'));

      expect(find.text('m@x.org'), findsOneWidget);
    });

    testWidgets('Log out выходит и возвращает на приветствие', (tester) async {
      final Harness h = await openProfile(tester);

      await tapAndSettle(tester, find.byTooltip('Log out'));

      expect(h.auth.signOutCalls, 1);
      expect(welcomeText, findsOneWidget);
    });
  });

  group('последние записи и статистика', () {
    testWidgets('пустой дневник: подсказка, всего 0, у всех самочувствий 0%', (tester) async {
      await openProfile(tester);

      expect(find.textContaining('No entries yet'), findsOneWidget);
      expect(find.text('Total entries: 0'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(Feeling.values.length));
      expect(newEntryButton, findsOneWidget);
    });

    testWidgets('показывает только две последние записи, новые сверху', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [
          sampleEntry(1, title: 'First'),
          sampleEntry(2, title: 'Second'),
          sampleEntry(3, title: 'Third'),
          sampleEntry(4, title: 'Fourth'),
        ],
      );
      await openProfile(tester, diary: diary);

      expect(profileLastEntriesCount, 2);
      expect(find.text('Fourth'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
      expect(find.text('First'), findsNothing);
      expect(tester.getTopLeft(find.text('Fourth')).dy, lessThan(tester.getTopLeft(find.text('Third')).dy));
    });

    testWidgets('у записи: дата, значок самочувствия, заголовок', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [sampleEntry(5, title: 'Fifth', feeling: Feeling.veryDissatisfied)],
      );
      await openProfile(tester, diary: diary);

      expect(find.text('2026-11-05'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_very_dissatisfied), findsWidgets);
      expect(find.text('Fifth'), findsOneWidget);
    });

    testWidgets('всего записей считает ВСЕ, а не только показанные', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [for (int i = 1; i <= 7; i++) sampleEntry(i)],
      );
      await openProfile(tester, diary: diary);

      expect(find.text('Total entries: 7'), findsOneWidget);
    });

    testWidgets('проценты: 2 из 3 это 67%, 1 из 3 это 33%, остальные 0%', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [
          sampleEntry(1, feeling: Feeling.satisfied),
          sampleEntry(2, feeling: Feeling.satisfied),
          sampleEntry(3, feeling: Feeling.neutral),
        ],
      );
      await openProfile(tester, diary: diary);

      expect(find.text('67%'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(find.text('0%'), findsNWidgets(3));
    });

    testWidgets('в списке самочувствий все пять подписей', (tester) async {
      await openProfile(tester);

      for (final Feeling f in Feeling.values) {
        expect(find.text(f.label), findsOneWidget);
      }
    });

    testWidgets('в реальном времени: запись пришла со стороны, цифры и список обновились', (tester) async {
      final Harness h = await openProfile(tester);
      expect(find.text('Total entries: 0'), findsOneWidget);

      await h.diary.add(
        'u-alice',
        EntryDraft(
          email: 'alice@example.com',
          date: DateTime(2026, 11, 20),
          title: 'From the other phone',
          feeling: Feeling.verySatisfied,
          content: 'Hello',
        ),
      );
      await tester.pump();

      expect(find.text('Total entries: 1'), findsOneWidget);
      expect(find.text('From the other phone'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('No entries yet'), findsNothing);
    });

    testWidgets('в реальном времени: после удаления цифры пересчитались, из «старых» всплыла запись', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [
          sampleEntry(1, title: 'Old', feeling: Feeling.neutral),
          sampleEntry(2, title: 'Middle', feeling: Feeling.neutral),
          sampleEntry(3, title: 'Newest', feeling: Feeling.satisfied),
        ],
      );
      await openProfile(tester, diary: diary);
      expect(find.text('Old'), findsNothing);

      final Finder row = find.widgetWithText(ListTile, 'Newest');
      await tapAndSettle(tester, find.descendant(of: row, matching: find.byTooltip('Delete entry')));
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(find.text('Total entries: 2'), findsOneWidget);
      expect(find.text('Newest'), findsNothing);
      expect(find.text('Old'), findsOneWidget); // стала одной из двух последних
      expect(find.text('100%'), findsOneWidget); // теперь обе записи нейтральные
    });
  });

  group('оболочка', () {
    testWidgets('подписка на записи одна на оба экрана и не пересоздаётся при смене вкладки', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);

      await tapAndSettle(tester, agendaTab);
      await tapAndSettle(tester, profileTab);

      expect(diary.watchCalls, ['u-alice']);
    });

    testWidgets('пока список не пришёл: индикатор загрузки', (tester) async {
      usePhoneScreen(tester);
      final FakeDiaryRepository diary = FakeDiaryRepository()..silent = true;
      final Harness h = Harness(auth: FakeAuthService(signedIn: alice), diary: diary);
      addTearDown(h.auth.dispose);
      addTearDown(h.diary.dispose);
      await tester.pumpWidget(DiaryApp(services: h.services));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ошибка базы: сообщение и «Try again» подписывается заново', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository()..watchFailure = const DiaryUnavailable();
      await openProfile(tester, diary: diary);

      expect(find.textContaining('Cannot reach the database'), findsOneWidget);

      diary.watchFailure = null;
      await tapAndSettle(tester, find.text('Try again'));

      expect(diary.watchCalls, hasLength(2));
      expect(find.text('Total entries: 0'), findsOneWidget);
    });

    testWidgets('чужие записи не показываются', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [sampleEntry(1, title: 'Mine')],
        owner: 'someone-else',
      );
      await openProfile(tester, diary: diary);

      expect(find.text('Mine'), findsNothing);
      expect(find.text('Total entries: 0'), findsOneWidget);
    });

    testWidgets('вход пропал сам: возврат на приветствие', (tester) async {
      final Harness h = await openProfile(tester);

      h.auth.expireSession();
      await tester.pumpAndSettle();

      expect(welcomeText, findsOneWidget);
    });
  });

  group('создание записи', () {
    testWidgets('пустая форма не сохраняется: подсказки «Required»', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);

      await tapAndSettle(tester, find.text('Save'));

      expect(find.text('Required'), findsNWidgets(2));
      expect(diary.added, isEmpty);
    });

    testWidgets('заполнили и сохранили: запись в базе с почтой и датой, профиль обновился', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);

      await tester.enterText(titleField, '  A good day  ');
      await tester.tap(find.text('Very happy'));
      await tester.enterText(contentField, 'We walked by the sea.');
      await tapAndSettle(tester, find.text('Save'));

      expect(diary.added, hasLength(1));
      expect(diary.added.single.email, 'alice@example.com');
      expect(diary.added.single.date, fixedNow);
      expect(diary.added.single.title, 'A good day');
      expect(diary.added.single.feeling, Feeling.verySatisfied);

      expect(find.text('A good day'), findsOneWidget);
      expect(find.text('2026-11-28'), findsOneWidget);
      expect(find.text('Total entries: 1'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('новая запись сразу видна и на вкладке «Ежедневник» (на сегодняшнем дне)', (tester) async {
      await openProfile(tester);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'Fresh');
      await tester.enterText(contentField, 'Text');
      await tapAndSettle(tester, find.text('Save'));

      await tapAndSettle(tester, agendaTab);

      expect(find.text('Fresh'), findsOneWidget);
      expect(find.text('09:30'), findsOneWidget); // fixedNow
    });

    testWidgets('Cancel: ничего не сохраняется', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'draft');

      await tapAndSettle(tester, find.text('Cancel'));

      expect(diary.added, isEmpty);
    });

    testWidgets('у аккаунта без почты запись сохраняется с пустой почтой', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(owner: 'u-gh');
      await openProfile(tester, diary: diary, user: noMail);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'T');
      await tester.enterText(contentField, 'C');
      await tapAndSettle(tester, find.text('Save'));

      expect(diary.added.single.email, '');
    });

    testWidgets('база отказала: сообщение, записи в списке нет', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository()..writeFailure = const DiaryPermissionDenied();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'T');
      await tester.enterText(contentField, 'C');
      await tapAndSettle(tester, find.text('Save'));

      expect(find.textContaining('refused this action'), findsOneWidget);
      expect(find.text('Total entries: 0'), findsOneWidget);
    });

    testWidgets('без сети: запись видна сразу, через 8 секунд честное сообщение', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository()..writeGate = Completer<void>();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'Offline note');
      await tester.enterText(contentField, 'No signal here.');
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Offline note'), findsOneWidget);
      expect(find.textContaining('Saved on this device'), findsNothing);

      await tester.pump(writeConfirmationTimeout + const Duration(seconds: 1));
      await tester.pump();

      expect(find.textContaining('Saved on this device'), findsOneWidget);
      expect(find.text('Offline note'), findsOneWidget);
    });
  });

  group('чтение и удаление', () {
    testWidgets('нажатие на запись открывает её целиком', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [
          sampleEntry(
            7,
            title: 'Long day',
            content: 'First line.\nSecond line.',
            feeling: Feeling.dissatisfied,
            date: DateTime(2026, 11, 7, 18, 45),
          ),
        ],
      );
      await openProfile(tester, diary: diary);

      await tapAndSettle(tester, find.text('Long day'));

      expect(find.text('First line.\nSecond line.'), findsOneWidget);
      expect(find.text('2026-11-07 18:45'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('удаление из окна чтения: один вопрос, запись исчезает, подсказка возвращается', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(entries: [sampleEntry(1, title: 'Gone soon')]);
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, find.text('Gone soon'));

      await tapAndSettle(tester, find.widgetWithText(TextButton, 'Delete'));
      expect(find.text('Delete this entry?'), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(diary.deleted, ['seed1']);
      expect(find.text('Gone soon'), findsNothing);
      expect(find.textContaining('No entries yet'), findsOneWidget);
    });

    testWidgets('Cancel в вопросе: запись на месте', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(entries: [sampleEntry(1, title: 'Stay')]);
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, find.byTooltip('Delete entry'));

      await tapAndSettle(tester, find.text('Cancel'));

      expect(diary.deleted, isEmpty);
      expect(find.text('Stay'), findsOneWidget);
    });

    testWidgets('база отказала при удалении: сообщение, запись остаётся', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(entries: [sampleEntry(1, title: 'Protected')])
        ..writeFailure = const DiaryPermissionDenied();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, find.byTooltip('Delete entry'));
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(find.textContaining('refused this action'), findsOneWidget);
      expect(find.text('Protected'), findsOneWidget);
    });
  });
}

// ex01: профиль: список, создание, чтение, удаление, работа без сети.
// Подробности: docs/04-ex01.md.
//
// ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:diary_app/app.dart';
import 'package:diary_app/config.dart';
import 'package:diary_app/models/app_user.dart';
import 'package:diary_app/models/feeling.dart';
import 'package:diary_app/services/diary_repository.dart';

import 'fakes.dart';
import 'helpers.dart';

// Профиль уже вошедшего пользователя; записи лежат в подделке базы.
Future<Harness> openProfile(
  WidgetTester tester, {
  FakeDiaryRepository? diary,
  AppUser? user,
}) async {
  final Harness h = Harness(
    auth: FakeAuthService(signedIn: user ?? alice),
    diary: diary ?? FakeDiaryRepository(),
  );
  return pumpApp(tester, harness: h);
}

Finder get titleField => find.widgetWithText(TextFormField, 'Title');
Finder get contentField => find.widgetWithText(TextFormField, 'Dear diary...');

void main() {
  group('список записей', () {
    testWidgets('пустой дневник: подсказка, как начать', (tester) async {
      await openProfile(tester);

      expect(find.textContaining('No entries yet'), findsOneWidget);
      expect(newEntryButton, findsOneWidget);
    });

    testWidgets('записи в списке: заголовок, дата, значок самочувствия; новые сверху', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [
          sampleEntry(3, title: 'Third'),
          sampleEntry(5, title: 'Fifth', feeling: Feeling.veryDissatisfied),
          sampleEntry(4, title: 'Fourth'),
        ],
      );
      await openProfile(tester, diary: diary);

      expect(find.text('Fifth'), findsOneWidget);
      expect(find.text('2026-11-05'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_very_dissatisfied), findsOneWidget);
      final double yFifth = tester.getTopLeft(find.text('Fifth')).dy;
      final double yFourth = tester.getTopLeft(find.text('Fourth')).dy;
      final double yThird = tester.getTopLeft(find.text('Third')).dy;
      expect(yFifth, lessThan(yFourth));
      expect(yFourth, lessThan(yThird));
    });

    testWidgets('подписываемся на записи именно этого пользователя, один раз', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);

      expect(diary.watchCalls, ['u-alice']);
      await tester.pump(const Duration(seconds: 1));
      expect(diary.watchCalls, hasLength(1)); // перерисовки не пересоздают подписку
    });

    testWidgets('пока список не пришёл: индикатор загрузки', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository()..silent = true;
      final Harness h = Harness(auth: FakeAuthService(signedIn: alice), diary: diary);
      addTearDown(h.auth.dispose);
      addTearDown(h.diary.dispose);
      await tester.pumpWidget(DiaryApp(services: h.services));
      await tester.pump(); // стартовый переход
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ошибка базы: сообщение и «Try again» подписывается заново', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository()..watchFailure = const DiaryUnavailable();
      await openProfile(tester, diary: diary);

      expect(find.textContaining('Cannot reach the database'), findsOneWidget);

      diary.watchFailure = null; // связь появилась
      await tapAndSettle(tester, find.text('Try again'));

      expect(diary.watchCalls, hasLength(2));
      expect(find.textContaining('No entries yet'), findsOneWidget);
    });

    testWidgets('чужие записи не показываются', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [sampleEntry(1, title: 'Mine')],
        owner: 'someone-else',
      );
      await openProfile(tester, diary: diary);

      expect(find.text('Mine'), findsNothing);
    });
  });

  group('создание записи', () {
    testWidgets('пустая форма не сохраняется: подсказки «Required»', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);

      await tapAndSettle(tester, find.text('Save'));

      expect(find.text('Required'), findsNWidgets(2)); // заголовок и текст
      expect(diary.added, isEmpty);
    });

    testWidgets('пробелы вместо текста тоже считаются пустым', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);

      await tester.enterText(titleField, '   ');
      await tester.enterText(contentField, '  ');
      await tapAndSettle(tester, find.text('Save'));

      expect(diary.added, isEmpty);
    });

    testWidgets('заполнили и сохранили: запись ушла в базу с почтой и датой, список обновился', (tester) async {
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
      expect(diary.added.single.title, 'A good day'); // края обрезаны
      expect(diary.added.single.feeling, Feeling.verySatisfied);
      expect(diary.added.single.content, 'We walked by the sea.');

      // окно закрылось, в списке новая запись
      expect(find.text('Dear diary...'), findsNothing);
      expect(find.text('A good day'), findsOneWidget);
      expect(find.text('2026-11-28'), findsOneWidget);
      expect(find.textContaining('No entries yet'), findsNothing);
    });

    testWidgets('самочувствие по умолчанию нейтральное', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'T');
      await tester.enterText(contentField, 'C');
      await tapAndSettle(tester, find.text('Save'));

      expect(diary.added.single.feeling, Feeling.neutral);
    });

    testWidgets('Cancel: ничего не сохраняется', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'draft');

      await tapAndSettle(tester, find.text('Cancel'));

      expect(diary.added, isEmpty);
      expect(find.text('Dear diary...'), findsNothing);
    });

    testWidgets('у GitHub-аккаунта без почты запись сохраняется с пустой почтой', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(owner: 'u-gh');
      await openProfile(tester, diary: diary, user: noMail);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'T');
      await tester.enterText(contentField, 'C');
      await tapAndSettle(tester, find.text('Save'));

      expect(diary.added.single.email, '');
      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('база отказала (правила): сообщение, окно закрыто, записи нет', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository()..writeFailure = const DiaryPermissionDenied();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'T');
      await tester.enterText(contentField, 'C');
      await tapAndSettle(tester, find.text('Save'));

      expect(find.textContaining('refused this action'), findsOneWidget);
      expect(find.text('T'), findsNothing);
    });

    testWidgets('без сети сервер не отвечает: запись уже в списке, через 8 секунд честное сообщение', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository()..writeGate = Completer<void>();
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, newEntryButton);
      await tester.enterText(titleField, 'Offline note');
      await tester.enterText(contentField, 'No signal here.');
      await tester.tap(find.text('Save'));
      await tester.pump(); // окно закрывается, запись уходит
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Offline note'), findsOneWidget); // видно сразу, не дожидаясь сервера
      expect(find.textContaining('Saved on this device'), findsNothing);

      await tester.pump(writeConfirmationTimeout + const Duration(seconds: 1));
      await tester.pump();

      expect(find.textContaining('Saved on this device'), findsOneWidget);
      expect(find.text('Offline note'), findsOneWidget);
    });
  });

  group('чтение записи', () {
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
      expect(find.text('Sad'), findsOneWidget); // подпись самочувствия
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Close закрывает окно, запись остаётся', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(entries: [sampleEntry(7, title: 'Keep me')]);
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, find.text('Keep me'));

      await tapAndSettle(tester, find.text('Close'));

      expect(find.text('Text of day 7.'), findsNothing);
      expect(find.text('Keep me'), findsOneWidget);
      expect(diary.deleted, isEmpty);
    });
  });

  group('удаление записи', () {
    testWidgets('кнопка удаления в строке: вопрос, подтверждение, список обновился', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(
        entries: [sampleEntry(1, title: 'Keep'), sampleEntry(2, title: 'Remove me')],
      );
      await openProfile(tester, diary: diary);

      final Finder row = find.widgetWithText(ListTile, 'Remove me');
      await tapAndSettle(tester, find.descendant(of: row, matching: find.byTooltip('Delete entry')));
      expect(find.text('Delete this entry?'), findsOneWidget);
      expect(diary.deleted, isEmpty); // пока не подтвердили, ничего не удалено

      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Delete'));

      expect(diary.deleted, ['seed2']);
      expect(find.text('Remove me'), findsNothing);
      expect(find.text('Keep'), findsOneWidget);
    });

    testWidgets('Cancel в вопросе: запись на месте', (tester) async {
      final FakeDiaryRepository diary = FakeDiaryRepository(entries: [sampleEntry(1, title: 'Stay')]);
      await openProfile(tester, diary: diary);
      await tapAndSettle(tester, find.byTooltip('Delete entry'));

      await tapAndSettle(tester, find.text('Cancel'));

      expect(diary.deleted, isEmpty);
      expect(find.text('Stay'), findsOneWidget);
    });

    testWidgets('удаление из окна чтения: один вопрос, запись исчезает', (tester) async {
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

    testWidgets('база отказала: сообщение, запись остаётся в списке', (tester) async {
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

// Общие помощники виджет-тестов: запуск приложения на подделках.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:diary_app/app.dart';
import 'package:diary_app/app_services.dart';

import 'fakes.dart';

// «Сейчас» в тестах: суббота, 28 ноября 2026, 09:30.
final DateTime fixedNow = DateTime(2026, 11, 28, 9, 30);

class Harness {
  Harness({FakeAuthService? auth, FakeDiaryRepository? diary})
    : auth = auth ?? FakeAuthService(),
      diary = diary ?? FakeDiaryRepository();

  final FakeAuthService auth;
  final FakeDiaryRepository diary;

  AppServices get services => AppServices(auth: auth, diary: diary, now: () => fixedNow);
}

// Запускает приложение и ждёт, пока всё устоится (в том числе авто-переход
// на профиль, если вход уже выполнен).
Future<Harness> pumpApp(WidgetTester tester, {Harness? harness}) async {
  final Harness h = harness ?? Harness();
  addTearDown(h.auth.dispose);
  addTearDown(h.diary.dispose);
  await tester.pumpWidget(DiaryApp(services: h.services));
  await tester.pumpAndSettle();
  return h;
}

// Нажать кнопку/иконку и дождаться конца анимаций.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder get welcomeText => find.text('Welcome to your Diary');
Finder get loginButton => find.widgetWithText(FilledButton, 'Login');
Finder get googleButton => find.text('Continue with Google');
Finder get githubButton => find.text('Continue with GitHub');
Finder get newEntryButton => find.text('New diary entry');

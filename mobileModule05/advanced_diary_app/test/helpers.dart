// Общие помощники виджет-тестов: запуск приложения на подделках.

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_diary_app/app.dart';
import 'package:advanced_diary_app/app_services.dart';

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

// Экран «как телефон»: 360 x 800 логических пикселей (1080 x 2400 при плотности 3).
// Тестовый экран по умолчанию 800 x 600: календарь с шестью неделями и две вкладки
// на нём тесны, и часть строк оказалась бы за краем.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

// Низкий широкий экран (телефон в ландшафте): проверка «ничего не переполняется».
void useLandscapeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 720);
  tester.view.devicePixelRatio = 2.0; // 800 x 360 логических
  addTearDown(tester.view.reset);
}

Finder get profileTab => find.widgetWithText(NavigationDestination, 'Profile');
Finder get agendaTab => find.widgetWithText(NavigationDestination, 'Agenda');

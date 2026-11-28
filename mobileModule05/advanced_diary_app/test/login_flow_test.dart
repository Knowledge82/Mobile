// ex00: страница входа и путь до профиля. Подробности: docs/04-ex00.md.
//
// ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_diary_app/services/auth_service.dart';

import 'fakes.dart';
import 'helpers.dart';

void main() {
  group('страница входа', () {
    testWidgets('приветствие и кнопка Login', (tester) async {
      await pumpApp(tester);

      expect(welcomeText, findsOneWidget);
      expect(loginButton, findsOneWidget);
    });

    testWidgets('не вошёл: Login открывает страницу входа с Google и GitHub', (tester) async {
      await pumpApp(tester);

      await tapAndSettle(tester, loginButton);

      expect(googleButton, findsOneWidget);
      expect(githubButton, findsOneWidget);
      expect(find.text('My diary'), findsNothing); // профиль без входа не открывается
    });

    testWidgets('уже вошёл при запуске: сразу профиль, без нажатия на Login', (tester) async {
      await pumpApp(tester, harness: Harness(auth: FakeAuthService(signedIn: alice)));

      expect(find.text('My diary'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('уже вошёл и вернулся назад: Login ведёт прямо в профиль', (tester) async {
      await pumpApp(tester, harness: Harness(auth: FakeAuthService(signedIn: alice)));

      await tester.pageBack(); // с профиля обратно на приветствие
      await tester.pumpAndSettle();
      expect(welcomeText, findsOneWidget);

      await tapAndSettle(tester, loginButton);

      expect(find.text('My diary'), findsOneWidget);
      expect(googleButton, findsNothing); // страницу входа пропустили
    });
  });

  group('вход Google и GitHub', () {
    testWidgets('Google: вошли и попали в профиль', (tester) async {
      final Harness h = await pumpApp(tester);
      await tapAndSettle(tester, loginButton);

      await tapAndSettle(tester, googleButton);

      expect(h.auth.signInCalls, [SignInProvider.google]);
      expect(find.text('My diary'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('GitHub: вошли и попали в профиль', (tester) async {
      final Harness h = await pumpApp(tester);
      h.auth.userToSignIn = noMail; // у GitHub-аккаунта почта может быть скрыта
      await tapAndSettle(tester, loginButton);

      await tapAndSettle(tester, githubButton);

      expect(h.auth.signInCalls, [SignInProvider.github]);
      expect(find.text('My diary'), findsOneWidget);
      expect(find.text('u-gh'), findsOneWidget); // нет имени и почты: показываем uid
    });

    testWidgets('пока идёт вход: обе кнопки отключены, на нажатой крутится индикатор', (tester) async {
      final Harness h = await pumpApp(tester);
      h.auth.gate = Completer<void>();
      await tapAndSettle(tester, loginButton);

      await tester.tap(googleButton);
      await tester.pump(); // кадр без settle: индикатор крутится бесконечно

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // OutlinedButton.icon создаёт ПОДКЛАСС OutlinedButton, а byType подклассы не
      // находит (сравнивает точный тип): поэтому bySubtype.
      final OutlinedButton google = tester.widget(
        find.ancestor(of: googleButton, matching: find.bySubtype<OutlinedButton>()),
      );
      final OutlinedButton github = tester.widget(
        find.ancestor(of: githubButton, matching: find.bySubtype<OutlinedButton>()),
      );
      expect(google.onPressed, isNull);
      expect(github.onPressed, isNull);

      h.auth.gate!.complete(); // «вход завершился»
      await tester.pumpAndSettle();
      expect(find.text('My diary'), findsOneWidget);
      expect(h.auth.signInCalls, hasLength(1)); // второго входа не запускали
    });

    testWidgets('отмена входа: тихо остаёмся на странице входа, без сообщения', (tester) async {
      final Harness h = await pumpApp(tester);
      h.auth.failure = const SignInCancelled();
      await tapAndSettle(tester, loginButton);

      await tapAndSettle(tester, googleButton);

      expect(googleButton, findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('My diary'), findsNothing);
    });

    testWidgets('«почта занята другим способом»: понятное сообщение', (tester) async {
      final Harness h = await pumpApp(tester);
      h.auth.failure = const AccountExistsWithOtherProvider();
      await tapAndSettle(tester, loginButton);

      await tapAndSettle(tester, githubButton);

      expect(find.textContaining('already used with another sign-in method'), findsOneWidget);
      expect(find.text('My diary'), findsNothing);
    });

    testWidgets('нет сети: сообщение, кнопки снова работают', (tester) async {
      final Harness h = await pumpApp(tester);
      h.auth.failure = const AuthNetworkFailure();
      await tapAndSettle(tester, loginButton);

      await tapAndSettle(tester, googleButton);
      expect(find.textContaining('No internet connection'), findsOneWidget);

      h.auth.failure = null; // сеть появилась
      await tester.pump(const Duration(seconds: 5)); // snackbar уходит
      await tapAndSettle(tester, googleButton);
      expect(find.text('My diary'), findsOneWidget);
    });
  });

  group('выход и охрана профиля', () {
    testWidgets('Log out возвращает на приветствие', (tester) async {
      final Harness h = await pumpApp(tester, harness: Harness(auth: FakeAuthService(signedIn: alice)));

      await tapAndSettle(tester, find.byTooltip('Log out'));

      expect(h.auth.signOutCalls, 1);
      expect(welcomeText, findsOneWidget);
      expect(find.text('My diary'), findsNothing);
    });

    testWidgets('после выхода Login снова открывает страницу входа', (tester) async {
      await pumpApp(tester, harness: Harness(auth: FakeAuthService(signedIn: alice)));
      await tapAndSettle(tester, find.byTooltip('Log out'));

      await tapAndSettle(tester, loginButton);

      expect(googleButton, findsOneWidget);
    });

    testWidgets('вход пропал сам (токен отозван): профиль закрывается, окна тоже', (tester) async {
      final Harness h = await pumpApp(tester, harness: Harness(auth: FakeAuthService(signedIn: alice)));
      await tapAndSettle(tester, newEntryButton); // открыто окно «New diary entry»
      expect(find.text('Dear diary...'), findsOneWidget);

      h.auth.expireSession();
      await tester.pumpAndSettle();

      expect(welcomeText, findsOneWidget);
      expect(find.text('Dear diary...'), findsNothing);
    });
  });
}

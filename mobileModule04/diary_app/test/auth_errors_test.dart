// Перевод кодов ошибок Firebase Auth в наши. Подробности: docs/04-ex00.md.
//
// ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/services/auth_service.dart';
import 'package:diary_app/services/firebase_auth_service.dart';

void main() {
  test('закрыл окно входа: отмена, а не ошибка (все платформы)', () {
    for (final String code in [
      'web-context-canceled', // Android
      'web-context-cancelled', // iOS
      'popup-closed-by-user', // веб
      'cancelled-popup-request',
      'redirect-cancelled-by-user',
      'user-cancelled',
      'canceled',
    ]) {
      expect(translateAuthError(code), isA<SignInCancelled>(), reason: code);
    }
  });

  test('почта уже занята другим способом входа', () {
    expect(
      translateAuthError('account-exists-with-different-credential'),
      isA<AccountExistsWithOtherProvider>(),
    );
  });

  test('нет сети', () {
    expect(translateAuthError('network-request-failed'), isA<AuthNetworkFailure>());
    expect(translateAuthError('web-network-request-failed'), isA<AuthNetworkFailure>());
  });

  test('остальное: понятное сообщение, а не пустота', () {
    for (final String code in ['operation-not-allowed', 'user-disabled', 'too-many-requests', 'strange-code']) {
      final AuthFailure failure = translateAuthError(code);
      expect(failure, isA<AuthUnknownFailure>(), reason: code);
      expect(failure.message, isNotEmpty, reason: code);
    }
    expect(translateAuthError('strange-code').message, contains('strange-code'));
  });

  test('у каждой ошибки есть сообщение для человека', () {
    for (final AuthFailure f in const [
      SignInCancelled(),
      AccountExistsWithOtherProvider(),
      AuthNetworkFailure(),
      AuthUnknownFailure(),
    ]) {
      expect(f.message, isNotEmpty);
    }
  });
}

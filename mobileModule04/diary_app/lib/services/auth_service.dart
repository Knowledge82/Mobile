import '../models/app_user.dart';

// Чем входим. Сабж требует Google или GitHub.
enum SignInProvider {
  google('Google'),
  github('GitHub');

  const SignInProvider(this.label);

  final String label;
}

// Что может пойти не так при входе. sealed: компилятор заставит учесть ВСЕ виды
// в switch (так же, как WeatherFailure в модуле 02).
sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  // Фраза для пользователя (на английском: язык интерфейса приложения).
  final String message;

  @override
  String toString() => message;
}

// Пользователь закрыл окно входа или нажал «назад». Это НЕ ошибка:
// никакого сообщения показывать не надо.
class SignInCancelled extends AuthFailure {
  const SignInCancelled() : super('Sign-in was cancelled.');
}

// Такая почта уже зарегистрирована у ДРУГОГО способа входа (например, вы входили
// через Google, а теперь нажали GitHub с той же почтой). Firebase по умолчанию
// разрешает один аккаунт на почту.
class AccountExistsWithOtherProvider extends AuthFailure {
  const AccountExistsWithOtherProvider()
    : super(
        'This email is already used with another sign-in method. '
        'Try the other button (Google or GitHub).',
      );
}

class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure()
    : super('No internet connection. Check your network and try again.');
}

class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure([String details = ''])
    : super(details == '' ? 'Sign-in failed. Please try again.' : 'Sign-in failed: $details');
}

// Вход и выход. Интерфейс описывает ЧТО нужно экранам, а не КАК это делает Firebase.
abstract interface class AuthService {
  // Кто вошёл прямо сейчас (null: никто). Firebase восстанавливает сессию сам,
  // поэтому после перезапуска приложения здесь сразу будет прошлый пользователь.
  AppUser? get currentUser;

  // Поток «кто вошёл»: сразу присылает текущее состояние, затем каждое изменение
  // (вход, выход, отзыв доступа).
  Stream<AppUser?> authStateChanges();

  // Вход выбранным способом. Бросает AuthFailure (включая SignInCancelled).
  Future<AppUser> signIn(SignInProvider provider);

  Future<void> signOut();
}

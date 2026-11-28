import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/app_user.dart';
import 'auth_service.dart';

// Настоящий вход через Firebase Authentication.
//
// И Google, и GitHub идут ОДНИМ способом: Firebase открывает страницу входа
// провайдера (на Android во вкладке Chrome Custom Tab), пользователь входит, и
// Firebase возвращает вошедшего пользователя. Отдельный пакет google_sign_in
// не нужен: так входят в официальном примере FlutterFire.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toAppUser);

  @override
  Future<AppUser> signIn(SignInProvider provider) async {
    final AuthProvider authProvider = switch (provider) {
      SignInProvider.google => GoogleAuthProvider(),
      // Без этой области GitHub не отдаёт приватную почту, а сабж требует
      // хранить почту пользователя в записи.
      SignInProvider.github => GithubAuthProvider()..addScope('user:email'),
    };

    try {
      // В вебе окно входа это всплывающее окно браузера, на телефоне это
      // «нативный» поток Firebase (вкладка Chrome).
      final UserCredential credential = kIsWeb
          ? await _auth.signInWithPopup(authProvider)
          : await _auth.signInWithProvider(authProvider);

      final AppUser? user = _toAppUser(credential.user);
      if (user == null) throw const AuthUnknownFailure('no user returned');
      return user;
    } on FirebaseAuthException catch (e) {
      throw translateAuthError(e.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  // Firebase-пользователь -> наш AppUser. Почта бывает не в user.email, а только
  // в данных провайдера (так у GitHub), поэтому ищем и там.
  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    final String email =
        user.email ??
        user.providerData
            .map((UserInfo info) => info.email)
            .whereType<String>()
            .where((String e) => e.isNotEmpty)
            .firstOrNull ??
        '';
    return AppUser(uid: user.uid, email: email, displayName: user.displayName);
  }
}

// Код ошибки Firebase -> наша ошибка. Вынесено отдельной функцией, чтобы
// проверять тестом, не создавая FirebaseAuthException.
//
// Коды сверены со справкой FlutterFire («Error Handling»):
//   web-context-canceled / web-context-cancelled  закрыли окно входа (Android / iOS)
//   popup-closed-by-user, cancelled-popup-request, redirect-cancelled-by-user  (веб)
//   user-cancelled                                 не выдали запрошенные права
AuthFailure translateAuthError(String code) {
  switch (code) {
    case 'web-context-canceled':
    case 'web-context-cancelled':
    case 'popup-closed-by-user':
    case 'cancelled-popup-request':
    case 'redirect-cancelled-by-user':
    case 'user-cancelled':
    case 'canceled':
      return const SignInCancelled();
    case 'account-exists-with-different-credential':
      return const AccountExistsWithOtherProvider();
    case 'network-request-failed':
    case 'web-network-request-failed':
      return const AuthNetworkFailure();
    case 'operation-not-allowed':
      return const AuthUnknownFailure('this sign-in method is not enabled in Firebase');
    case 'user-disabled':
      return const AuthUnknownFailure('this account is disabled');
    case 'too-many-requests':
      return const AuthUnknownFailure('too many attempts, wait a bit');
    default:
      return AuthUnknownFailure(code);
  }
}

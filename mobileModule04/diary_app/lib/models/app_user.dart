// Вошедший пользователь, как его видит приложение. Это НАШ класс, а не
// firebase_auth.User: экраны ничего не знают о Firebase, поэтому их можно
// проверять на подделках без интернета и без проекта Firebase.
class AppUser {
  const AppUser({required this.uid, required this.email, this.displayName});

  // Постоянный идентификатор пользователя (по нему лежат его записи в базе).
  final String uid;

  // Почта. У GitHub-аккаунта она бывает скрыта, тогда здесь пустая строка.
  final String email;

  final String? displayName;

  // Как подписать человека на экране: имя, иначе почта, иначе uid.
  String get label {
    final String? name = displayName;
    if (name != null && name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    return uid;
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);

  @override
  String toString() => 'AppUser($uid, $email)';
}

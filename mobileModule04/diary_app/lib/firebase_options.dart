// ЗАГЛУШКА. Этот файл заменяет команда `flutterfire configure`: она создаёт
// настоящий firebase_options.dart с идентификаторами ВАШЕГО проекта Firebase
// (они не секретные: защита данных держится на правилах базы, см. firestore.rules).
//
// Пока файл не заменён, приложение показывает экран с инструкцией, а не падает.
// Пошагово: docs/04-ex00.md, раздел «Настройка Firebase».

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// Имя класса и свойства совпадают с тем, что генерирует flutterfire configure,
// поэтому после замены остальной код менять не нужно.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured yet. Run `flutterfire configure` in the project '
      'folder (see docs/04-ex00.md).',
    );
  }
}

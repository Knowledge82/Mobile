import '../models/diary_entry.dart';

// Что может пойти не так при работе с базой.
sealed class DiaryFailure implements Exception {
  const DiaryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

// Правила базы не пустили (не тот пользователь, не прошла проверка данных).
class DiaryPermissionDenied extends DiaryFailure {
  const DiaryPermissionDenied()
    : super('The database refused this action. Try signing out and in again.');
}

// Нет связи с сервером.
class DiaryUnavailable extends DiaryFailure {
  const DiaryUnavailable()
    : super('Cannot reach the database. Check your internet connection.');
}

class DiaryUnknownFailure extends DiaryFailure {
  const DiaryUnknownFailure([String details = ''])
    : super(details == '' ? 'Something went wrong with the diary.' : 'Something went wrong: $details');
}

// Хранилище записей. Экраны знают только этот интерфейс; настоящая работа с
// Firestore спрятана в FirestoreDiaryRepository, а в тестах стоит подделка.
abstract interface class DiaryRepository {
  // Живой список записей пользователя, новые сверху. Присылает новый список при
  // каждом изменении (добавили, удалили, пришло с другого устройства), поэтому
  // экрану не нужно «обновлять» его вручную. Ошибки приходят как error в потоке.
  Stream<List<DiaryEntry>> watchEntries(String userId);

  // Создать запись. Future завершается, когда СЕРВЕР подтвердил: без сети он
  // может висеть долго (а запись при этом уже видна в watchEntries).
  Future<void> add(String userId, EntryDraft draft);

  // Удалить запись (то же замечание про ожидание сервера).
  Future<void> delete(String userId, String entryId);
}

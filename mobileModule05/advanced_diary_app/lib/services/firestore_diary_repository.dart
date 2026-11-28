import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diary_entry.dart';
import 'diary_repository.dart';
import 'entry_mapper.dart';

// Настоящее хранилище на Cloud Firestore.
//
// Где лежат записи:  users/{uid}/entries/{id}
//   users            коллекция пользователей (документов-«папок», самих данных в них нет)
//   {uid}            идентификатор пользователя из Firebase Auth
//   entries          его записи; у каждой автоматический id
//
// Так «чужие» записи недоступны по самому ПУТИ (правила в firestore.rules
// сверяют uid из пути с uid вошедшего), и не нужен составной индекс.
class FirestoreDiaryRepository implements DiaryRepository {
  FirestoreDiaryRepository([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _entries(String userId) =>
      _db.collection('users').doc(userId).collection('entries');

  @override
  Stream<List<DiaryEntry>> watchEntries(String userId) {
    return _entries(userId)
        .orderBy(fieldDate, descending: true) // новые сверху
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => [
            for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs)
              entryFromMap(doc.id, doc.data()),
          ],
        )
        .transform(
          StreamTransformer<List<DiaryEntry>, List<DiaryEntry>>.fromHandlers(
            handleError: (Object error, StackTrace stack, EventSink<List<DiaryEntry>> sink) {
              sink.addError(_translate(error), stack);
            },
          ),
        );
  }

  @override
  Future<void> add(String userId, EntryDraft draft) async {
    try {
      await _entries(userId).add(draftToMap(draft));
    } catch (e) {
      throw _translate(e);
    }
  }

  @override
  Future<void> delete(String userId, String entryId) async {
    try {
      await _entries(userId).doc(entryId).delete();
    } catch (e) {
      throw _translate(e);
    }
  }

  // Ошибка Firestore -> наша. Коды: permission-denied (правила не пустили),
  // unavailable (нет связи).
  static DiaryFailure _translate(Object error) {
    if (error is DiaryFailure) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const DiaryPermissionDenied();
        case 'unavailable':
          return const DiaryUnavailable();
      }
      return DiaryUnknownFailure(error.code);
    }
    return DiaryUnknownFailure('$error');
  }
}

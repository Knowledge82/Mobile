// Подделки сервисов для тестов: никакого Firebase, интернета и проекта в облаке.
// Экраны знают только интерфейсы AuthService и DiaryRepository, поэтому
// подменить их тут просто.

import 'dart:async';

import 'package:advanced_diary_app/models/app_user.dart';
import 'package:advanced_diary_app/models/diary_entry.dart';
import 'package:advanced_diary_app/models/feeling.dart';
import 'package:advanced_diary_app/services/auth_service.dart';
import 'package:advanced_diary_app/services/diary_repository.dart';

const AppUser alice = AppUser(uid: 'u-alice', email: 'alice@example.com', displayName: 'Alice');
const AppUser noMail = AppUser(uid: 'u-gh', email: '', displayName: null);

class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? signedIn}) : _user = signedIn;

  AppUser? _user;
  final StreamController<AppUser?> _changes = StreamController<AppUser?>.broadcast();

  // Кого «пустит» signIn.
  AppUser userToSignIn = alice;

  // Если задана, signIn бросит её (проверка сообщений об ошибках).
  AuthFailure? failure;

  // Если задан, signIn ждёт его завершения (проверка «идёт вход»).
  Completer<void>? gate;

  final List<SignInProvider> signInCalls = [];
  int signOutCalls = 0;

  @override
  AppUser? get currentUser => _user;

  // Как у Firebase: сразу текущее состояние, потом каждое изменение.
  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<AppUser> signIn(SignInProvider provider) async {
    signInCalls.add(provider);
    final Completer<void>? g = gate;
    if (g != null) await g.future;
    final AuthFailure? f = failure;
    if (f != null) throw f;
    _user = userToSignIn;
    _changes.add(_user);
    return userToSignIn;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _changes.add(null);
  }

  // «Вход пропал сам» (токен отозван, выход с другого устройства).
  void expireSession() {
    _user = null;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

class FakeDiaryRepository implements DiaryRepository {
  FakeDiaryRepository({List<DiaryEntry> entries = const [], this.owner = 'u-alice'}) {
    _entries.addAll(entries);
  }

  // Чьи записи лежат в подделке (остальные пользователи получат пустой список).
  final String owner;

  final List<DiaryEntry> _entries = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  // Если задана, watchEntries выдаст эту ошибку вместо списка.
  DiaryFailure? watchFailure;

  // true: список не присылается совсем (экран «загрузка»).
  bool silent = false;

  // Если задан, add/delete применяются локально (список обновился), но Future
  // не завершается, пока его не завершат: так ведёт себя Firestore без сети.
  Completer<void>? writeGate;

  // Если задана, add/delete бросают её (правила базы не пустили).
  DiaryFailure? writeFailure;

  final List<String> watchCalls = [];
  final List<EntryDraft> added = [];
  final List<String> deleted = [];

  List<DiaryEntry> get entries => List.unmodifiable(_entries);

  List<DiaryEntry> _sorted() {
    final List<DiaryEntry> copy = [..._entries];
    copy.sort((DiaryEntry a, DiaryEntry b) => b.date.compareTo(a.date)); // новые сверху
    return copy;
  }

  @override
  Stream<List<DiaryEntry>> watchEntries(String userId) {
    watchCalls.add(userId);
    final DiaryFailure? failure = watchFailure;
    if (failure != null) return Stream<List<DiaryEntry>>.error(failure);

    return Stream<List<DiaryEntry>>.multi((MultiStreamController<List<DiaryEntry>> controller) {
      List<DiaryEntry> snapshot() => userId == owner ? _sorted() : <DiaryEntry>[];
      if (!silent) controller.add(snapshot());
      final StreamSubscription<void> sub = _changes.stream.listen((_) {
        if (!silent) controller.add(snapshot());
      });
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> add(String userId, EntryDraft draft) async {
    final DiaryFailure? failure = writeFailure;
    if (failure != null) throw failure;
    added.add(draft);
    _entries.add(
      DiaryEntry(
        id: 'e${_nextId++}',
        email: draft.email,
        date: draft.date,
        title: draft.title,
        feeling: draft.feeling,
        content: draft.content,
      ),
    );
    _changes.add(null);
    final Completer<void>? gate = writeGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> delete(String userId, String entryId) async {
    final DiaryFailure? failure = writeFailure;
    if (failure != null) throw failure;
    deleted.add(entryId);
    _entries.removeWhere((DiaryEntry e) => e.id == entryId);
    _changes.add(null);
    final Completer<void>? gate = writeGate;
    if (gate != null) await gate.future;
  }

  // Принудительно прислать список заново (после ручной правки подделки).
  void notifyChanged() => _changes.add(null);

  Future<void> dispose() => _changes.close();
}

// Несколько готовых записей для тестов списка.
DiaryEntry sampleEntry(
  int n, {
  Feeling feeling = Feeling.satisfied,
  String? title,
  String? content,
  DateTime? date,
}) => DiaryEntry(
  id: 'seed$n',
  email: 'alice@example.com',
  date: date ?? DateTime(2026, 11, n),
  title: title ?? 'Day $n',
  feeling: feeling,
  content: content ?? 'Text of day $n.',
);

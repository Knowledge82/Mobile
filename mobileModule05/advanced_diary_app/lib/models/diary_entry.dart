import 'feeling.dart';

// Что вводит пользователь и что дописывает приложение, ещё БЕЗ номера записи.
// Номер (id) выдаёт база при сохранении, поэтому у «черновика» его нет.
class EntryDraft {
  const EntryDraft({
    required this.email,
    required this.date,
    required this.title,
    required this.feeling,
    required this.content,
  });

  final String email; // почта автора (требование сабжа; у GitHub может быть пустой)
  final DateTime date; // когда записано
  final String title;
  final Feeling feeling; // самочувствие дня
  final String content;
}

// Запись, уже лежащая в базе: черновик плюс её номер.
class DiaryEntry extends EntryDraft {
  const DiaryEntry({
    required this.id,
    required super.email,
    required super.date,
    required super.title,
    required super.feeling,
    required super.content,
  });

  final String id;

  // Равенство по значению нужно тестам («в списке лежит именно эта запись»).
  @override
  bool operator ==(Object other) =>
      other is DiaryEntry &&
      other.id == id &&
      other.email == email &&
      other.date == date &&
      other.title == title &&
      other.feeling == feeling &&
      other.content == content;

  @override
  int get hashCode => Object.hash(id, email, date, title, feeling, content);

  @override
  String toString() => 'DiaryEntry($id, $title)';
}

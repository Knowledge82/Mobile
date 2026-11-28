import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../models/diary_entry.dart';
import '../models/feeling.dart';

// Перевод «запись <-> то, что лежит в Firestore». Отдельно от репозитория, чтобы
// проверять обычными тестами (без базы и без интернета).
//
// Поля документа (имена как в сабже: email, date, title, feeling, content):
//   email    string      почта автора
//   date     timestamp   когда записано
//   title    string      заголовок
//   feeling  string      имя значения Feeling ('satisfied', ...)
//   content  string      текст записи

const String fieldEmail = 'email';
const String fieldDate = 'date';
const String fieldTitle = 'title';
const String fieldFeeling = 'feeling';
const String fieldContent = 'content';

Map<String, Object?> draftToMap(EntryDraft draft) => {
  fieldEmail: draft.email,
  // Timestamp: родной тип даты Firestore (в консоли показывается как дата и время).
  fieldDate: Timestamp.fromDate(draft.date),
  fieldTitle: draft.title,
  fieldFeeling: draft.feeling.name,
  fieldContent: draft.content,
};

// Читаем ТЕРПИМО: пропавшее или кривое поле даёт безопасное значение, а не
// исключение. Иначе одна испорченная запись (скажем, добавленная руками в
// консоли) уронила бы весь список.
DiaryEntry entryFromMap(String id, Map<String, Object?> data) => DiaryEntry(
  id: id,
  email: _string(data[fieldEmail]),
  date: _date(data[fieldDate]),
  title: _string(data[fieldTitle]),
  feeling: Feeling.fromName(data[fieldFeeling]),
  content: _string(data[fieldContent]),
);

String _string(Object? value) => value is String ? value : '';

DateTime _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0); // дата не читается: «1970»
}

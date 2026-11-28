// Перевод запись <-> документ Firestore. Подробности: docs/04-ex01.md.
//
// ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/models/feeling.dart';
import 'package:diary_app/services/entry_mapper.dart';

void main() {
  final DateTime when = DateTime(2026, 11, 28, 9, 30);
  final EntryDraft draft = EntryDraft(
    email: 'alice@example.com',
    date: when,
    title: 'Saturday',
    feeling: Feeling.dissatisfied,
    content: 'It rained all day.',
  );

  group('draftToMap', () {
    test('ровно пять полей с именами из сабжа', () {
      final Map<String, Object?> map = draftToMap(draft);
      expect(map.keys.toSet(), {'email', 'date', 'title', 'feeling', 'content'});
    });

    test('значения: дата Timestamp, самочувствие строкой-именем', () {
      final Map<String, Object?> map = draftToMap(draft);
      expect(map['email'], 'alice@example.com');
      expect(map['date'], isA<Timestamp>());
      expect((map['date']! as Timestamp).toDate(), when);
      expect(map['title'], 'Saturday');
      expect(map['feeling'], 'dissatisfied');
      expect(map['content'], 'It rained all day.');
    });
  });

  group('entryFromMap', () {
    test('туда и обратно получаем то же самое', () {
      final DiaryEntry entry = entryFromMap('abc', draftToMap(draft));
      expect(entry.id, 'abc');
      expect(entry.email, draft.email);
      expect(entry.date, draft.date);
      expect(entry.title, draft.title);
      expect(entry.feeling, draft.feeling);
      expect(entry.content, draft.content);
    });

    test('пустой документ не роняет, а даёт безопасные значения', () {
      final DiaryEntry entry = entryFromMap('x', <String, Object?>{});
      expect(entry.email, '');
      expect(entry.title, '');
      expect(entry.content, '');
      expect(entry.feeling, Feeling.neutral);
      expect(entry.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('поля неправильных типов тоже не роняют', () {
      final DiaryEntry entry = entryFromMap('x', <String, Object?>{
        'email': 5,
        'date': 'вчера',
        'title': null,
        'feeling': 123,
        'content': ['a'],
      });
      expect(entry.email, '');
      expect(entry.date, DateTime.fromMillisecondsSinceEpoch(0));
      expect(entry.title, '');
      expect(entry.feeling, Feeling.neutral);
      expect(entry.content, '');
    });

    test('самочувствие из примера сабжа («satisfied») читается', () {
      final DiaryEntry entry = entryFromMap('x', <String, Object?>{'feeling': 'satisfied'});
      expect(entry.feeling, Feeling.satisfied);
    });
  });
}

// «Самочувствие»: имена хранятся в базе, поэтому их менять нельзя, а читать
// надо терпимо. Подробности: docs/04-ex01.md.
//
// ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_diary_app/models/feeling.dart';
import 'package:advanced_diary_app/ui/feeling_icon.dart';

void main() {
  test('имена значений это формат хранения: менять нельзя (старые записи сломаются)', () {
    expect(
      Feeling.values.map((Feeling f) => f.name).toList(),
      ['verySatisfied', 'satisfied', 'neutral', 'dissatisfied', 'veryDissatisfied'],
    );
  });

  test('fromName: знакомые имена узнаёт', () {
    for (final Feeling f in Feeling.values) {
      expect(Feeling.fromName(f.name), f);
    }
  });

  test('fromName: незнакомое, пустое и не строка дают neutral, а не исключение', () {
    expect(Feeling.fromName('ecstatic'), Feeling.neutral);
    expect(Feeling.fromName(''), Feeling.neutral);
    expect(Feeling.fromName(null), Feeling.neutral);
    expect(Feeling.fromName(42), Feeling.neutral);
  });

  test('у каждого значения своя подпись, значок и цвет (смысл не только в цвете)', () {
    expect(Feeling.values.map((Feeling f) => f.label).toSet(), hasLength(5));
    expect(Feeling.values.map(feelingIcon).toSet(), hasLength(5));
    expect(Feeling.values.map(feelingColor).toSet(), hasLength(5));
    expect(feelingIcon(Feeling.satisfied), Icons.sentiment_satisfied);
  });
}

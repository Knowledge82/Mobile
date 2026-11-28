// ex00 (профиль): чистая логика «последние записи», проценты, записи за день.
// Подробности: docs/05-ex00.md.
//
// ВАЖНО: тесты не запускались (см. docs/05-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_diary_app/logic/diary_stats.dart';
import 'package:advanced_diary_app/models/diary_entry.dart';
import 'package:advanced_diary_app/models/feeling.dart';

DiaryEntry e(String id, DateTime date, {Feeling feeling = Feeling.neutral}) => DiaryEntry(
  id: id,
  email: 'a@b.c',
  date: date,
  title: 't$id',
  feeling: feeling,
  content: 'c',
);

List<DiaryEntry> withFeelings(List<Feeling> feelings) => [
  for (int i = 0; i < feelings.length; i++) e('f$i', DateTime(2026, 11, 1 + i), feeling: feelings[i]),
];

int sumPercent(List<FeelingShare> shares) => shares.fold(0, (int s, FeelingShare x) => s + x.percent);

void main() {
  group('lastEntries', () {
    test('пустой список даёт пустой список', () {
      expect(lastEntries([], 2), isEmpty);
    });

    test('берёт самые новые, не больше count', () {
      final List<DiaryEntry> entries = [
        e('a', DateTime(2026, 11, 3)),
        e('b', DateTime(2026, 11, 9)),
        e('c', DateTime(2026, 11, 5)),
        e('d', DateTime(2026, 11, 1)),
      ];

      expect(lastEntries(entries, 2).map((x) => x.id), ['b', 'c']);
    });

    test('записей меньше, чем просили: отдаёт сколько есть', () {
      expect(lastEntries([e('a', DateTime(2026, 11, 3))], 2), hasLength(1));
    });

    test('не полагается на порядок входа и не меняет входной список', () {
      final List<DiaryEntry> entries = [e('old', DateTime(2026, 1, 1)), e('new', DateTime(2026, 12, 1))];

      lastEntries(entries, 1);

      expect(entries.map((x) => x.id), ['old', 'new']); // исходный порядок цел
      expect(lastEntries(entries, 1).single.id, 'new');
    });

    test('одинаковые даты: порядок определён по id (не «как повезёт»)', () {
      final DateTime same = DateTime(2026, 11, 3, 10);
      final List<DiaryEntry> a = [e('b', same), e('a', same)];
      final List<DiaryEntry> b = [e('a', same), e('b', same)];

      expect(lastEntries(a, 2).map((x) => x.id), lastEntries(b, 2).map((x) => x.id));
    });
  });

  group('feelingShares', () {
    test('нет записей: пять строк, везде 0 и 0%', () {
      final List<FeelingShare> shares = feelingShares([]);

      expect(shares.map((s) => s.feeling), Feeling.values);
      expect(shares.every((s) => s.count == 0 && s.percent == 0), isTrue);
    });

    test('одна запись: 100% у её самочувствия, у остальных 0%', () {
      final List<FeelingShare> shares = feelingShares(withFeelings([Feeling.dissatisfied]));

      expect(shares.firstWhere((s) => s.feeling == Feeling.dissatisfied).percent, 100);
      expect(sumPercent(shares), 100);
    });

    test('ровные доли: 1 из 4 это 25%', () {
      final List<FeelingShare> shares = feelingShares(
        withFeelings([Feeling.satisfied, Feeling.neutral, Feeling.neutral, Feeling.neutral]),
      );

      expect(shares.firstWhere((s) => s.feeling == Feeling.satisfied).percent, 25);
      expect(shares.firstWhere((s) => s.feeling == Feeling.neutral).percent, 75);
    });

    test('три равные трети: сумма всё равно 100 (метод наибольших остатков)', () {
      final List<FeelingShare> shares = feelingShares(
        withFeelings([Feeling.verySatisfied, Feeling.satisfied, Feeling.neutral]),
      );

      expect(sumPercent(shares), 100); // обычное round() дало бы 99
      // лишний процент достался первому по порядку из равных остатков
      expect(shares[0].percent, 34);
      expect(shares[1].percent, 33);
      expect(shares[2].percent, 33);
    });

    test('шесть записей (1, 1, 1, 1, 2): наивное round() дало бы 101, мы даём ровно 100', () {
      final List<FeelingShare> shares = feelingShares(
        withFeelings([
          Feeling.verySatisfied, Feeling.satisfied, Feeling.neutral,
          Feeling.dissatisfied, Feeling.veryDissatisfied, Feeling.veryDissatisfied,
        ]),
      );

      // 16,67 -> 17 четыре раза и 33,33 -> 33 дали бы 17*4 + 33 = 101
      expect(shares.map((s) => s.percent), [17, 17, 17, 16, 33]);
      expect(sumPercent(shares), 100);
    });

    test('сумма равна 100 при любом числе записей от 1 до 40 (перебор)', () {
      for (int n = 1; n <= 40; n++) {
        final List<Feeling> feelings = [for (int i = 0; i < n; i++) Feeling.values[(i * 7 + i ~/ 3) % 5]];
        final List<FeelingShare> shares = feelingShares(withFeelings(feelings));

        expect(sumPercent(shares), 100, reason: 'n = $n');
        expect(shares.fold(0, (int s, FeelingShare x) => s + x.count), n, reason: 'n = $n');
      }
    });

    test('самый частый никогда не выглядит реже менее частого', () {
      final List<FeelingShare> shares = feelingShares(
        withFeelings([
          Feeling.satisfied, Feeling.satisfied, Feeling.satisfied,
          Feeling.neutral, Feeling.neutral,
          Feeling.veryDissatisfied,
        ]),
      );

      for (final FeelingShare a in shares) {
        for (final FeelingShare b in shares) {
          if (a.count > b.count) expect(a.percent, greaterThanOrEqualTo(b.percent));
        }
      }
    });

    test('порядок строк всегда как в enum', () {
      final List<FeelingShare> shares = feelingShares(withFeelings([Feeling.veryDissatisfied]));

      expect(shares.map((s) => s.feeling), Feeling.values);
    });
  });

  group('записи за день', () {
    final DateTime day = DateTime(2026, 11, 28);

    test('находит записи этого дня независимо от времени суток', () {
      final List<DiaryEntry> entries = [
        e('early', DateTime(2026, 11, 28, 0, 0)),
        e('late', DateTime(2026, 11, 28, 23, 59)),
        e('prev', DateTime(2026, 11, 27, 23, 59)),
        e('next', DateTime(2026, 11, 29, 0, 0)),
      ];

      expect(entriesOnDay(entries, day).map((x) => x.id), ['late', 'early']); // поздние сверху
    });

    test('другой год или месяц с тем же числом не считается', () {
      final List<DiaryEntry> entries = [
        e('oct', DateTime(2026, 10, 28, 12)),
        e('y25', DateTime(2025, 11, 28, 12)),
      ];

      expect(entriesOnDay(entries, day), isEmpty);
    });

    test('isSameDay: время суток не важно', () {
      expect(isSameDay(DateTime(2026, 11, 28, 1), DateTime(2026, 11, 28, 23)), isTrue);
      expect(isSameDay(DateTime(2026, 11, 28), DateTime(2026, 11, 29)), isFalse);
    });

    test('entryCountsByDay считает записи по дням', () {
      final Map<DateTime, int> counts = entryCountsByDay([
        e('1', DateTime(2026, 11, 28, 8)),
        e('2', DateTime(2026, 11, 28, 20)),
        e('3', DateTime(2026, 11, 27, 9)),
      ]);

      expect(counts[DateTime(2026, 11, 28)], 2);
      expect(counts[DateTime(2026, 11, 27)], 1);
      expect(counts[DateTime(2026, 11, 26)], isNull);
    });
  });
}

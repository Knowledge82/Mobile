// ex01 (ежедневник): арифметика календаря. Подробности: docs/05-ex01.md.
//
// ВАЖНО: тесты не запускались (см. docs/05-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_diary_app/logic/calendar_math.dart';

void main() {
  group('daysInMonth', () {
    test('обычные месяцы', () {
      expect(daysInMonth(2026, 11), 30);
      expect(daysInMonth(2026, 12), 31); // декабрь: «следующий месяц» это январь следующего года
      expect(daysInMonth(2026, 1), 31);
    });

    test('февраль: високосный и обычный год', () {
      expect(daysInMonth(2024, 2), 29);
      expect(daysInMonth(2026, 2), 28);
      expect(daysInMonth(2100, 2), 28); // 2100 не високосный (делится на 100, но не на 400)
      expect(daysInMonth(2000, 2), 29);
    });
  });

  group('addMonths', () {
    test('вперёд и назад в пределах года', () {
      expect(addMonths(DateTime(2026, 5, 17), 1), DateTime(2026, 6));
      expect(addMonths(DateTime(2026, 5, 17), -2), DateTime(2026, 3));
    });

    test('через границу года', () {
      expect(addMonths(DateTime(2026, 12, 31), 1), DateTime(2027, 1));
      expect(addMonths(DateTime(2026, 1, 15), -1), DateTime(2025, 12));
      expect(addMonths(DateTime(2026, 11), 14), DateTime(2028, 1));
    });

    test('31 января плюс месяц не «перескакивает» в март', () {
      // Если бы прибавляли к дню, 31 января + 1 месяц дало бы 3 марта. Мы всегда
      // возвращаем ПЕРВОЕ число месяца, поэтому такой ошибки нет.
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2));
    });
  });

  group('monthGrid', () {
    test('ноябрь 2026: шесть недель с 26 октября по 6 декабря', () {
      final List<List<DateTime>> grid = monthGrid(DateTime(2026, 11, 15));

      expect(grid, hasLength(6)); // 1 ноября 2026 воскресенье: 6 дней хвоста + 30 = 36 клеток -> 6 недель
      expect(grid.first.first, DateTime(2026, 10, 26)); // понедельник
      expect(grid.last.last, DateTime(2026, 12, 6)); // воскресенье
    });

    test('февраль 2027 начинается с понедельника и умещается в четыре недели', () {
      final List<List<DateTime>> grid = monthGrid(DateTime(2027, 2));

      expect(grid, hasLength(4));
      expect(grid.first.first, DateTime(2027, 2, 1));
      expect(grid.last.last, DateTime(2027, 2, 28));
    });

    test('в каждой неделе семь дней, первая клетка понедельник', () {
      for (int m = 1; m <= 12; m++) {
        for (final List<DateTime> week in monthGrid(DateTime(2026, m))) {
          expect(week, hasLength(7), reason: 'месяц $m');
          expect(week.first.weekday, DateTime.monday, reason: 'месяц $m');
          expect(week.last.weekday, DateTime.sunday, reason: 'месяц $m');
        }
      }
    });

    test('все дни месяца присутствуют ровно по одному разу', () {
      for (int m = 1; m <= 12; m++) {
        final List<DateTime> inMonth = [
          for (final List<DateTime> week in monthGrid(DateTime(2026, m)))
            for (final DateTime d in week)
              if (d.month == m) d,
        ];

        expect(inMonth, hasLength(daysInMonth(2026, m)), reason: 'месяц $m');
        expect(inMonth.map((d) => d.day).toSet(), hasLength(daysInMonth(2026, m)), reason: 'месяц $m');
      }
    });

    test('дни идут подряд без пропусков и повторов (в том числе вокруг перехода на летнее время)', () {
      // Март 2026: в Европе переход на летнее время 29 марта. Если строить дни
      // прибавлением 24 часов, день мог бы повториться или пропасть.
      for (final DateTime month in [DateTime(2026, 3), DateTime(2026, 10), DateTime(2026, 11)]) {
        final List<DateTime> days = [for (final List<DateTime> w in monthGrid(month)) ...w];
        for (int i = 1; i < days.length; i++) {
          final DateTime p = days[i - 1];
          expect(days[i].year == DateTime(p.year, p.month, p.day + 1).year, isTrue);
          expect(days[i].month, DateTime(p.year, p.month, p.day + 1).month, reason: '$month, $i');
          expect(days[i].day, DateTime(p.year, p.month, p.day + 1).day, reason: '$month, $i');
        }
      }
    });

    test('декабрь: хвост уходит в январь следующего года', () {
      final List<List<DateTime>> grid = monthGrid(DateTime(2026, 12));

      expect(grid.last.last.year >= 2026, isTrue);
      expect(grid.expand((w) => w).any((d) => d == DateTime(2027, 1, 1)), isTrue);
    });
  });

  test('dateOnly и firstOfMonth отбрасывают лишнее', () {
    expect(dateOnly(DateTime(2026, 11, 28, 23, 59, 59)), DateTime(2026, 11, 28));
    expect(firstOfMonth(DateTime(2026, 11, 28, 23)), DateTime(2026, 11));
  });
}

// Арифметика месячного календаря. Чистые функции без Flutter.
//
// Почему своя, а не пакет table_calendar: раздел «Решения» в docs/05-ex01.md.

// Начало дня (00:00 по местному времени).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// Первое число месяца.
DateTime firstOfMonth(DateTime d) => DateTime(d.year, d.month);

// Сдвиг на n месяцев вперёд (или назад при отрицательном n); возвращает первое число
// нового месяца. DateTime(год, месяц + n) сам «переливает» месяцы через границу года
// (месяц 13 это январь следующего года), поэтому ручной арифметики не нужно.
DateTime addMonths(DateTime d, int n) => DateTime(d.year, d.month + n);

// Количество дней в месяце: нулевой день следующего месяца это последний день этого.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

// Сетка месяца: список недель по 7 дней, начиная с понедельника.
//
// В неё входят и «хвосты» соседних месяцев (чтобы первая и последняя недели были
// полными), поэтому в сетке от 4 до 6 недель. Дни возвращаются как «полночь по
// местному времени». Строим через DateTime(год, месяц, день + i), а не прибавлением
// Duration(days: 1): при переходе на летнее время в сутках бывает 23 или 25 часов,
// и прибавление 24 часов давало бы «сдвиг на час» и повторяющийся день.
List<List<DateTime>> monthGrid(DateTime month) {
  final DateTime first = firstOfMonth(month);
  final int leading = first.weekday - DateTime.monday; // сколько дней до понедельника (0..6)
  final DateTime start = DateTime(first.year, first.month, 1 - leading);

  final int total = leading + daysInMonth(first.year, first.month);
  final int weeks = (total / 7).ceil();

  return [
    for (int w = 0; w < weeks; w++)
      [for (int d = 0; d < 7; d++) DateTime(start.year, start.month, start.day + w * 7 + d)],
  ];
}

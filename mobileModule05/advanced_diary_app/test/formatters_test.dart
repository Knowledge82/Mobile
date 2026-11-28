// Форматирование дат. ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_diary_app/ui/formatters.dart';

void main() {
  test('formatDate: нули в месяце и дне', () {
    expect(formatDate(DateTime(2026, 11, 28)), '2026-11-28');
    expect(formatDate(DateTime(2026, 3, 5)), '2026-03-05');
  });

  test('formatDateTime: час и минуты с нулями', () {
    expect(formatDateTime(DateTime(2026, 11, 28, 9, 5)), '2026-11-28 09:05');
    expect(formatDateTime(DateTime(2026, 11, 28, 23, 59)), '2026-11-28 23:59');
  });

  test('formatTime: нули в часах и минутах', () {
    expect(formatTime(DateTime(2026, 1, 2, 9, 5)), '09:05');
    expect(formatTime(DateTime(2026, 1, 2, 23, 59)), '23:59');
    expect(formatTime(DateTime(2026, 1, 2, 0, 0)), '00:00');
  });

  test('formatMonth и formatLongDate: английские названия месяцев', () {
    expect(formatMonth(DateTime(2026, 11, 28)), 'November 2026');
    expect(formatMonth(DateTime(2027, 1, 1)), 'January 2027');
    expect(formatLongDate(DateTime(2026, 11, 28)), '28 November 2026');
    expect(formatLongDate(DateTime(2026, 3, 5)), '5 March 2026'); // день без нуля
  });

  test('имён месяцев двенадцать, дней недели семь, неделя с понедельника', () {
    expect(monthNames, hasLength(12));
    expect(weekdayShortNames, hasLength(7));
    expect(weekdayShortNames.first, 'Mon');
  });
}

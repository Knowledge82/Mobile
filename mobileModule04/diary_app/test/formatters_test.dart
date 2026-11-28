// Форматирование дат. ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/ui/formatters.dart';

void main() {
  test('formatDate: нули в месяце и дне', () {
    expect(formatDate(DateTime(2026, 11, 28)), '2026-11-28');
    expect(formatDate(DateTime(2026, 3, 5)), '2026-03-05');
  });

  test('formatDateTime: час и минуты с нулями', () {
    expect(formatDateTime(DateTime(2026, 11, 28, 9, 5)), '2026-11-28 09:05');
    expect(formatDateTime(DateTime(2026, 11, 28, 23, 59)), '2026-11-28 23:59');
  });
}

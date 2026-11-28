// Арифметика графика: чистые функции, проверяются без экрана.
//
// ВАЖНО: тесты не запускались (см. docs/03-ex03.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_weather_app/ui/chart_math.dart';

void main() {
  group('niceTicks', () {
    test('шаг 2 для диапазона 3..11', () {
      expect(niceTicks(3, 11), [2, 4, 6, 8, 10, 12]);
    });

    test('границы округляются наружу, нули в середине', () {
      expect(niceTicks(-3.2, 14.8), [-5, 0, 5, 10, 15]);
    });

    test('большой диапазон: шаг 20', () {
      expect(niceTicks(0, 100), [0, 20, 40, 60, 80, 100]);
    });

    test('все значения равны: окно ±1, без деления на ноль', () {
      expect(niceTicks(5, 5), [4, 4.5, 5, 5.5, 6]);
    });

    test('перепутанные границы работают как обычные', () {
      expect(niceTicks(11, 3), niceTicks(3, 11));
    });

    test('мелкие дробные значения: без «хвостов» вида 0.30000000000000004', () {
      final List<double> ticks = niceTicks(0.0, 0.7);
      for (final double t in ticks) {
        expect(t.toString().length, lessThan(8), reason: '$t');
      }
    });

    test('свойство: ось всегда накрывает данные и шаг везде одинаковый', () {
      const List<(double, double)> ranges = [
        (-12.4, -3.1),
        (0, 0.4),
        (14.2, 14.9),
        (-0.4, 31.7),
        (100, 1300),
      ];
      for (final (double lo, double hi) in ranges) {
        final List<double> ticks = niceTicks(lo, hi);
        expect(ticks.first, lessThanOrEqualTo(lo), reason: '$lo..$hi');
        expect(ticks.last, greaterThanOrEqualTo(hi), reason: '$lo..$hi');
        expect(ticks.length, inInclusiveRange(2, 9), reason: '$lo..$hi');
        final double step = ticks[1] - ticks[0];
        for (int i = 2; i < ticks.length; i++) {
          expect(ticks[i] - ticks[i - 1], closeTo(step, 1e-9), reason: '$lo..$hi');
        }
      }
    });
  });

  group('labelIndices', () {
    test('24 часа на 6 мест: каждая четвёртая', () {
      expect(labelIndices(24, 6), [0, 4, 8, 12, 16, 20]);
    });

    test('всё помещается: все подписи', () {
      expect(labelIndices(7, 7), [0, 1, 2, 3, 4, 5, 6]);
      expect(labelIndices(7, 20), [0, 1, 2, 3, 4, 5, 6]);
    });

    test('не помещается: через одну/две', () {
      expect(labelIndices(7, 4), [0, 2, 4, 6]);
      expect(labelIndices(7, 3), [0, 3, 6]);
    });

    test('граничные случаи: пусто и нет места', () {
      expect(labelIndices(0, 5), isEmpty);
      expect(labelIndices(5, 0), [0]);
    });
  });

  group('координаты', () {
    test('xAt: крайние точки на краях, одна точка посередине', () {
      expect(xAt(0, 5, 40, 200), 40);
      expect(xAt(4, 5, 40, 200), 240);
      expect(xAt(2, 5, 40, 200), 140);
      expect(xAt(0, 1, 40, 200), 140);
    });

    test('yAt: большее значение выше (меньше Y), экран растёт вниз', () {
      expect(yAt(10, 0, 10, 10, 100), 10); // максимум на верхней границе
      expect(yAt(0, 0, 10, 10, 100), 110); // минимум на нижней
      expect(yAt(5, 0, 10, 10, 100), 60);
      expect(yAt(7, 7, 7, 10, 100), 60); // нулевой диапазон: посередине
    });
  });
}

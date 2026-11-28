import 'dart:math' as math;

// Арифметика графика отдельно от рисования: это чистые функции (число на входе,
// число на выходе), поэтому их проверяют обычными тестами, без экрана.

// «Красивые» значения для горизонтальных линий сетки.
//
// Хотим, чтобы на оси были 2, 4, 6, 8, 10, а не 3.17, 4.61... Шаг выбираем из
// ряда 1, 2, 5 × 10^k (так считают люди), а границы округляем наружу, чтобы
// все данные поместились.
//
//   niceTicks(3.0, 11.0)   ->  [2, 4, 6, 8, 10, 12]   (шаг 2)
//   niceTicks(-3.2, 14.8)  ->  [-5, 0, 5, 10, 15]     (шаг 5, границы наружу)
//   niceTicks(5, 5)        ->  [4, 4.5, 5, 5.5, 6]    (все значения равны: расширяем)
List<double> niceTicks(double min, double max, {int target = 4}) {
  assert(target >= 1);
  if (max < min) {
    final double t = min;
    min = max;
    max = t;
  }
  if (max - min < 1e-9) {
    // Одно и то же число: иначе делим на ноль. Берём окно ±1 вокруг него.
    min -= 1;
    max += 1;
  }

  final double rough = (max - min) / target; // примерный шаг
  final double magnitude = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final double normalized = rough / magnitude; // в диапазоне [1, 10)
  final double step =
      (normalized < 1.5 ? 1 : normalized < 3 ? 2 : normalized < 7 ? 5 : 10) * magnitude;

  final double start = (min / step).floor() * step;
  final double end = (max / step).ceil() * step;
  final int count = ((end - start) / step).round();

  // Считаем start + i * step, а не «прибавляем шаг в цикле»: так ошибки
  // двоичных дробей (0.1 + 0.2) не накапливаются.
  return [for (int i = 0; i <= count; i++) _clean(start + i * step)];
}

// Убирает «хвосты» вида 2.0000000000000004 (результат умножения шага на индекс).
double _clean(double value) => double.parse(value.toStringAsFixed(9));

// Какие подписи по оси X показывать, чтобы они не слипались.
//
// [count] подписей в данных, помещается не больше [maxLabels]. Берём каждую
// step-ю: 24 часа при 6 местах дают 0, 4, 8, 12, 16, 20.
List<int> labelIndices(int count, int maxLabels) {
  if (count <= 0) return const [];
  final int fit = math.max(1, maxLabels);
  final int step = (count / fit).ceil();
  return [for (int i = 0; i < count; i += step) i];
}

// Координата X i-й точки из [count], если область рисования начинается в [left]
// и имеет ширину [width]. Крайние точки лежат на краях области; одна точка
// стоит посередине.
double xAt(int i, int count, double left, double width) =>
    count <= 1 ? left + width / 2 : left + width * i / (count - 1);

// Координата Y значения [value] при оси от [min] (внизу) до [max] (вверху)
// в области рисования высотой [height], начинающейся в [top].
// В экранных координатах Y растёт ВНИЗ, поэтому большее значение даёт меньший Y.
double yAt(double value, double min, double max, double top, double height) {
  if (max - min < 1e-9) return top + height / 2;
  return top + height * (1 - (value - min) / (max - min));
}

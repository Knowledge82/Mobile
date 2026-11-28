import 'package:material_ui/material_ui.dart';

import 'chart_math.dart';

// Одна кривая на графике: подпись (для легенды), значения и цвет.
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.values,
    required this.color,
  });

  final String label;
  final List<double> values; // по одному значению на каждую подпись оси X
  final Color color;
}

// Линейный график: одна или несколько кривых, сетка с подписями температур слева
// и подписями (часы или дни) снизу.
//
// Нарисован вручную через CustomPainter, без пакета для графиков (см. разбор
// ex03, раздел «Альтернативы»). Виджет умеет:
//   - несколько кривых на общих осях (для Weekly: минимум и максимум);
//   - подписи оси X сами «прореживаются», чтобы не слипаться;
//   - легенда над графиком, если кривых больше одной;
//   - работает на пустых данных и на одной точке.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.series,
    required this.xLabels,
    required this.formatY,
    this.height = 200,
    this.semanticsLabel,
  });

  final List<ChartSeries> series;
  final List<String> xLabels;
  final String Function(double value) formatY;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final bool legend = series.length > 1;

    return Semantics(
      label: semanticsLabel,
      image: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (legend)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Wrap(
                spacing: 16,
                children: [
                  for (final ChartSeries s in series)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(s.label, style: Theme.of(context).textTheme.labelLarge),
                      ],
                    ),
                ],
              ),
            ),
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(
                series: series,
                xLabels: xLabels,
                formatY: formatY,
                labelStyle: const TextStyle(fontSize: 11, color: Color(0xCCFFFFFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.series,
    required this.xLabels,
    required this.formatY,
    required this.labelStyle,
  });

  final List<ChartSeries> series;
  final List<String> xLabels;
  final String Function(double value) formatY;
  final TextStyle labelStyle;

  // Поля вокруг области рисования: слева место под подписи температур,
  // снизу под подписи оси X, справа запас, чтобы последняя подпись не обрезалась.
  static const double _left = 40;
  static const double _right = 20;
  static const double _top = 10;
  static const double _bottom = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double> all = [for (final ChartSeries s in series) ...s.values];
    if (all.isEmpty) return; // рисовать нечего

    final double plotWidth = size.width - _left - _right;
    final double plotHeight = size.height - _top - _bottom;
    if (plotWidth <= 0 || plotHeight <= 0) return; // слишком тесно

    // --- ось Y: «красивые» значения, охватывающие все данные ---
    double lo = all.first;
    double hi = all.first;
    for (final double v in all) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final List<double> ticks = niceTicks(lo, hi);
    final double axisMin = ticks.first;
    final double axisMax = ticks.last;

    final Paint gridPaint = Paint()
      ..color = const Color(0x26FFFFFF)
      ..strokeWidth = 1;

    for (final double tick in ticks) {
      final double y = yAt(tick, axisMin, axisMax, _top, plotHeight);
      canvas.drawLine(Offset(_left, y), Offset(size.width - _right, y), gridPaint);
      _drawText(canvas, formatY(tick), Offset(_left - 6, y), alignRight: true);
    }

    // --- ось X: подписи, прореженные по реальной ширине текста ---
    final int count = series.map((ChartSeries s) => s.values.length).reduce((a, b) => a > b ? a : b);
    double widest = 0;
    for (final String label in xLabels) {
      final double w = _measure(label).width;
      if (w > widest) widest = w;
    }
    final int maxLabels = (plotWidth / (widest + 12)).floor(); // +12: зазор между подписями
    for (final int i in labelIndices(xLabels.length, maxLabels)) {
      final double x = xAt(i, count, _left, plotWidth);
      _drawText(canvas, xLabels[i], Offset(x, size.height - _bottom / 2), centerX: true);
    }

    // --- кривые ---
    for (final ChartSeries s in series) {
      _drawSeries(canvas, s, axisMin, axisMax, plotWidth, plotHeight, count);
    }
  }

  void _drawSeries(
    Canvas canvas,
    ChartSeries s,
    double axisMin,
    double axisMax,
    double plotWidth,
    double plotHeight,
    int count,
  ) {
    if (s.values.isEmpty) return;

    final List<Offset> points = [
      for (int i = 0; i < s.values.length; i++)
        Offset(
          xAt(i, count, _left, plotWidth),
          yAt(s.values[i], axisMin, axisMax, _top, plotHeight),
        ),
    ];

    // Плавная линия: между соседними точками S-образная кривая. Контрольные точки
    // стоят на высоте КОНЦОВ отрезка, поэтому линия никогда не «перелетает» выше
    // максимума и ниже минимума (с «умными» сплайнами такое бывает).
    final Path line = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset a = points[i - 1];
      final Offset b = points[i];
      final double midX = (a.dx + b.dx) / 2;
      line.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }

    // Заливка под первой кривой нужна только одиночному графику (Today).
    if (series.length == 1 && points.length > 1) {
      final double bottom = _top + plotHeight;
      final Path fill = Path.from(line)
        ..lineTo(points.last.dx, bottom)
        ..lineTo(points.first.dx, bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.color.withValues(alpha: 0.35), s.color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, _top, 1, plotHeight)),
      );
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Точки: на коротких рядах (неделя) их видно и приятно, на 24 часах это шум.
    if (points.length <= 8) {
      final Paint dot = Paint()..color = s.color;
      for (final Offset p in points) {
        canvas.drawCircle(p, 4, dot);
      }
    }
  }

  TextPainter _measure(String text) =>
      TextPainter(text: TextSpan(text: text, style: labelStyle), textDirection: TextDirection.ltr)
        ..layout();

  // Рисует подпись. [at] это точка привязки: правый край по центру высоты
  // (подписи оси Y) или центр по горизонтали (подписи оси X).
  void _drawText(
    Canvas canvas,
    String text,
    Offset at, {
    bool alignRight = false,
    bool centerX = false,
  }) {
    final TextPainter painter = _measure(text);
    double dx = at.dx;
    if (alignRight) dx -= painter.width;
    if (centerX) dx -= painter.width / 2;
    painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.series != series || old.xLabels != xLabels || old.labelStyle != labelStyle;
}

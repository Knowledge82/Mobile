// Виджет графика: рисуется без исключений на любых данных и размерах.
// (Как именно выглядит картинка, тестом не проверить: это смотрят глазами.)
//
// ВАЖНО: тесты не запускались (см. docs/03-ex03.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:advanced_weather_app/ui/line_chart.dart';

Widget host(Widget chart, {double width = 360, double height = 400}) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: width, height: height, child: chart)),
  ),
);

LineChart chartOf(List<ChartSeries> series, List<String> labels, {double height = 200}) =>
    LineChart(series: series, xLabels: labels, formatY: (double v) => '${v.round()}°', height: height);

const Color blue = Color(0xFF2196F3);
const Color orange = Color(0xFFFF9800);

List<String> days(int n) => [for (int i = 0; i < n; i++) 'D$i'];

void main() {
  testWidgets('одна кривая на 24 точки', (tester) async {
    await tester.pumpWidget(host(chartOf(
      [ChartSeries(label: 'T', values: [for (int i = 0; i < 24; i++) 5.0 + i / 2], color: blue)],
      [for (int i = 0; i < 24; i++) '${i.toString().padLeft(2, '0')}:00'],
    )));

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('две кривые: легенда с подписями', (tester) async {
    await tester.pumpWidget(host(chartOf(
      [
        ChartSeries(label: 'Max', values: const [10, 12, 11, 9, 8, 7, 9], color: orange),
        ChartSeries(label: 'Min', values: const [2, 3, 1, 0, -1, -2, 0], color: blue),
      ],
      days(7),
    )));

    expect(tester.takeException(), isNull);
    expect(find.text('Max'), findsOneWidget);
    expect(find.text('Min'), findsOneWidget);
  });

  testWidgets('одна кривая: легенды нет', (tester) async {
    await tester.pumpWidget(host(chartOf(
      [ChartSeries(label: 'Temperature', values: const [1, 2, 3], color: blue)],
      days(3),
    )));

    expect(find.text('Temperature'), findsNothing);
  });

  testWidgets('пустые данные не роняют', (tester) async {
    await tester.pumpWidget(host(chartOf(
      [ChartSeries(label: 'T', values: const [], color: blue)],
      const [],
    )));
    await tester.pumpWidget(host(chartOf(const [], const [])));

    expect(tester.takeException(), isNull);
  });

  testWidgets('одна точка и одинаковые значения не роняют (деление на ноль)', (tester) async {
    await tester.pumpWidget(host(chartOf(
      [ChartSeries(label: 'T', values: const [5], color: blue)],
      days(1),
    )));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(chartOf(
      [ChartSeries(label: 'T', values: const [5, 5, 5, 5], color: blue)],
      days(4),
    )));
    expect(tester.takeException(), isNull);
  });

  testWidgets('крошечная область: график просто ничего не рисует', (tester) async {
    await tester.pumpWidget(host(
      chartOf([ChartSeries(label: 'T', values: const [1, 2, 3], color: blue)], days(3), height: 20),
      width: 30,
    ));

    expect(tester.takeException(), isNull);
  });

  testWidgets('отрицательные и большие значения', (tester) async {
    await tester.pumpWidget(host(chartOf(
      [ChartSeries(label: 'T', values: const [-40.5, -12, 0, 33.3, 48], color: blue)],
      days(5),
    )));

    expect(tester.takeException(), isNull);
  });

  testWidgets('смысловая подпись для скринридера', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(host(LineChart(
      series: [ChartSeries(label: 'T', values: const [1, 2], color: blue)],
      xLabels: const ['a', 'b'],
      formatY: (double v) => '$v',
      semanticsLabel: 'Temperature chart',
    )));

    expect(find.bySemanticsLabel('Temperature chart'), findsOneWidget);
    handle.dispose();
  });
}

import 'package:material_ui/material_ui.dart';

import '../models/weather_report.dart';
import 'chart_list_page.dart';
import 'formatters.dart';
import 'glass_card.dart';
import 'line_chart.dart';
import 'location_header.dart';
import 'weather_icon.dart';

// Вкладка Weekly: место, график из двух кривых (минимум и максимум по дням)
// и список по дням недели.
class WeeklyView extends StatelessWidget {
  const WeeklyView({super.key, required this.report});

  final WeatherReport report;

  static const Color _maxColor = Color(0xFFFF9F5A); // тёплая: максимум
  static const Color _minColor = Color(0xFF7CC4FF); // холодная: минимум

  @override
  Widget build(BuildContext context) {
    final List<DailyWeather> days = report.daily;

    return ChartListPage(
      // Шапка тоже на «стекле»: без него светлый текст на ярком участке фона
      // (у горизонта) читается плохо (контраст около 3:1 вместо 7:1).
      header: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        radius: 16,
        child: LocationHeader(place: report.place),
      ),
      chart: GlassCard(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: LineChart(
          semanticsLabel: 'Minimum and maximum temperature for the next ${days.length} days',
          formatY: formatAxisTemperature,
          xLabels: [for (final DailyWeather d in days) formatWeekdayShort(d.date)],
          series: [
            ChartSeries(
              label: 'Max',
              values: [for (final DailyWeather d in days) d.maxTemperature],
              color: _maxColor,
            ),
            ChartSeries(
              label: 'Min',
              values: [for (final DailyWeather d in days) d.minTemperature],
              color: _minColor,
            ),
          ],
        ),
      ),
      itemCount: days.length,
      itemBuilder: (BuildContext context, int index) {
        final DailyWeather day = days[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.zero,
          radius: 16,
          child: ListTile(
            leading: Icon(
              weatherIcon(day.weatherCode),
              color: weatherIconColor(day.weatherCode),
              size: 32,
            ),
            title: Text(formatWeekday(day.date)),
            subtitle: Text(day.description),
            trailing: Text(
              'min ${formatTemperature(day.minTemperature)}\n'
              'max ${formatTemperature(day.maxTemperature)}',
              textAlign: TextAlign.end,
            ),
          ),
        );
      },
    );
  }
}

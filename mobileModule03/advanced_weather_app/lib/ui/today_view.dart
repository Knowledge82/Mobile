import 'package:material_ui/material_ui.dart';

import '../models/weather_report.dart';
import 'chart_list_page.dart';
import 'formatters.dart';
import 'glass_card.dart';
import 'line_chart.dart';
import 'location_header.dart';
import 'weather_icon.dart';

// Вкладка Today: место, график температуры за день и список по часам.
class TodayView extends StatelessWidget {
  const TodayView({super.key, required this.report});

  final WeatherReport report;

  static const Color _lineColor = Color(0xFFFFC857); // тёплая линия на тёмном фоне

  @override
  Widget build(BuildContext context) {
    final List<HourlyWeather> hours = report.hourly;

    final List<double> temperatures = [for (final HourlyWeather h in hours) h.temperature];
    final String summary = temperatures.isEmpty
        ? 'No hourly data'
        : 'Temperature today, from ${formatTemperature(_min(temperatures))} '
              'to ${formatTemperature(_max(temperatures))}';

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
          semanticsLabel: summary,
          formatY: formatAxisTemperature,
          xLabels: [for (final HourlyWeather h in hours) formatHour(h.time)],
          series: [
            ChartSeries(label: 'Temperature', values: temperatures, color: _lineColor),
          ],
        ),
      ),
      itemCount: hours.length,
      itemBuilder: (BuildContext context, int index) {
        final HourlyWeather hour = hours[index];
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.zero,
          radius: 16,
          child: ListTile(
            leading: Icon(
              weatherIcon(hour.weatherCode, isDay: hour.isDay),
              color: weatherIconColor(hour.weatherCode, isDay: hour.isDay),
              size: 32,
            ),
            title: Text('${formatHour(hour.time)}  ${hour.description}'),
            subtitle: Row(
              children: [
                const Icon(Icons.air, size: 16),
                const SizedBox(width: 4),
                Flexible(child: Text('Wind: ${formatWind(hour.windSpeed)}')),
              ],
            ),
            trailing: Text(
              formatTemperature(hour.temperature),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  static double _min(List<double> v) => v.reduce((a, b) => a < b ? a : b);
  static double _max(List<double> v) => v.reduce((a, b) => a > b ? a : b);
}

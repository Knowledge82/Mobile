import 'package:material_ui/material_ui.dart';

import '../models/weather_report.dart';
import 'formatters.dart';
import 'location_header.dart';

// Вкладка Weekly: место и список «дата, мин и макс температура, описание».
class WeeklyView extends StatelessWidget {
  const WeeklyView({super.key, required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final List<DailyWeather> days = report.daily;

    return ListView.builder(
      itemCount: days.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: LocationHeader(place: report.place),
          );
        }
        final DailyWeather day = days[index - 1];
        return ListTile(
          title: Text(formatDate(day.date)),
          subtitle: Text(day.description),
          trailing: Text(
            'min ${formatTemperature(day.minTemperature)}\n'
            'max ${formatTemperature(day.maxTemperature)}',
            textAlign: TextAlign.end,
          ),
        );
      },
    );
  }
}

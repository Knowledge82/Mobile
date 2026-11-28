import 'package:material_ui/material_ui.dart';

import '../models/weather_report.dart';
import 'formatters.dart';
import 'location_header.dart';

// Вкладка Today: место и список «час, температура, описание, ветер».
class TodayView extends StatelessWidget {
  const TodayView({super.key, required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final List<HourlyWeather> hours = report.hourly;

    // Заголовок это нулевой элемент ТОГО ЖЕ списка, а не отдельный виджет над ним:
    // тогда всё вместе прокручивается и на низком экране нет overflow.
    return ListView.builder(
      itemCount: hours.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: LocationHeader(place: report.place),
          );
        }
        final HourlyWeather hour = hours[index - 1];
        return ListTile(
          title: Text('${formatHour(hour.time)}  ${hour.description}'),
          subtitle: Text('Wind: ${formatWind(hour.windSpeed)}'),
          trailing: Text(formatTemperature(hour.temperature)),
        );
      },
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../models/weather_report.dart';
import 'formatters.dart';
import 'location_header.dart';

// Вкладка Currently: место, температура, описание, ветер.
class CurrentView extends StatelessWidget {
  const CurrentView({super.key, required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CurrentWeather current = report.current;

    // Тот же приём, что в модуле 01: Center + SingleChildScrollView + Column(min).
    // Ландшафт, клавиатура и крупный шрифт не дадут overflow, а прокрутят.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocationHeader(place: report.place),
            const SizedBox(height: 24),
            Text(
              formatTemperature(current.temperature),
              style: textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              current.description,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Wind: ${formatWind(current.windSpeed)}',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

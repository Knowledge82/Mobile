import 'package:material_ui/material_ui.dart';

import '../models/weather_report.dart';
import 'formatters.dart';
import 'glass_card.dart';
import 'location_header.dart';
import 'weather_icon.dart';

// Вкладка Currently. Читается за три секунды, потому что порядок сверху вниз
// это порядок важности, а размер шрифта показывает, что главное:
//   1. где (город, регион, страна);
//   2. какая погода (крупная иконка и очень крупная температура);
//   3. словами (описание);
//   4. ветер (мельче всего).
class CurrentView extends StatelessWidget {
  const CurrentView({super.key, required this.report});

  final WeatherReport report;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final CurrentWeather current = report.current;

    // Center + SingleChildScrollView + Column(min): по центру, пока места хватает;
    // в ландшафте, с клавиатурой и при крупном шрифте прокручивается без overflow.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocationHeader(place: report.place),
                const SizedBox(height: 24),
                Icon(
                  weatherIcon(current.weatherCode, isDay: current.isDay),
                  size: 96,
                  color: weatherIconColor(current.weatherCode, isDay: current.isDay),
                ),
                const SizedBox(height: 8),
                Text(
                  formatTemperature(current.temperature),
                  style: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w300),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  current.description,
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.air, size: 22),
                    const SizedBox(width: 8),
                    // Flexible: при крупном шрифте на узком экране текст переносится,
                    // а не вылезает за край (иначе overflow в Row).
                    Flexible(
                      child: Text(
                        'Wind: ${formatWind(current.windSpeed)}',
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import 'search_request.dart';
import 'weather_tab.dart';

// Содержимое одной вкладки: её имя и (если был поиск) его результат.
// StatelessWidget: сам ничего не помнит, всё получает от HomePage.
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.tab, required this.request});

  final WeatherTab tab;
  final SearchRequest? request; // null = ещё ничего не искали

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final SearchRequest? request = this.request;

    // Center даёт колонке «свободу»: она занимает ровно столько, сколько нужно,
    // и стоит по центру. SingleChildScrollView страхует от переполнения:
    // повёрнутый экран, клавиатура, огромный шрифт или длинный текст -
    // содержимое просто прокручивается вместо жёлто-чёрной полосы overflow.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.title,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (request != null) ...[
              const SizedBox(height: 8),
              Text(
                request.label,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

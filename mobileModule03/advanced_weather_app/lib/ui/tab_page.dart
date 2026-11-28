import 'package:material_ui/material_ui.dart';

import '../state/weather_state.dart';
import 'current_view.dart';
import 'message_view.dart';
import 'today_view.dart';
import 'weather_tab.dart';
import 'weekly_view.dart';

// Содержимое одной вкладки = функция от (вкладка, состояние).
// Два вложенных switch по закрытым типам: компилятор проверит, что разобраны
// ВСЕ состояния и ВСЕ вкладки.
class TabPage extends StatelessWidget {
  const TabPage({super.key, required this.tab, required this.state});

  final WeatherTab tab;
  final WeatherState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    WeatherIdle() => const SizedBox.shrink(),
    WeatherLoading() => const Center(child: CircularProgressIndicator()),
    WeatherFailed(:final failure) => MessageView(failure: failure),
    WeatherLoaded(:final report) => switch (tab) {
      WeatherTab.currently => CurrentView(report: report),
      WeatherTab.today => TodayView(report: report),
      WeatherTab.weekly => WeeklyView(report: report),
    },
  };
}

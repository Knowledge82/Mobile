import 'package:material_ui/material_ui.dart';

// Три вкладки приложения. Порядок констант = порядок вкладок на экране
// и индекс во TabController (currently = 0, today = 1, weekly = 2).
//
// Enum с полями (enhanced enum, Dart 2.17+): название и иконка лежат рядом
// с самой вкладкой, а не в трёх разных списках, которые легко рассинхронизировать.
enum WeatherTab {
  currently('Currently', Icons.wb_sunny_outlined),
  today('Today', Icons.today_outlined),
  weekly('Weekly', Icons.calendar_month_outlined);

  const WeatherTab(this.title, this.icon);

  final String title;
  final IconData icon;
}

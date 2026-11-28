// СНИМОК ЭТАПА ex00 (модуль 01): весь код в одном файле lib/main.dart.
//
// Что умеет: AppBar с полем поиска и кнопкой (пока ничего не делают),
// нижняя панель из трёх вкладок, переключение нажатием и свайпом,
// на вкладке просто её название. Состояния нет вообще.
//
// Файл лежит в docs/code/ как справка и НЕ входит ни в какой проект:
// чтобы попробовать этап, скопируйте его в weather_app/lib/main.dart
// (и временно уберите остальные файлы из lib/, они понадобятся на ex01).
// Подробности: docs/01-ex00.md.

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const WeatherApp());
}

// Без этого в Chrome вкладки не листаются мышью (только пальцем/тачпадом).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomePage(),
    );
  }
}

// Названия и иконки трёх вкладок. Порядок = порядок на экране.
enum WeatherTab {
  currently('Currently', Icons.wb_sunny_outlined),
  today('Today', Icons.today_outlined),
  weekly('Weekly', Icons.calendar_month_outlined);

  const WeatherTab(this.title, this.icon);

  final String title;
  final IconData icon;
}

// Состояния пока нет, поэтому StatelessWidget.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TabBar tabBar = TabBar(
      dividerColor: Colors.transparent,
      tabs: [
        for (final WeatherTab tab in WeatherTab.values)
          Tab(icon: Icon(tab.icon), text: tab.title),
      ],
    );

    return DefaultTabController(
      length: WeatherTab.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const TextField(
            decoration: InputDecoration(
              hintText: 'Search location...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Geolocation',
              onPressed: () {}, // заглушка: работать начнёт в ex01
            ),
          ],
        ),
        body: TabBarView(
          children: [
            for (final WeatherTab tab in WeatherTab.values)
              Center(
                child: Text(
                  tab.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          height: tabBar.preferredSize.height,
          padding: EdgeInsets.zero,
          child: tabBar,
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

import 'home_page.dart';

void main() {
  runApp(const WeatherApp());
}

// По умолчанию Flutter листает перетаскиванием только пальцем/стилусом/тачпадом,
// а МЫШЬ нет. На телефоне это незаметно, но в Chrome «свайп» вкладок мышью
// не работал бы. Добавляем мышь в список устройств, которыми можно листать.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

// Корневой виджет: тема и первая страница. Больше здесь ничего нет.
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
      home: const HomePage(), // home = первый экран
    );
  }
}

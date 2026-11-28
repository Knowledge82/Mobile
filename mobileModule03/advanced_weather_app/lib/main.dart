import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'services/geocoding_service.dart';
import 'services/location_service.dart';
import 'services/reverse_geocoding_service.dart';
import 'services/weather_service.dart';
import 'state/weather_controller.dart';
import 'ui/app_background.dart';
import 'ui/home_page.dart';

// «Сборочный цех» приложения: здесь, и только здесь, создаются настоящие
// сервисы и склеиваются в контроллер. Всё остальное получает готовое снаружи
// (внедрение зависимостей), поэтому в тестах подставляются подделки.
void main() {
  // Один HTTP-клиент на всё приложение (он держит соединения, их выгодно переиспользовать).
  // Закрывать его не нужно: он живёт, пока живёт приложение.
  final http.Client client = http.Client();

  runApp(
    WeatherApp(
      controller: WeatherController(
        location: const GeolocatorLocationService(),
        geocoding: OpenMeteoGeocodingService(client),
        reverseGeocoding: BigDataCloudReverseGeocodingService(client),
        weather: OpenMeteoWeatherService(client),
      ),
    ),
  );
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
  const WeatherApp({super.key, required this.controller});

  final WeatherController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      // Тёмная тема: светлый текст на фоне-картинке с затемнением читается лучше.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      // builder оборачивает ВСЁ приложение (навигатор и все экраны) один раз:
      // здесь, и только здесь, появляется фон. Вкладки его не создают и не меняют.
      builder: (BuildContext context, Widget? child) =>
          AppBackground(child: child ?? const SizedBox.shrink()),
      home: HomePage(controller: controller),
    );
  }
}

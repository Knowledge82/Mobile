import 'package:material_ui/material_ui.dart';

// Иконка по коду погоды WMO (тот же код, что превращается в текст в
// describeWeatherCode). Иконки берём из встроенного шрифта Material Icons:
// ни картинок, ни пакетов, ни лицензий, и они масштабируются как текст.
//
// [isDay] нужен только ясному небу: днём солнце, ночью луна.
IconData weatherIcon(int code, {bool isDay = true}) => switch (code) {
  0 || 1 => isDay ? Icons.wb_sunny : Icons.nights_stay,
  2 => Icons.wb_cloudy,
  3 => Icons.cloud,
  45 || 48 => Icons.foggy,
  51 || 53 || 55 || 56 || 57 => Icons.grain, // морось
  61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => Icons.water_drop, // дождь
  71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit, // снег
  95 || 96 || 97 || 99 => Icons.thunderstorm,
  _ => Icons.help_outline, // незнакомый код: не падаем, а показываем «?»
};

// Цвет иконки: солнце жёлтое, луна бледная, остальное светлое.
// Цвета подобраны под тёмный фон (контраст важнее «реализма»).
Color weatherIconColor(int code, {bool isDay = true}) => switch (code) {
  0 || 1 => isDay ? const Color(0xFFFFC857) : const Color(0xFFCFD8FF),
  _ => const Color(0xFFE8F1FF),
};

// Превращение чисел и дат в текст для экрана. Отдельно от виджетов, чтобы
// проверять тестами без интерфейса.

// «12.3°C». Округляем до десятых; «-0.0» (так выглядит -0.04) показываем как «0.0».
String formatTemperature(double value) => '${_oneDecimal(value)}°C';

// «10.5 km/h».
String formatWind(double value) => '${_oneDecimal(value)} km/h';

// «08:00».
String formatHour(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

// «2026-11-28» (формат ISO: однозначный и сортируемый; красивые «Sat, 28 Nov»
// потребуют пакета intl, это модуль 03).
String formatDate(DateTime date) =>
    '${date.year}-${_two(date.month)}-${_two(date.day)}';

String _oneDecimal(double value) {
  final String text = value.toStringAsFixed(1);
  return text == '-0.0' ? '0.0' : text;
}

String _two(int value) => value.toString().padLeft(2, '0');

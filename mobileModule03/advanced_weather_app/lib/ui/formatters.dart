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

const List<String> _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

// «Saturday». DateTime.weekday: понедельник = 1 ... воскресенье = 7,
// поэтому индекс в списке это weekday - 1. Без пакета intl (он в следующих модулях).
String formatWeekday(DateTime date) => _weekdays[date.weekday - 1];

// «Sat»: короткая подпись для оси графика.
String formatWeekdayShort(DateTime date) => formatWeekday(date).substring(0, 3);

// «5°»: подпись на оси температур (без «C»: место на оси дорого).
String formatAxisTemperature(double value) => '${value.round()}°';

String _oneDecimal(double value) {
  final String text = value.toStringAsFixed(1);
  return text == '-0.0' ? '0.0' : text;
}

String _two(int value) => value.toString().padLeft(2, '0');

// Форматирование дат без пакета intl (он понадобится для локализации позже).

String _two(int n) => n.toString().padLeft(2, '0');

// «2026-11-28»
String formatDate(DateTime date) => '${date.year}-${_two(date.month)}-${_two(date.day)}';

// «2026-11-28 09:05»
String formatDateTime(DateTime date) => '${formatDate(date)} ${_two(date.hour)}:${_two(date.minute)}';

// «09:05»
String formatTime(DateTime date) => '${_two(date.hour)}:${_two(date.minute)}';

const List<String> monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> weekdayShortNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// «November 2026»
String formatMonth(DateTime date) => '${monthNames[date.month - 1]} ${date.year}';

// «28 November 2026»
String formatLongDate(DateTime date) => '${date.day} ${monthNames[date.month - 1]} ${date.year}';

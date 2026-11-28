// Форматирование дат без пакета intl (он понадобится для локализации позже).

String _two(int n) => n.toString().padLeft(2, '0');

// «2026-11-28»
String formatDate(DateTime date) => '${date.year}-${_two(date.month)}-${_two(date.day)}';

// «2026-11-28 09:05»
String formatDateTime(DateTime date) => '${formatDate(date)} ${_two(date.hour)}:${_two(date.minute)}';

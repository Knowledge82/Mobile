import 'package:material_ui/material_ui.dart';

import '../logic/calendar_math.dart';
import '../logic/diary_stats.dart' show isSameDay;
import 'formatters.dart';

// Ключ ячейки дня: по нему тесты находят нужный день, не гадая по цифрам
// (цифра «30» в сетке ноября встречается дважды: 30 октября и 30 ноября).
ValueKey<String> dayCellKey(DateTime day) => ValueKey<String>(
  'day-${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
);

// Месячный календарь: заголовок со стрелками, подписи дней недели и сетка дней.
// Виджет «глупый»: ничего не помнит. Какой месяц показан и какой день выбран,
// решает тот, кто его построил (AgendaPage), а сюда присылает готовые значения и
// принимает обратно нажатия через колбэки. Такой виджет легко проверять тестом.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.today,
    required this.entryCounts,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onTodayPressed,
  });

  final DateTime month; // любой день показываемого месяца
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, int> entryCounts; // ключ: дата без времени
  final ValueChanged<DateTime> onMonthChanged; // присылает первое число нового месяца
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onTodayPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<List<DateTime>> weeks = monthGrid(month);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
              onPressed: () => onMonthChanged(addMonths(month, -1)),
            ),
            Expanded(
              child: Text(
                formatMonth(month),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
              onPressed: () => onMonthChanged(addMonths(month, 1)),
            ),
            TextButton(onPressed: onTodayPressed, child: const Text('Today')),
          ],
        ),
        Row(
          children: [
            for (final String name in weekdayShortNames)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        for (final List<DateTime> week in weeks)
          Row(
            children: [
              for (final DateTime day in week)
                Expanded(
                  child: _DayCell(
                    key: dayCellKey(day),
                    day: day,
                    inMonth: day.month == month.month,
                    isSelected: isSameDay(day, selected),
                    isToday: isSameDay(day, today),
                    entryCount: entryCounts[day] ?? 0,
                    onTap: () => onDaySelected(day),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.inMonth,
    required this.isSelected,
    required this.isToday,
    required this.entryCount,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isSelected;
  final bool isToday;
  final int entryCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Три признака дня, и ни один не держится на одном цвете: выбранный залит,
    // сегодняшний в рамке, день с записями с точкой под числом.
    final Color textColor = isSelected
        ? colors.onPrimary
        : (inMonth ? colors.onSurface : colors.onSurfaceVariant);

    final String label =
        '${formatLongDate(day)}'
        '${isToday ? ', today' : ''}'
        '${entryCount > 0 ? ', $entryCount ${entryCount == 1 ? 'entry' : 'entries'}' : ''}';

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          height: 48, // не меньше 48: так рекомендует Material для цели нажатия
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colors.primary : null,
                  border: (isToday && !isSelected) ? Border.all(color: colors.primary, width: 1.5) : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: (isSelected || isToday) ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Точка занимает место и когда её нет: иначе числа «прыгали» бы по высоте.
              SizedBox(
                height: 5,
                child: entryCount > 0
                    ? DecoratedBox(
                        decoration: BoxDecoration(color: colors.tertiary, shape: BoxShape.circle),
                        child: const SizedBox(width: 5, height: 5),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

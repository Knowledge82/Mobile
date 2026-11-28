import 'package:material_ui/material_ui.dart';

import '../logic/calendar_math.dart';
import '../logic/diary_stats.dart';
import '../models/diary_entry.dart';
import 'diary_actions.dart';
import 'entry_tile.dart';
import 'formatters.dart';
import 'month_calendar.dart';

// Вкладка «Ежедневник»: календарь и записи выбранного дня.
//
// Открывается на сегодняшней дате (сабж: «календарь показывает текущую дату»).
// Помнит два значения: какой день выбран и какой месяц показан. Записи приходят
// готовыми от HomePage, поэтому удаление записи обновляет список само.
class AgendaPage extends StatefulWidget {
  const AgendaPage({
    super.key,
    required this.entries,
    required this.actions,
    required this.now,
  });

  final List<DiaryEntry> entries;
  final DiaryActions actions;

  // «Сегодня»: приходит из AppServices (в тесте подставляется известная дата).
  final DateTime Function() now;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  late DateTime _selected; // выбранный день (полночь)
  late DateTime _month; // показанный месяц (первое число)

  @override
  void initState() {
    super.initState();
    _selected = dateOnly(widget.now());
    _month = firstOfMonth(_selected);
  }

  void _select(DateTime day) {
    setState(() {
      _selected = dateOnly(day);
      // Нажали серый «хвост» соседнего месяца: переходим в этот месяц.
      if (day.month != _month.month || day.year != _month.year) _month = firstOfMonth(day);
    });
  }

  void _goToToday() {
    _select(widget.now());
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = dateOnly(widget.now());
    final List<DiaryEntry> dayEntries = entriesOnDay(widget.entries, _selected);
    final ThemeData theme = Theme.of(context);

    // CustomScrollView: календарь и список прокручиваются ВМЕСТЕ. На низком экране
    // (ландшафт, клавиатура) календарь уезжает вверх, и список остаётся доступным;
    // «Column + Expanded» дал бы там переполнение (жёлто-чёрные полосы).
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: MonthCalendar(
              month: _month,
              selected: _selected,
              today: today,
              entryCounts: entryCountsByDay(widget.entries),
              onMonthChanged: (DateTime m) => setState(() => _month = firstOfMonth(m)),
              onDaySelected: _select,
              onTodayPressed: _goToToday,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              formatLongDate(_selected),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (dayEntries.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Text('No entries on this day.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList.builder(
              itemCount: dayEntries.length,
              itemBuilder: (BuildContext context, int index) {
                final DiaryEntry entry = dayEntries[index];
                return EntryTile(
                  entry: entry,
                  subtitle: formatTime(entry.date),
                  onTap: () => widget.actions.read(context, entry),
                  onDelete: () => widget.actions.confirmAndDelete(context, entry),
                );
              },
            ),
          ),
      ],
    );
  }
}

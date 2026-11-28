import '../models/diary_entry.dart';
import '../models/feeling.dart';

// Чистая логика профиля и ежедневника: никакого Flutter, никакой базы.
// Именно поэтому её можно проверить обычными тестами за доли секунды.
//
// Все функции получают ВЕСЬ список записей, пришедший из базы, и каждый раз
// считают нужное заново. Список небольшой, а пересчёт при любом изменении даёт
// требование сабжа «всё обновляется в реальном времени» бесплатно: нет
// отдельных счётчиков, которые могли бы разойтись с настоящим списком.

// Последние записи: самые новые по дате, не больше count штук.
// Список из базы уже отсортирован, но на это не полагаемся: сортируем сами
// (sort стабилен не всегда, поэтому при равных датах разводим по id).
List<DiaryEntry> lastEntries(List<DiaryEntry> entries, int count) {
  final List<DiaryEntry> sorted = [...entries]..sort(_newestFirst);
  return sorted.take(count).toList();
}

int _newestFirst(DiaryEntry a, DiaryEntry b) {
  final int byDate = b.date.compareTo(a.date);
  return byDate != 0 ? byDate : a.id.compareTo(b.id);
}

// Доля одного самочувствия: сколько записей и сколько это в процентах.
class FeelingShare {
  const FeelingShare({required this.feeling, required this.count, required this.percent});

  final Feeling feeling;
  final int count;
  final int percent; // целое, 0..100

  @override
  bool operator ==(Object other) =>
      other is FeelingShare &&
      other.feeling == feeling &&
      other.count == count &&
      other.percent == percent;

  @override
  int get hashCode => Object.hash(feeling, count, percent);

  @override
  String toString() => 'FeelingShare($feeling, $count, $percent%)';
}

// Проценты по самочувствиям, всегда по одной строке на КАЖДОЕ значение Feeling
// (в порядке объявления), даже если записей с ним нет (тогда 0%).
//
// Округление: «метод наибольших остатков». Обычное round() даёт сумму 99 или 101
// (три равные трети: 33+33+33=99). Здесь сначала берём целую часть доли, потом
// недостающие единицы раздаём тем, у кого остаток дробной части больше (при
// равенстве тому, кто раньше в списке). Сумма всегда ровно 100, если записи есть.
List<FeelingShare> feelingShares(List<DiaryEntry> entries) {
  final List<Feeling> all = Feeling.values;
  final Map<Feeling, int> counts = {for (final Feeling f in all) f: 0};
  for (final DiaryEntry entry in entries) {
    counts[entry.feeling] = counts[entry.feeling]! + 1;
  }

  final int total = entries.length;
  if (total == 0) {
    return [for (final Feeling f in all) FeelingShare(feeling: f, count: 0, percent: 0)];
  }

  // Доля в «сотых процента» без дробей: count * 100 / total как целое деление
  // и остаток (count * 100) % total. Так нет ошибок двоичной арифметики double.
  final Map<Feeling, int> floors = {};
  final Map<Feeling, int> remainders = {};
  int assigned = 0;
  for (final Feeling f in all) {
    final int scaled = counts[f]! * 100;
    floors[f] = scaled ~/ total;
    remainders[f] = scaled % total;
    assigned += floors[f]!;
  }

  int missing = 100 - assigned; // сколько единиц осталось раздать
  final List<Feeling> byRemainder = [...all]
    ..sort((Feeling a, Feeling b) {
      final int cmp = remainders[b]!.compareTo(remainders[a]!);
      return cmp != 0 ? cmp : a.index.compareTo(b.index);
    });
  for (final Feeling f in byRemainder) {
    if (missing == 0) break;
    if (remainders[f]! > 0) {
      floors[f] = floors[f]! + 1;
      missing--;
    }
  }

  return [
    for (final Feeling f in all)
      FeelingShare(feeling: f, count: counts[f]!, percent: floors[f]!),
  ];
}

// Один и тот же календарный день (по местному времени, время суток не важно).
bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

// Записи за выбранный день, самые поздние сверху.
List<DiaryEntry> entriesOnDay(List<DiaryEntry> entries, DateTime day) {
  final List<DiaryEntry> found = [
    for (final DiaryEntry e in entries)
      if (isSameDay(e.date, day)) e,
  ];
  found.sort(_newestFirst);
  return found;
}

// Сколько записей в каждом календарном дне (ключ: дата без времени).
// Календарь по нему рисует точки под днями, в которые что-то написано.
Map<DateTime, int> entryCountsByDay(List<DiaryEntry> entries) {
  final Map<DateTime, int> counts = {};
  for (final DiaryEntry e in entries) {
    final DateTime key = DateTime(e.date.year, e.date.month, e.date.day);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

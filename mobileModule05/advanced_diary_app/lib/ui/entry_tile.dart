import 'package:material_ui/material_ui.dart';

import '../models/diary_entry.dart';
import 'feeling_icon.dart';

// Строка записи: значок самочувствия, заголовок, подпись (дата или время),
// мусорка. Одна и та же в профиле («последние записи») и в ежедневнике.
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
  });

  final DiaryEntry entry;

  // Что написать под заголовком: профиль показывает дату, ежедневник время
  // (дата и так выбрана в календаре).
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.5), width: 1.5),
      ),
      child: ListTile(
        leading: Icon(
          feelingIcon(entry.feeling),
          color: feelingColor(entry.feeling),
          semanticLabel: entry.feeling.label,
          size: 32,
        ),
        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete entry',
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

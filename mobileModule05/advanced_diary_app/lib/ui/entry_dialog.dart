import 'package:material_ui/material_ui.dart';

import '../models/diary_entry.dart';
import 'feeling_icon.dart';
import 'formatters.dart';

// Окно чтения записи. Возвращает true, если нажали «Delete» (само удаление и
// вопрос «точно?» делает профиль), и null, если просто закрыли.
class EntryDialog extends StatelessWidget {
  const EntryDialog({super.key, required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      scrollable: true, // длинный текст прокручивается внутри окна
      title: Text(entry.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(feelingIcon(entry.feeling), color: feelingColor(entry.feeling)),
              const SizedBox(width: 8),
              Flexible(child: Text(entry.feeling.label)),
            ],
          ),
          const SizedBox(height: 4),
          Text(formatDateTime(entry.date), style: theme.textTheme.bodySmall),
          const Divider(height: 24),
          // SelectableText: текст можно выделить и скопировать.
          SelectableText(entry.content),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          child: const Text('Delete'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

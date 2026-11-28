import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../models/feeling.dart';
import 'feeling_icon.dart';

// То, что пользователь ввёл в окне новой записи (почту и дату дописывает приложение).
class NewEntryData {
  const NewEntryData({required this.title, required this.feeling, required this.content});

  final String title;
  final Feeling feeling;
  final String content;
}

// Окно «Новая запись»: заголовок, самочувствие, текст. Возвращает
// NewEntryData при «Save» и null при «Cancel».
class NewEntryDialog extends StatefulWidget {
  const NewEntryDialog({super.key});

  @override
  State<NewEntryDialog> createState() => _NewEntryDialogState();
}

class _NewEntryDialogState extends State<NewEntryDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();
  Feeling _feeling = Feeling.neutral;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  // Пустые поля из одних пробелов тоже считаем пустыми.
  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  void _save() {
    // validate() запускает validator у всех полей формы и рисует их ошибки.
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewEntryData(
        title: _title.text.trim(),
        feeling: _feeling,
        content: _content.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New diary entry'),
      scrollable: true, // на низком экране или с клавиатурой окно прокручивается
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
              maxLength: maxTitleLength,
              validator: _required,
            ),
            const SizedBox(height: 8),
            Text('How do you feel today?', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final Feeling feeling in Feeling.values)
                  ChoiceChip(
                    avatar: Icon(feelingIcon(feeling), color: feelingColor(feeling)),
                    label: Text(feeling.label),
                    selected: _feeling == feeling,
                    onSelected: (_) => setState(() => _feeling = feeling),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _content,
              decoration: const InputDecoration(
                labelText: 'Dear diary...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              minLines: 4,
              maxLines: 8,
              maxLength: maxContentLength,
              keyboardType: TextInputType.multiline,
              validator: _required,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

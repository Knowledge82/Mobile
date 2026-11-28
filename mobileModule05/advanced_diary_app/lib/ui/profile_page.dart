import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../logic/diary_stats.dart';
import '../models/app_user.dart';
import '../models/diary_entry.dart';
import 'diary_actions.dart';
import 'entry_tile.dart';
import 'feeling_icon.dart';
import 'formatters.dart';

// Вкладка «Профиль»: имя, выход, последние 2 записи, всего записей и проценты по
// самочувствиям. Страница ничего не загружает сама: список записей приходит
// готовым от HomePage, а всё остальное (последние, проценты) считается из него
// чистыми функциями (logic/diary_stats.dart). Поэтому «в реальном времени» тут
// получается само: пришёл новый список, страница перестроилась, цифры новые.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.entries,
    required this.actions,
    required this.onLogout,
  });

  final AppUser user;
  final List<DiaryEntry> entries;
  final DiaryActions actions;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final List<DiaryEntry> last = lastEntries(entries, profileLastEntriesCount);
    final List<FeelingShare> shares = feelingShares(entries);

    return ListView(
      // Внизу запас под кнопку «New diary entry», иначе она закроет последнюю строку.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _Header(user: user, onLogout: onLogout),
        const SizedBox(height: 16),
        _Section(
          title: 'Your last diary entries',
          child: last.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No entries yet.\nTap "New diary entry" to write the first one.'),
                )
              : Column(
                  children: [
                    for (final DiaryEntry entry in last)
                      EntryTile(
                        entry: entry,
                        subtitle: formatDate(entry.date),
                        onTap: () => actions.read(context, entry),
                        onDelete: () => actions.confirmAndDelete(context, entry),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Your feelings',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total entries: ${entries.length}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final FeelingShare share in shares) _ShareRow(share: share),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  // Первая буква имени для «аватарки». Картинку профиля из сети не берём:
  // это ещё одна загрузка, ещё одна ошибка и ещё один пакет (см. разбор, решение 7).
  String get _initial {
    final String name = user.label.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool showEmail = user.email.isNotEmpty && user.email != user.label;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(_initial, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.label,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showEmail)
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: onLogout,
        ),
      ],
    );
  }
}

// Карточка с заголовком, как «Your last diary entries» на картинке сабжа.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// Строка статистики: значок, подпись, полоска и процент.
class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share});

  final FeelingShare share;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // MergeSemantics: скринридер читает строку одной фразой, а не по кускам.
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(feelingIcon(share.feeling), color: feelingColor(share.feeling)),
            const SizedBox(width: 8),
            SizedBox(width: 84, child: Text(share.feeling.label)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: share.percent / 100,
                  minHeight: 8,
                  color: feelingColor(share.feeling),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('${share.percent}%', textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}

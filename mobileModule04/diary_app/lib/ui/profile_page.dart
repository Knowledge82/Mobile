import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../config.dart';
import '../models/app_user.dart';
import '../models/diary_entry.dart';
import '../services/diary_repository.dart';
import 'entry_dialog.dart';
import 'feeling_icon.dart';
import 'formatters.dart';
import 'new_entry_dialog.dart';

// Профиль: список записей, кнопка «New diary entry», чтение и удаление.
//
// ДОСТУП ТОЛЬКО ДЛЯ ВОШЕДШИХ держится на двух вещах:
//   1. конструктор требует НЕ-null AppUser: профиль нельзя построить без
//      пользователя (компилятор не даст), поэтому к нему ведут только из мест,
//      где вход уже случился;
//   2. страница следит за authStateChanges и, если вход пропал (выход, отзыв
//      доступа), сама возвращает на приветствие.
// Настоящая защита данных всё равно в правилах Firestore (firestore.rules).
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.services, required this.user});

  final AppServices services;
  final AppUser user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Stream<List<DiaryEntry>> _entries;
  StreamSubscription<AppUser?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToEntries();
    // Охранник: вход пропал, значит уходим на приветствие.
    _authSubscription = widget.services.auth.authStateChanges().listen((AppUser? user) {
      if (user == null) _backToLogin();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Поток создаём ОДИН раз (а не в build): иначе каждая перерисовка
  // переподписывалась бы на базу заново.
  void _subscribeToEntries() {
    _entries = widget.services.diary.watchEntries(widget.user.uid);
  }

  void _backToLogin() {
    if (!mounted) return;
    // До первой страницы (приветствия); заодно закрываются открытые окна.
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  Future<void> _signOut() async {
    // Сам переход сделает охранник, когда придёт «вошедших нет».
    await widget.services.auth.signOut();
  }

  // --- запись в базу с понятным поведением без сети --------------------------
  //
  // Без связи Firestore принимает запись в локальный кэш (список уже обновился),
  // а Future из add()/delete() завершится только когда ответит сервер, то есть,
  // возможно, через часы. Ждать вечно нельзя: через writeConfirmationTimeout
  // говорим, что записано на устройстве и отправится позже.
  Future<void> _runWrite(Future<void> Function() action, String pendingMessage) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await action().timeout(writeConfirmationTimeout);
    } on TimeoutException {
      messenger.showSnackBar(SnackBar(content: Text(pendingMessage)));
    } on DiaryFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _newEntry() async {
    final NewEntryData? data = await showDialog<NewEntryData>(
      context: context,
      builder: (BuildContext context) => const NewEntryDialog(),
    );
    if (data == null || !mounted) return;

    final EntryDraft draft = EntryDraft(
      email: widget.user.email,
      date: widget.services.now(),
      title: data.title,
      feeling: data.feeling,
      content: data.content,
    );
    await _runWrite(
      () => widget.services.diary.add(widget.user.uid, draft),
      'Saved on this device. It will be sent when you are online.',
    );
  }

  Future<void> _read(DiaryEntry entry) async {
    final bool? wantsDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => EntryDialog(entry: entry),
    );
    if (wantsDelete == true && mounted) await _confirmAndDelete(entry);
  }

  Future<void> _confirmAndDelete(DiaryEntry entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('"${entry.title}" will be removed for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runWrite(
      () => widget.services.diary.delete(widget.user.uid, entry.id),
      'Deleted on this device. It will be synced when you are online.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My diary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Signed in as ${widget.user.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DiaryEntry>>(
              stream: _entries,
              builder: (BuildContext context, AsyncSnapshot<List<DiaryEntry>> snapshot) {
                if (snapshot.hasError) {
                  final Object? error = snapshot.error;
                  return _ErrorView(
                    message: error is DiaryFailure ? error.message : 'Could not load the diary.',
                    onRetry: () => setState(_subscribeToEntries),
                  );
                }
                final List<DiaryEntry>? entries = snapshot.data;
                if (entries == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (entries.isEmpty) {
                  return const _EmptyView();
                }
                return ListView.builder(
                  // Внизу запас под кнопку, иначе она закроет последнюю запись.
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: entries.length,
                  itemBuilder: (BuildContext context, int index) {
                    final DiaryEntry entry = entries[index];
                    return _EntryTile(
                      entry: entry,
                      onTap: () => _read(entry),
                      onDelete: () => _confirmAndDelete(entry),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newEntry,
        icon: const Icon(Icons.add),
        label: const Text('New diary entry'),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap, required this.onDelete});

  final DiaryEntry entry;
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
        subtitle: Text(formatDate(entry.date)),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No entries yet.\nTap "New diary entry" to write the first one.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

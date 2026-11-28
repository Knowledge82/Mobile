import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../config.dart';
import '../models/app_user.dart';
import '../models/diary_entry.dart';
import '../services/diary_repository.dart';
import 'entry_dialog.dart';
import 'new_entry_dialog.dart';

// Три действия над записями: создать, прочитать, удалить. Раньше они жили внутри
// страницы профиля (модуль 04). Теперь ими пользуются профиль И ежедневник,
// поэтому вынесены в один общий объект: диалоги, вопрос «удалить?» и честное
// поведение без сети написаны в одном месте и ведут себя везде одинаково.
//
// Объект неизменяемый и не хранит состояния экрана: контекст передаётся в каждый
// метод. Так он не может «пережить» экран и держать ссылку на мёртвый виджет.
class DiaryActions {
  const DiaryActions({required this.services, required this.user});

  final AppServices services;
  final AppUser user;

  // Запись в базу с понятным поведением без сети (подробно: docs/04-ex01.md, 2.4).
  Future<void> _runWrite(
    BuildContext context,
    Future<void> Function() action,
    String pendingMessage,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await action().timeout(writeConfirmationTimeout);
    } on TimeoutException {
      messenger.showSnackBar(SnackBar(content: Text(pendingMessage)));
    } on DiaryFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> newEntry(BuildContext context) async {
    final NewEntryData? data = await showDialog<NewEntryData>(
      context: context,
      builder: (BuildContext context) => const NewEntryDialog(),
    );
    // context.mounted: «страница, из которой открыли окно, ещё жива?» (вместо
    // State.mounted: у нас нет State, объект действий общий для нескольких экранов).
    if (data == null || !context.mounted) return;

    final EntryDraft draft = EntryDraft(
      email: user.email,
      date: services.now(),
      title: data.title,
      feeling: data.feeling,
      content: data.content,
    );
    await _runWrite(
      context,
      () => services.diary.add(user.uid, draft),
      'Saved on this device. It will be sent when you are online.',
    );
  }

  Future<void> read(BuildContext context, DiaryEntry entry) async {
    final bool? wantsDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => EntryDialog(entry: entry),
    );
    if (wantsDelete == true && context.mounted) await confirmAndDelete(context, entry);
  }

  Future<void> confirmAndDelete(BuildContext context, DiaryEntry entry) async {
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
    if (confirmed != true || !context.mounted) return;

    await _runWrite(
      context,
      () => services.diary.delete(user.uid, entry.id),
      'Deleted on this device. It will be synced when you are online.',
    );
  }
}

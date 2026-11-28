import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../models/app_user.dart';
import '../models/diary_entry.dart';
import '../services/diary_repository.dart';
import 'agenda_page.dart';
import 'diary_actions.dart';
import 'profile_page.dart';

// Оболочка вошедшего пользователя: две вкладки (профиль и ежедневник) под
// нижней панелью. Здесь, и только здесь:
//   1. ОДНА подписка на записи пользователя (обе вкладки получают один и тот же
//      список; две подписки были бы двойными чтениями и могли бы на миг показать
//      разные данные);
//   2. охранник: если вход пропал, возвращаем на приветствие;
//   3. состояния «загрузка» и «ошибка» для обеих вкладок сразу.
//
// Доступ только для вошедших держится, как в модуле 04: конструктор требует
// НЕ-null AppUser, плюс подписка на authStateChanges, а настоящая защита данных
// это firestore.rules.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.services, required this.user});

  final AppServices services;
  final AppUser user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<List<DiaryEntry>> _entries;
  StreamSubscription<AppUser?>? _authSubscription;
  int _tab = 0; // 0: профиль, 1: ежедневник

  late final DiaryActions _actions = DiaryActions(services: widget.services, user: widget.user);

  @override
  void initState() {
    super.initState();
    _subscribeToEntries();
    _authSubscription = widget.services.auth.authStateChanges().listen((AppUser? user) {
      if (user == null) _backToLogin();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Поток создаём один раз, а не в build (иначе подписка пересоздавалась бы
  // при каждой перерисовке). «Try again» вызывает этот же метод.
  void _subscribeToEntries() {
    _entries = widget.services.diary.watchEntries(widget.user.uid);
  }

  void _backToLogin() {
    if (!mounted) return;
    // До первой страницы (приветствия); заодно закрываются открытые окна.
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  Future<void> _signOut() async {
    // Переход сделает охранник, когда придёт «вошедших нет».
    await widget.services.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tab == 0 ? 'My diary' : 'Diary agenda')),
      body: StreamBuilder<List<DiaryEntry>>(
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
          // IndexedStack строит обе вкладки сразу и прячет неактивную: так ежедневник
          // не забывает выбранный день и месяц, пока вы смотрите профиль.
          return IndexedStack(
            index: _tab,
            sizing: StackFit.expand,
            children: [
              ProfilePage(
                user: widget.user,
                entries: entries,
                actions: _actions,
                onLogout: _signOut,
              ),
              AgendaPage(entries: entries, actions: _actions, now: widget.services.now),
            ],
          );
        },
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _actions.newEntry(context),
              icon: const Icon(Icons.add),
              label: const Text('New diary entry'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
        ],
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

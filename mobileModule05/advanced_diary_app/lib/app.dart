import 'package:material_ui/material_ui.dart';

import 'app_services.dart';
import 'ui/login_page.dart';

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      // Первая страница всегда страница входа. Если сессия уже есть, она сама
      // перебросит на профиль (см. LoginPage).
      home: LoginPage(services: services),
    );
  }
}

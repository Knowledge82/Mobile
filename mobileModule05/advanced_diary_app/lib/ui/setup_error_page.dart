import 'package:material_ui/material_ui.dart';

// Экран «Firebase не настроен». Показывается вместо приложения, если
// Firebase.initializeApp не удался (обычно: firebase_options.dart ещё заглушка).
class SetupErrorApp extends StatelessWidget {
  const SetupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase is not configured')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.build_circle_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'The app could not start Firebase.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Run this once in the project folder, choose your Firebase project '
                'and the Android platform, then restart the app:',
              ),
              const SizedBox(height: 12),
              const SelectableText('flutterfire configure'),
              const SizedBox(height: 12),
              const Text('Step by step: docs/04-ex00.md, section "Firebase setup".'),
              const SizedBox(height: 24),
              Text('Details:', style: Theme.of(context).textTheme.labelLarge),
              SelectableText('$error'),
            ],
          ),
        ),
      ),
    );
  }
}

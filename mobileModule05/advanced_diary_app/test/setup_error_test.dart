// Экран «Firebase не настроен».
// (Теста на заглушку firebase_options.dart нет намеренно: после настоящего
// flutterfire configure он бы падал и учил не доверять тестам.)
// Подробности: docs/04-ex00.md, раздел про настройку Firebase.
//
// ВАЖНО: тесты не запускались (см. docs/04-ex00.md).

import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_diary_app/ui/setup_error_page.dart';

void main() {
  testWidgets('показывает команду flutterfire configure и текст ошибки', (tester) async {
    await tester.pumpWidget(SetupErrorApp(error: StateError('boom')));

    expect(find.text('Firebase is not configured'), findsOneWidget);
    expect(find.text('flutterfire configure'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });
}

import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'app_services.dart';
import 'firebase_options.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_diary_repository.dart';
import 'ui/setup_error_page.dart';

// «Сборочный цех»: здесь, и только здесь, поднимается Firebase и создаются
// настоящие сервисы. Всё остальное получает их готовыми.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    // Самая частая причина: ещё не запускали `flutterfire configure`. Вместо
    // красного экрана или чёрного окна показываем понятную инструкцию.
    runApp(SetupErrorApp(error: error));
    return;
  }

  runApp(
    DiaryApp(
      services: AppServices(
        auth: FirebaseAuthService(),
        diary: FirestoreDiaryRepository(),
      ),
    ),
  );
}

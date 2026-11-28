import 'services/auth_service.dart';
import 'services/diary_repository.dart';

// Всё, что экранам нужно от внешнего мира, одним пакетом. Настоящие сервисы
// создаются в main.dart, а в тестах подставляются подделки (внедрение
// зависимостей через конструкторы, без дополнительных пакетов).
class AppServices {
  const AppServices({
    required this.auth,
    required this.diary,
    this.now = DateTime.now,
  });

  final AuthService auth;
  final DiaryRepository diary;

  // «Который час» подставляется тестом, чтобы даты записей были известны заранее.
  final DateTime Function() now;
}

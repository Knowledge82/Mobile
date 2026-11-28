import 'package:material_ui/material_ui.dart';

// Путь к картинке фона (она объявлена в pubspec.yaml, раздел assets).
const String backgroundAsset = 'assets/images/background.jpg';

// Фон приложения. Создаётся ОДИН раз, в MaterialApp.builder, то есть ВЫШЕ
// навигатора и всех экранов: вкладки, поиск, ошибки лежат поверх него,
// а он не перерисовывается и не дублируется (требование сабжа).
//
// Слои снизу вверх:
//   1. картинка на весь экран (BoxFit.cover: заполняет, обрезая лишнее по краям);
//   2. тёмный градиент: чуть темнее сверху (под полем поиска) и снизу (под панелью
//      вкладок), чтобы светлый текст читался на любом куске картинки;
//   3. сам интерфейс (child).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          backgroundAsset,
          fit: BoxFit.cover,
          excludeFromSemantics: true, // декоративная: скринридеру она не нужна
          // Если файл потерялся, приложение остаётся читаемым на сплошном цвете.
          errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
              const ColoredBox(color: Color(0xFF1B3A5C)),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x80000000), Color(0x33000000), Color(0x99000000)],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

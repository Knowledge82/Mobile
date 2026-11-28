import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../models/app_user.dart';
import 'home_page.dart';
import 'sign_in_page.dart';

// Путь к картинке с листвой (объявлена в pubspec.yaml, раздел assets).
const String leavesAsset = 'assets/images/leaves.jpg';

// Страница входа: приветствие и кнопка «Login».
//
//   * кнопка Login: если пользователь уже вошёл, сразу ведёт на профиль,
//     иначе открывает страницу входа (Google или GitHub);
//   * при запуске: если сессия уже есть (прошлый вход сохранился), страница
//     сама переходит на профиль, не заставляя нажимать кнопку.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.services});

  final AppServices services;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();
    _redirectIfSignedIn();
  }

  // Поток authStateChanges сразу присылает текущее состояние. Берём только
  // первое значение: дальше за состоянием следят другие экраны.
  Future<void> _redirectIfSignedIn() async {
    final AppUser? user = await widget.services.auth.authStateChanges().first;
    if (!mounted || user == null) return;
    _openProfile(user);
  }

  void _openProfile(AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => HomePage(services: widget.services, user: user),
      ),
    );
  }

  void _onLoginPressed() {
    final AppUser? user = widget.services.auth.currentUser;
    if (user != null) {
      _openProfile(user); // уже вошёл: сразу в дневник
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => SignInPage(services: widget.services),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8EE),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Листва сверху. Если картинка потерялась, остаётся сплошной светлый фон.
          Image.asset(
            leavesAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
            errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                const SizedBox.shrink(),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                // Светлая плашка (92% непрозрачности) под текстом: листва не мешает
                // читать ни на высоком экране, ни в ландшафте, где она занимает больше места.
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xEBF4F8EE),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome to your Diary',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: const Color(0xFF1B5E20),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _onLoginPressed,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          child: Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

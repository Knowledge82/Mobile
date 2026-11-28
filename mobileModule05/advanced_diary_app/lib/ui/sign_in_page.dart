import 'package:material_ui/material_ui.dart';

import '../app_services.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

// «Страница аутентификации»: выбор способа входа, Google или GitHub.
// Сам вход делает AuthService (Firebase откроет страницу провайдера).
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.services});

  final AppServices services;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Каким способом входим сейчас (null: ничего не происходит).
  SignInProvider? _busy;

  Future<void> _signIn(SignInProvider provider) async {
    if (_busy != null) return; // второй тап, пока идёт первый, игнорируем
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = provider);

    try {
      final user = await widget.services.auth.signIn(provider);
      if (!mounted) return;
      // pushReplacement: страница входа заменяется профилем, поэтому «назад» с
      // профиля ведёт на приветствие, а не на уже ненужную страницу входа.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => HomePage(services: widget.services, user: user),
        ),
      );
    } on SignInCancelled {
      // Закрыл окно входа: не ошибка, ничего не показываем.
    } on AuthFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _busy != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Log in to your account to continue.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _ProviderButton(
                    label: 'Continue with Google',
                    icon: Icons.account_circle,
                    loading: _busy == SignInProvider.google,
                    onPressed: busy ? null : () => _signIn(SignInProvider.google),
                  ),
                  const SizedBox(height: 12),
                  _ProviderButton(
                    label: 'Continue with GitHub',
                    icon: Icons.code,
                    loading: _busy == SignInProvider.github,
                    onPressed: busy ? null : () => _signIn(SignInProvider.github),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading; // на ЭТОЙ кнопке крутится индикатор
  final VoidCallback? onPressed; // null: кнопка серая и не нажимается

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label),
      ),
    );
  }
}

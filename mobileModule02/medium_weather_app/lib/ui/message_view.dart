import 'package:material_ui/material_ui.dart';

import '../failures.dart';

// Сообщение об ошибке посреди вкладки. Висит, пока его не заменят данные.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.failure});

  final WeatherFailure failure;

  // switch по sealed-классу: компилятор следит, что иконка есть для каждой ошибки.
  IconData get _icon => switch (failure) {
    LocationDeniedFailure() ||
    LocationDeniedForeverFailure() ||
    LocationServiceDisabledFailure() ||
    LocationUnavailableFailure() => Icons.location_off,
    CityNotFoundFailure() => Icons.search_off,
    ConnectionFailure() => Icons.cloud_off,
    ServerFailure() => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              failure.message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

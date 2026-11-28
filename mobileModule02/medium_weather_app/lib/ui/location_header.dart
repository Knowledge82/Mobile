import 'package:material_ui/material_ui.dart';

import '../models/place.dart';

// «Барселона / Catalonia, Spain»: заголовок над данными на каждой вкладке.
class LocationHeader extends StatelessWidget {
  const LocationHeader({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          place.name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (place.subtitle.isNotEmpty)
          Text(
            place.subtitle,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../models/place.dart';

// Выпадающий список подсказок: «город / регион, страна».
// Белая карточка с тенью поверх вкладок (лежит в Stack), закруглённая и
// прижатая к верху. Название города жирное и крупное, регион и страна мельче.
class SuggestionsList extends StatelessWidget {
  const SuggestionsList({
    super.key,
    required this.places,
    required this.onSelected,
  });

  final List<Place> places;
  final ValueChanged<Place> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<Place> shown = places.take(maxSuggestions).toList();

    // Align не «съедает» нажатия вне списка: клики мимо проваливаются
    // на вкладки под ним.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Material(
            color: const Color(0xFAFFFFFF), // белый 98%
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias, // скругление обрезает и подсветку нажатия
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: shown.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (BuildContext context, int index) {
                final Place place = shown[index];
                return ListTile(
                  leading: const Icon(Icons.location_city, color: Color(0xFF1565C0)),
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      color: Color(0xDE000000),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: place.subtitle.isEmpty
                      ? null
                      : Text(
                          place.subtitle,
                          style: const TextStyle(color: Color(0x99000000)),
                        ),
                  onTap: () => onSelected(place),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

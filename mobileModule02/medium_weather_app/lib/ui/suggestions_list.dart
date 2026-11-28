import 'package:material_ui/material_ui.dart';

import '../models/place.dart';

// Выпадающий список подсказок: «город / регион, страна».
// Лежит поверх вкладок (в Stack), поэтому сам прижимается к верху и не
// превышает 320 px по высоте: длиннее и так не бывает (подсказок не больше 5).
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
    // Align не «съедает» нажатия вне списка: клики мимо проваливаются
    // на вкладки под ним.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 320),
        child: Material(
          elevation: 4,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: places.length,
            itemBuilder: (BuildContext context, int index) {
              final Place place = places[index];
              return ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(place.name),
                subtitle: place.subtitle.isEmpty ? null : Text(place.subtitle),
                onTap: () => onSelected(place),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:material_ui/material_ui.dart';

import 'search_request.dart';

// Верхняя панель: поле поиска + кнопка геолокации.
//
// Почему StatefulWidget: у поля есть TextEditingController, а контроллер надо
// создать один раз, а в конце освободить (dispose). Это работа State.
//
// Почему implements PreferredSizeWidget: Scaffold.appBar принимает только
// виджеты, которые заранее умеют сказать свою высоту (preferredSize), чтобы
// Scaffold знал, сколько места отдать телу страницы.
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SearchAppBar({super.key, required this.onRequest});

  // Панель сама ничего не показывает, она только сообщает наверх, что искали.
  // null = поле очистили, искать нечего.
  final ValueChanged<SearchRequest?> onRequest;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  // Поле на широких экранах не растягиваем до безобразия.
  static const double _maxFieldWidth = 560;

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose(); // super.dispose() всегда последним
  }

  // Срабатывает на каждый введённый или стёртый символ.
  void _handleTextChanged(String text) {
    final String query = text.trim();
    widget.onRequest(query.isEmpty ? null : TextSearch(query));
  }

  void _handleGeolocation() {
    // Очищаем поле, чтобы то, что в поле, и то, что на вкладках, не расходились.
    // Программная очистка onChanged НЕ вызывает, поэтому дальше сообщаем сами.
    _controller.clear();
    // Убираем фокус: на телефоне клавиатура закрывается.
    FocusScope.of(context).unfocus();
    widget.onRequest(const GeolocationSearch());
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxFieldWidth),
          child: TextField(
            controller: _controller,
            onChanged: _handleTextChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search location...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.my_location),
          tooltip: 'Geolocation',
          onPressed: _handleGeolocation,
        ),
      ],
    );
  }
}

import 'package:material_ui/material_ui.dart';

// Верхняя панель: поле поиска + кнопка геолокации.
//
// В модуле 01 это был StatefulWidget со своим контроллером поля. Теперь поле
// должно меняться и снаружи (выбор подсказки вписывает город в поле), поэтому
// контроллер ПОДНЯТ в HomePage, а панель снова StatelessWidget: всё получает
// параметрами. Это тот же «подъём состояния», только на этот раз вверх уехал
// ещё один кусок.
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    super.key,
    required this.controller,
    required this.onTextChanged,
    required this.onSubmitted,
    required this.onGeolocation,
  });

  final TextEditingController controller;
  final ValueChanged<String> onTextChanged; // каждый символ: для подсказок
  final ValueChanged<String> onSubmitted; // «ввод»/«поиск» на клавиатуре
  final VoidCallback onGeolocation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Поле поиска не растягиваем на всю ширину в широком окне.
  static const double _maxFieldWidth = 560;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxFieldWidth),
          child: TextField(
            controller: controller,
            onChanged: onTextChanged,
            onSubmitted: onSubmitted,
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
          onPressed: onGeolocation,
        ),
      ],
    );
  }
}

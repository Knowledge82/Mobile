import 'package:material_ui/material_ui.dart';

// Верхняя панель: поле поиска + кнопка геолокации.
//
// Поле поиска белое и яркое: на любом фоне это самый заметный элемент экрана.
// Подсказка внутри («Search for a city...») прямо говорит, ЧТО здесь ищут,
// а кнопка геолокации залита цветом и подписана в подсказке (tooltip).
//
// Состояния у панели нет: контроллер поля принадлежит HomePage (чтобы выбор
// подсказки мог вписать город в поле), всё остальное приходит параметрами.
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

  static const double _height = 68;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  // Поле не растягиваем на всю ширину в широком окне.
  static const double _maxFieldWidth = 560;

  void _clear() {
    controller.clear(); // программная очистка onChanged не вызывает...
    onTextChanged(''); // ...поэтому сообщаем сами: подсказки должны исчезнуть
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: _height,
      backgroundColor: Colors.transparent, // фон приложения виден сквозь панель
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxFieldWidth),
          child: TextField(
            controller: controller,
            onChanged: onTextChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Color(0xDE000000)), // чёрный 87% на белом
            cursorColor: const Color(0xFF1565C0),
            decoration: InputDecoration(
              hintText: 'Search for a city...',
              hintStyle: const TextStyle(color: Color(0x99000000)),
              prefixIcon: const Icon(Icons.search, color: Color(0x99000000)),
              // Крестик показываем только когда есть что стирать. Подписываемся
              // на сам контроллер: ему не нужен setState и целая перерисовка.
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (BuildContext context, TextEditingValue value, Widget? child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close, color: Color(0x99000000)),
                    tooltip: 'Clear',
                    onPressed: _clear,
                  );
                },
              ),
              filled: true,
              fillColor: const Color(0xF2FFFFFF), // белый 95%
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton.filled(
            icon: const Icon(Icons.my_location),
            tooltip: 'Use my location',
            onPressed: onGeolocation,
          ),
        ),
      ],
    );
  }
}

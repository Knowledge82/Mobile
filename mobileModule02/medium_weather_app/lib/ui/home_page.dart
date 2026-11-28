import 'package:material_ui/material_ui.dart';

import '../models/place.dart';
import '../state/weather_controller.dart';
import 'search_app_bar.dart';
import 'suggestions_list.dart';
import 'tab_page.dart';
import 'weather_tab.dart';

// Главная страница: каркас «верхняя панель + вкладки + нижняя панель».
// Состояние погоды живёт в WeatherController (его принесли снаружи),
// а здесь только то, что принадлежит самому экрану: контроллер текстового поля.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final WeatherController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // «При запуске приложения»: сразу пробуем определить место по GPS.
    widget.controller.useCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleGeolocation() {
    _searchController.clear(); // как в ex01: поле и экран не должны спорить
    FocusScope.of(context).unfocus();
    widget.controller.useCurrentLocation();
  }

  void _handleSubmitted(String text) {
    widget.controller.search(text);
  }

  void _handleSuggestionSelected(Place place) {
    // Программная запись в поле onChanged НЕ вызывает: новых подсказок не будет.
    _searchController.text = place.name;
    FocusScope.of(context).unfocus();
    widget.controller.select(place);
  }

  @override
  Widget build(BuildContext context) {
    final TabBar tabBar = TabBar(
      dividerColor: Colors.transparent,
      tabs: [
        for (final WeatherTab tab in WeatherTab.values)
          Tab(icon: Icon(tab.icon), text: tab.title),
      ],
    );

    // DefaultTabController стоит ВЫШЕ ListenableBuilder, поэтому перерисовка
    // при каждом изменении данных его не трогает. Так выполняется требование
    // «после поиска остаёмся на той же вкладке»: выбранная вкладка живёт
    // в TabController и не зависит от того, что показывают страницы.
    return DefaultTabController(
      length: WeatherTab.values.length,
      child: Scaffold(
        appBar: SearchAppBar(
          controller: _searchController,
          onTextChanged: widget.controller.queryChanged,
          onSubmitted: _handleSubmitted,
          onGeolocation: _handleGeolocation,
        ),
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              children: [
                TabBarView(
                  children: [
                    for (final WeatherTab tab in WeatherTab.values)
                      TabPage(tab: tab, state: widget.controller.state),
                  ],
                ),
                if (widget.controller.suggestions.isNotEmpty)
                  SuggestionsList(
                    places: widget.controller.suggestions,
                    onSelected: _handleSuggestionSelected,
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: BottomAppBar(
          height: tabBar.preferredSize.height,
          padding: EdgeInsets.zero,
          child: tabBar,
        ),
      ),
    );
  }
}

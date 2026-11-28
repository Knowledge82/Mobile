import 'package:material_ui/material_ui.dart';

import 'search_app_bar.dart';
import 'search_request.dart';
import 'tab_page.dart';
import 'weather_tab.dart';

// Главная страница: хранит общее состояние (что искали) и собирает каркас
// «верхняя панель + вкладки + нижняя панель».
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Единственное состояние приложения на этом этапе. null = ещё не искали.
  SearchRequest? _request;

  void _handleRequest(SearchRequest? request) {
    setState(() {
      _request = request;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Нижняя панель вкладок. Строим заранее, чтобы взять у неё высоту.
    final TabBar tabBar = TabBar(
      dividerColor: Colors.transparent, // линия-разделитель внизу не нужна
      tabs: [
        for (final WeatherTab tab in WeatherTab.values)
          Tab(icon: Icon(tab.icon), text: tab.title),
      ],
    );

    // DefaultTabController создаёт TabController и раздаёт его всем потомкам:
    // TabBar (кнопки) и TabBarView (страницы) подключаются к нему сами.
    // Именно он связывает «нажал на вкладку» и «перелистнулась страница».
    return DefaultTabController(
      length: WeatherTab.values.length,
      child: Scaffold(
        appBar: SearchAppBar(onRequest: _handleRequest),
        body: TabBarView(
          children: [
            for (final WeatherTab tab in WeatherTab.values)
              TabPage(tab: tab, request: _request),
          ],
        ),
        // padding: zero и height: высота самой TabBar. По умолчанию у
        // BottomAppBar в Material 3 высота 80 и отступы 12+12 сверху и снизу:
        // вкладке (ей нужно 72 плюс 2 на индикатор) досталось бы всего 56.
        bottomNavigationBar: BottomAppBar(
          height: tabBar.preferredSize.height,
          padding: EdgeInsets.zero,
          child: tabBar,
        ),
      ),
    );
  }
}

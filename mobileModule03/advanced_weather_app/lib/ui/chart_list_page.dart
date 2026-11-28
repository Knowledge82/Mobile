import 'package:material_ui/material_ui.dart';

// Каркас вкладок Today и Weekly: шапка (место), график и ПРОКРУЧИВАЕМЫЙ список.
//
// Два режима раскладки, потому что места на экранах бывает очень по-разному:
//
//   просторно (высокий экран):  шапка и график стоят на месте, а прокручивается
//                               только список под ними: график всегда на виду.
//   тесно (ландшафт, крупный    всё одним списком: шапка и график это первые
//   шрифт, низкое окно):        элементы, и прокручивается вся страница. Иначе
//                               для самого списка не осталось бы места вообще.
class ChartListPage extends StatelessWidget {
  const ChartListPage({
    super.key,
    required this.header,
    required this.chart,
    required this.itemCount,
    required this.itemBuilder,
  });

  final Widget header;
  final Widget chart;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  // Высота окна, с которой шапка и график спокойно умещаются над списком.
  static const double _roomyHeight = 560;

  static const EdgeInsets _listPadding = EdgeInsets.fromLTRB(16, 0, 16, 16);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Крупный системный шрифт раздувает шапку: требуем больше места.
        final double scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final bool roomy = constraints.maxHeight >= _roomyHeight * (scale < 1 ? 1 : scale);

        // Не шире 600 px: на планшете и в вебе широкие строки читать неудобно.
        Widget centered(Widget child) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: child),
        );

        if (roomy) {
          return centered(
            Column(
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: header),
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: chart),
                Expanded(
                  child: ListView.builder(
                    padding: _listPadding,
                    itemCount: itemCount,
                    itemBuilder: itemBuilder,
                  ),
                ),
              ],
            ),
          );
        }

        return centered(
          ListView.builder(
            padding: _listPadding,
            itemCount: itemCount + 2, // +2: шапка и график
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: header);
              }
              if (index == 1) {
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: chart);
              }
              return itemBuilder(context, index - 2);
            },
          ),
        );
      },
    );
  }
}

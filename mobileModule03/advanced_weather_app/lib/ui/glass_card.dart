import 'package:material_ui/material_ui.dart';

// «Стекло»: полупрозрачная тёмная плашка. Через неё виден фон (мы его видим и
// понимаем, где находимся), а текст на ней читается на любой картинке:
// темнее фон под текстом = выше контраст.
//
// Цвет 0x66 = 40% непрозрачности чёрного (0x66 / 0xFF).
const Color glassColor = Color(0x66000000);

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: glassColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x33FFFFFF)), // тонкая светлая кромка
      ),
      child: child,
    );
  }
}

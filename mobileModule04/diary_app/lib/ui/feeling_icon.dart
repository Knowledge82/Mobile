import 'package:material_ui/material_ui.dart';

import '../models/feeling.dart';

// Значок и цвет самочувствия. Цвет это подсказка, а не единственный признак:
// у каждого значения свой ЗНАЧОК (лицо) и своя ПОДПИСЬ.
IconData feelingIcon(Feeling feeling) => switch (feeling) {
  Feeling.verySatisfied => Icons.sentiment_very_satisfied,
  Feeling.satisfied => Icons.sentiment_satisfied,
  Feeling.neutral => Icons.sentiment_neutral,
  Feeling.dissatisfied => Icons.sentiment_dissatisfied,
  Feeling.veryDissatisfied => Icons.sentiment_very_dissatisfied,
};

Color feelingColor(Feeling feeling) => switch (feeling) {
  Feeling.verySatisfied => const Color(0xFF2E7D32), // тёмно-зелёный
  Feeling.satisfied => const Color(0xFF7CB342), // салатовый
  Feeling.neutral => const Color(0xFFF9A825), // янтарный
  Feeling.dissatisfied => const Color(0xFFEF6C00), // оранжевый
  Feeling.veryDissatisfied => const Color(0xFFC62828), // красный
};

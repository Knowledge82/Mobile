// «Самочувствие дня»: пять ступеней от «отлично» до «очень плохо».
//
// Храним в базе ИМЯ значения (строку 'satisfied'), а не номер: если завтра мы
// переставим значения местами или добавим новое, старые записи останутся верными.
// В примере из сабжа поле называется icon и тоже хранит строку «satisfied».
enum Feeling {
  verySatisfied('Very happy'),
  satisfied('Happy'),
  neutral('Neutral'),
  dissatisfied('Sad'),
  veryDissatisfied('Very sad');

  const Feeling(this.label);

  // Подпись для человека (на экране и в подсказках скринридера).
  final String label;

  // Значение из базы -> Feeling. Незнакомое или пустое значение не должно
  // ронять список: берём «нейтрально» (одна «странная» запись не ломает остальные).
  static Feeling fromName(Object? name) {
    for (final Feeling feeling in Feeling.values) {
      if (feeling.name == name) return feeling;
    }
    return Feeling.neutral;
  }
}

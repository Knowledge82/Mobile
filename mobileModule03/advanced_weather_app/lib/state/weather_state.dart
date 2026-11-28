import '../failures.dart';
import '../models/weather_report.dart';

// Что сейчас показывать на вкладках. Ровно одно из четырёх: «пусто», «грузим»,
// «есть данные» или «ошибка». Это и есть наследник идеи SearchRequest из модуля 01:
// «либо то, либо другое» описано ТИПОМ, а не набором флагов.
sealed class WeatherState {
  const WeatherState();
}

// Ещё ничего не запрашивали (мгновение между созданием экрана и первым запросом).
final class WeatherIdle extends WeatherState {
  const WeatherIdle();
}

final class WeatherLoading extends WeatherState {
  const WeatherLoading();
}

final class WeatherLoaded extends WeatherState {
  const WeatherLoaded(this.report);

  final WeatherReport report;
}

final class WeatherFailed extends WeatherState {
  const WeatherFailed(this.failure);

  final WeatherFailure failure;
}

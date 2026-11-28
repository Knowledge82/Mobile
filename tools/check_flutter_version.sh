#!/usr/bin/env bash
# Сверяет установленный Flutter с ожидаемой версией и с требованиями проектов.
#
#   tools/check_flutter_version.sh              # сверка с версией из setup_flutter_campus.sh
#   EXPECTED_FLUTTER=3.50.1 tools/check_flutter_version.sh
#
# Коды выхода: 0 всё совпадает; 1 версия отличается (или Dart старше, чем
# просит проект); 2 не удалось определить версию.
#
# Версию читаем из ФАЙЛОВ SDK, а не запуском `flutter`: на кампусе (NFS)
# команда `flutter` после `flutter upgrade` может зависнуть на «startup lock»,
# и проверка, которая сама зависает, никому не нужна. Запуск `flutter --version`
# остаётся запасным вариантом (с таймаутом).

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- 1. Ожидаемая версия: одна «истина» в setup_flutter_campus.sh ---------
expected="${EXPECTED_FLUTTER:-}"
if [ -z "$expected" ]; then
	expected="$(sed -n 's/^FLUTTER_VERSION="\${FLUTTER_VERSION:-\([0-9][0-9.]*\)}"$/\1/p' \
		"$ROOT/setup_flutter_campus.sh" 2>/dev/null | head -n1)"
fi
if [ -z "$expected" ]; then
	echo "Не нашла ожидаемую версию (ни EXPECTED_FLUTTER, ни строку FLUTTER_VERSION в setup_flutter_campus.sh)." >&2
	exit 2
fi

# --- 2. Где стоит SDK ---------------------------------------------------
flutter_bin="$(command -v flutter 2>/dev/null || true)"
if [ -z "$flutter_bin" ]; then
	echo "Команда flutter не найдена в PATH (на кампусе: source ~/.flutter_env.sh)." >&2
	exit 2
fi
sdk="$(cd "$(dirname "$(readlink -f "$flutter_bin")")/.." && pwd)"

# --- 3. Какая версия Flutter и Dart стоит (без запуска flutter) ---------
installed=""
if [ -f "$sdk/bin/cache/flutter.version.json" ]; then
	installed="$(sed -n 's/.*"frameworkVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
		"$sdk/bin/cache/flutter.version.json" | head -n1)"
fi
if [ -z "$installed" ] && [ -f "$sdk/version" ]; then
	installed="$(tr -d '[:space:]' < "$sdk/version")"
fi
if [ -z "$installed" ] && [ -d "$sdk/.git" ]; then
	installed="$(git -C "$sdk" describe --tags 2>/dev/null | sed 's/-.*//')"
fi
if [ -z "$installed" ]; then
	# Запасной путь: запускаем сам flutter, но не ждём вечно.
	installed="$(timeout 90 "$flutter_bin" --version 2>/dev/null | sed -n 's/^Flutter \([0-9][0-9.]*\).*/\1/p' | head -n1)"
fi
if [ -z "$installed" ]; then
	echo "Не смогла определить версию Flutter в $sdk." >&2
	echo "Если flutter висит на «Waiting for another flutter command to release the startup lock», см. README, раздел 3.3." >&2
	exit 2
fi

dart_installed=""
if [ -f "$sdk/bin/cache/dart-sdk/version" ]; then
	dart_installed="$(tr -d '[:space:]' < "$sdk/bin/cache/dart-sdk/version")"
fi

echo "SDK:               $sdk"
echo "Flutter установлен: $installed"
echo "Flutter ожидается:  $expected"
echo "Dart установлен:    ${dart_installed:-неизвестно}"

status=0

# --- 4. Сравнение с ожидаемым Flutter ----------------------------------
if [ "$installed" = "$expected" ]; then
	echo "OK: версия Flutter совпадает."
else
	status=1
	# major.minor одинаковы -> разница только в патче
	if [ "${installed%.*}" = "${expected%.*}" ]; then
		echo "ВНИМАНИЕ: отличается только патч-версия (${installed} вместо ${expected})."
		echo "  Патчи внутри ${expected%.*} обычно безопасны. Либо обновите машину"
		echo "  (дома: flutter upgrade; на кампусе: НЕ upgrade, а чистая установка скриптом),"
		echo "  либо осознанно примите ${installed} и поправьте FLUTTER_VERSION в setup_flutter_campus.sh."
	else
		echo "ВНИМАНИЕ: отличается минорная или мажорная версия (${installed} вместо ${expected})."
		echo "  Это уже может ломать сборку и тесты: прогоните flutter analyze и flutter test"
		echo "  во всех проектах и сверьте версию на второй машине."
	fi
fi

# --- 5. Хватает ли Dart для проектов (environment: sdk: ^X.Y.Z) ---------
# Берём наибольшее требование среди pubspec.yaml в репозитории.
need=""
while IFS= read -r line; do
	v="$(printf '%s\n' "$line" | sed -n 's/^[[:space:]]*sdk:[[:space:]]*"\{0,1\}[\^>=[:space:]]*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')"
	[ -n "$v" ] || continue
	if [ -z "$need" ] || [ "$(printf '%s\n%s\n' "$need" "$v" | sort -V | tail -n1)" = "$v" ]; then
		need="$v"
	fi
done < <(find "$ROOT" -name pubspec.yaml -not -path '*/.dart_tool/*' -not -path '*/build/*' \
	-exec grep -H -A0 -E '^[[:space:]]*sdk:[[:space:]]*"?[\^>=0-9]' {} + 2>/dev/null | sed 's/^[^:]*://')

if [ -n "$need" ] && [ -n "$dart_installed" ]; then
	echo "Dart нужен проектам: не ниже $need"
	if [ "$(printf '%s\n%s\n' "$need" "$dart_installed" | sort -V | head -n1)" != "$need" ]; then
		status=1
		echo "ПРОБЛЕМА: установленный Dart $dart_installed старше требуемого $need:"
		echo "  flutter pub get откажется работать (version solving failed). Обновите Flutter."
	else
		echo "OK: Dart подходит для всех проектов."
	fi
fi

exit "$status"

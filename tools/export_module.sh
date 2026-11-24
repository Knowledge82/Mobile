#!/usr/bin/env bash
# =============================================================================
# export_module.sh — выгрузка модуля из личного репозитория в репозиторий сдачи
#
# Использование (из любого места внутри личного репозитория):
#   tools/export_module.sh <NN> <путь_к_клону_репозитория_кампуса>
#   Пример: tools/export_module.sh 00 ~/Projects/campus-mobile-00
#
# Что делает:
#   1. Проверяет, что папка mobileModuleNN закоммичена (нет незакоммиченных правок).
#   2. Проверяет состав папки модуля: лишнего быть не должно.
#   3. Заменяет <кампус>/mobileModuleNN копией состояния HEAD. Берутся только
#      файлы, отслеживаемые git: build/, .dart_tool/ и всё из .gitignore не попадёт.
#   4. (CHECK=1) в выгруженной копии запускает flutter pub get / analyze / test.
#   5. Показывает git status репозитория кампуса. Коммит и push делаете вручную.
#
# Переменные окружения:
#   EXPECTED="ex00 ex01 ..."   какие папки должны быть в модуле
#                              (для модуля 00: ex00 ex01 ex02 calculator_app)
#   CHECK=1                    прогнать flutter pub get/analyze/test в копии
# =============================================================================
set -euo pipefail

log()  { printf '\033[1;36m[export]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m   %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m  %s\n' "$*" >&2; exit 1; }

[ $# -eq 2 ] || die "Использование: $0 <NN> <путь_к_репозиторию_кампуса>"

NN="$1"
DEST_ARG="$2"
case "$NN" in
	[0-9][0-9]) ;;
	*) die "NN должно состоять из двух цифр, например 00" ;;
esac
MODULE="mobileModule${NN}"

# ---------- 1. Где мы и куда выгружаем ----------------------------------------
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
	|| die "Запускайте скрипт внутри личного репозитория"
DEST="$(cd "$DEST_ARG" 2>/dev/null && pwd)" \
	|| die "Нет каталога: $DEST_ARG"
DEST_TOP="$(git -C "$DEST" rev-parse --show-toplevel 2>/dev/null)" \
	|| die "$DEST не является git-репозиторием"
[ "$DEST_TOP" = "$DEST" ] \
	|| die "$DEST находится внутри репозитория $DEST_TOP; укажите его корень"
[ "$DEST" != "$ROOT" ] \
	|| die "Репозиторий кампуса не может совпадать с личным"

# ---------- 2. Модуль должен быть закоммичен ----------------------------------
git -C "$ROOT" rev-parse --verify HEAD >/dev/null 2>&1 \
	|| die "В личном репозитории ещё нет ни одного коммита"

entries="$(git -C "$ROOT" ls-tree --name-only HEAD "$MODULE/" || true)"
[ -n "$entries" ] || die "В последнем коммите нет папки $MODULE (забыли git add / commit?)"

if [ -n "$(git -C "$ROOT" status --porcelain -- "$MODULE")" ]; then
	git -C "$ROOT" status --short -- "$MODULE" >&2
	die "В $MODULE есть незакоммиченные изменения. Закоммитьте их и запустите снова"
fi

# ---------- 3. Состав модуля --------------------------------------------------
if [ -z "${EXPECTED:-}" ] && [ "$NN" = "00" ]; then
	EXPECTED="ex00 ex01 ex02 calculator_app"
fi

if [ -n "${EXPECTED:-}" ]; then
	actual=""
	while IFS= read -r e; do
		actual="$actual ${e#"$MODULE"/}"
	done <<< "$entries"

	for a in $actual; do
		case " $EXPECTED " in
			*" $a "*) ;;
			*) die "Лишний элемент в $MODULE: '$a'. Ожидалось только: $EXPECTED" ;;
		esac
	done
	for x in $EXPECTED; do
		case " $actual " in
			*" $x "*) ;;
			*) warn "В $MODULE пока нет '$x' (нормально, если упражнение ещё не сделано)" ;;
		esac
	done
fi

# ---------- 4. Копирование ----------------------------------------------------
log "Источник : $ROOT ($MODULE, состояние HEAD $(git -C "$ROOT" rev-parse --short HEAD))"
log "Приёмник : $DEST/$MODULE"
rm -rf "${DEST:?}/${MODULE:?}"
git -C "$ROOT" archive --format=tar HEAD "$MODULE" | tar -x -C "$DEST"

# ---------- 5. Необязательная проверка копии ----------------------------------
if [ "${CHECK:-0}" = "1" ]; then
	command -v flutter >/dev/null 2>&1 \
		|| die "flutter не найден в PATH (выполните: source ~/.flutter_env.sh)"
	for p in "$DEST/$MODULE"/*/; do
		if [ ! -f "${p}pubspec.yaml" ]; then
			warn "Нет pubspec.yaml в $p, пропускаю"
			continue
		fi
		log "Проверяю $(basename "$p")"
		( cd "$p" && flutter pub get && flutter analyze && flutter test )
	done
fi

# ---------- 6. Итог -----------------------------------------------------------
log "Готово. Состояние репозитория кампуса:"
git -C "$DEST" status --short || true
cat <<EOF

Дальше вручную:
  cd $DEST
  git add -A && git status        # убедитесь, что нет build/ и .dart_tool/
  git commit -m "Module ${NN}"
  git push
EOF

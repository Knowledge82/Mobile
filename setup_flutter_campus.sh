#!/usr/bin/env bash
# =============================================================================
# setup_flutter_campus.sh — Flutter + JDK + Android SDK без sudo (кампус 42)
#
# ТОЛЬКО ДЛЯ КАМПУСА. Рассчитан на ~/sgoinfre и ~/goinfre. Дома не запускать:
# он переписывает ~/.zshrc / ~/.bashrc и ставит свой Flutter первым в PATH.
#
# Идемпотентный: повторный запуск пропускает то, что уже стоит, и доставляет
# недостающее. Запускай заново на каждой новой машине, где goinfre пустой.
#
# Переменные, которые можно переопределить перед запуском:
#   FLUTTER_VERSION=3.50.0 | latest   версия Flutter (по умолчанию — как в сабже)
#   JDK_MAJOR=17                      мажорная версия JDK, если системной нет
#   SDK_BASE=~/sgoinfre               где жить SDK (Flutter, Android, JDK)
#   CACHE_BASE=~/goinfre              где жить кэшам (Gradle, pub)
#
# Пример:  SDK_BASE=~/goinfre FLUTTER_VERSION=latest ./setup_flutter_campus.sh
# =============================================================================
set -euo pipefail

# Реальный путь этого скрипта (попадёт в напоминалку внутри ~/.flutter_env.sh)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

FLUTTER_VERSION="${FLUTTER_VERSION:-3.50.0}"
JDK_MAJOR="${JDK_MAJOR:-17}"
FALLBACK_CMDLINE_ZIP="commandlinetools-linux-13114758_latest.zip"
ENV_FILE="$HOME/.flutter_env.sh"

log()  { printf '\033[1;36m[setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- 0. Где что будет жить ---------------------------------------------
if [ -z "${SDK_BASE:-}" ]; then
	if [ -d "$HOME/sgoinfre" ] && [ -w "$HOME/sgoinfre" ]; then
		SDK_BASE="$HOME/sgoinfre"
	else
		SDK_BASE="$HOME/goinfre"
	fi
fi
CACHE_BASE="${CACHE_BASE:-$HOME/goinfre}"

[ -d "$SDK_BASE" ]   || die "Нет каталога SDK_BASE=$SDK_BASE"
[ -d "$CACHE_BASE" ] || die "Нет каталога CACHE_BASE=$CACHE_BASE"
[ -w "$SDK_BASE" ]   || die "Нет прав на запись в $SDK_BASE"

FLUTTER_DIR="$SDK_BASE/flutter"
ANDROID_DIR="$SDK_BASE/android-sdk"
JDK_DIR="$SDK_BASE/jdk-$JDK_MAJOR"
DL_DIR="$CACHE_BASE/.setup-downloads"
PUB_CACHE_DIR="$CACHE_BASE/.pub-cache"
GRADLE_DIR="$CACHE_BASE/.gradle"
AVD_DIR="$CACHE_BASE/.android-avd"

mkdir -p "$DL_DIR" "$PUB_CACHE_DIR" "$GRADLE_DIR" "$AVD_DIR"

log "SDK_BASE   = $SDK_BASE"
log "CACHE_BASE = $CACHE_BASE"

# ---------- 1. Проверки окружения ---------------------------------------------
[ "$(uname -m)" = "x86_64" ] || die "Скрипт рассчитан на x86_64, а тут $(uname -m)"

for c in tar unzip git python3; do
	command -v "$c" >/dev/null 2>&1 || die "Не найдена утилита: $c"
done
command -v wget >/dev/null 2>&1 || command -v curl >/dev/null 2>&1 \
	|| die "Нужен wget или curl"

free_kb=$(df -Pk "$SDK_BASE" | awk 'NR==2 {print $4}')
if [ "$free_kb" -lt $((6 * 1024 * 1024)) ]; then
	warn "В $SDK_BASE свободно меньше 6 ГБ ($((free_kb / 1024)) МБ). Может не хватить."
fi

# Скачать URL в файл (с докачкой)
dl() {
	if command -v wget >/dev/null 2>&1; then
		wget -q --show-progress -c -O "$2" "$1"
	else
		curl -fL -C - -o "$2" "$1"
	fi
}
# Скачать URL в stdout
dl_out() {
	if command -v wget >/dev/null 2>&1; then
		wget -qO- "$1"
	else
		curl -fsSL "$1"
	fi
}

# ---------- 2. Flutter --------------------------------------------------------
FLUTTER_BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases"

if [ -x "$FLUTTER_DIR/bin/flutter" ]; then
	log "Flutter уже стоит в $FLUTTER_DIR — пропускаю"
else
	if [ "$FLUTTER_VERSION" = "latest" ]; then
		log "Ищу последний stable Flutter..."
		archive=$(dl_out "$FLUTTER_BASE_URL/releases_linux.json" | python3 -c '
import sys, json
d = json.load(sys.stdin)
h = d["current_release"]["stable"]
print(next(r["archive"] for r in d["releases"] if r["hash"] == h))
')
	else
		archive="stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
	fi
	file="$DL_DIR/$(basename "$archive")"
	log "Качаю $archive"
	dl "$FLUTTER_BASE_URL/$archive" "$file"
	log "Распаковываю в $SDK_BASE (минуту-другую)..."
	tar xf "$file" -C "$SDK_BASE"          # создаёт $SDK_BASE/flutter
	rm -f "$file"
fi

# ---------- 3. JDK ------------------------------------------------------------
java_major() {
	"$1" -version 2>&1 | awk -F'"' '/version/ {
		split($2, v, ".");
		print (v[1] == "1") ? v[2] : v[1];
		exit
	}'
}

JAVA_HOME_SEL=""
if [ -x "$JDK_DIR/bin/java" ]; then
	JAVA_HOME_SEL="$JDK_DIR"
	log "Свой JDK уже стоит в $JDK_DIR"
elif command -v java >/dev/null 2>&1; then
	sys_major=$(java_major "$(command -v java)" || echo 0)
	if [ "${sys_major:-0}" -ge "$JDK_MAJOR" ] 2>/dev/null; then
		JAVA_HOME_SEL="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
		log "Использую системный JDK $sys_major: $JAVA_HOME_SEL"
	fi
fi

if [ -z "$JAVA_HOME_SEL" ]; then
	log "Подходящего JDK нет — ставлю Temurin $JDK_MAJOR"
	file="$DL_DIR/jdk-$JDK_MAJOR.tar.gz"
	dl "https://api.adoptium.net/v3/binary/latest/${JDK_MAJOR}/ga/linux/x64/jdk/hotspot/normal/eclipse" "$file"
	mkdir -p "$JDK_DIR"
	tar xzf "$file" -C "$JDK_DIR" --strip-components=1
	rm -f "$file"
	JAVA_HOME_SEL="$JDK_DIR"
fi

export JAVA_HOME="$JAVA_HOME_SEL"
export PATH="$JAVA_HOME/bin:$PATH"

# ---------- 4. Android SDK (cmdline-tools + пакеты) ---------------------------
SDKM="$ANDROID_DIR/cmdline-tools/latest/bin/sdkmanager"
ANDROID_REPO="https://dl.google.com/android/repository"

if [ -x "$SDKM" ]; then
	log "Android cmdline-tools уже стоят — пропускаю"
else
	log "Ищу последнюю версию Android cmdline-tools..."
	zip=$(dl_out "$ANDROID_REPO/repository2-3.xml" 2>/dev/null \
		| grep -oE 'commandlinetools-linux-[0-9]+_latest\.zip' \
		| sort -t- -k3 -n | tail -1 || true)
	[ -n "$zip" ] || { warn "Не нашла в репозитории, беру запасную"; zip="$FALLBACK_CMDLINE_ZIP"; }
	log "Качаю $zip"
	dl "$ANDROID_REPO/$zip" "$DL_DIR/$zip"
	rm -rf "$DL_DIR/cmdline-tools"
	unzip -q "$DL_DIR/$zip" -d "$DL_DIR"
	mkdir -p "$ANDROID_DIR/cmdline-tools"
	rm -rf "$ANDROID_DIR/cmdline-tools/latest"
	# sdkmanager требует строго такую структуру: cmdline-tools/latest/bin
	mv "$DL_DIR/cmdline-tools" "$ANDROID_DIR/cmdline-tools/latest"
	rm -f "$DL_DIR/$zip"
fi

export ANDROID_HOME="$ANDROID_DIR"
export ANDROID_SDK_ROOT="$ANDROID_DIR"
export ANDROID_AVD_HOME="$AVD_DIR"

log "Принимаю лицензии Android SDK..."
yes | "$SDKM" --sdk_root="$ANDROID_DIR" --licenses >/dev/null 2>&1 || true

log "Выясняю свежие platforms / build-tools..."
list_file="$DL_DIR/sdk-list.txt"
"$SDKM" --sdk_root="$ANDROID_DIR" --list > "$list_file" 2>&1 || warn "sdkmanager --list вернул ошибку (см. $list_file)"
pkg_list=$(awk -F'|' '{ gsub(/ /, "", $1); print $1 }' "$list_file")
plat=$(printf '%s\n' "$pkg_list" | grep -E '^platforms;android-[0-9]+$' \
	| sort -t- -k2 -n | tail -1 || true)
bt=$(printf '%s\n' "$pkg_list" | grep -E '^build-tools;[0-9]+\.[0-9]+\.[0-9]+$' \
	| sort -V | tail -1 || true)

# Запасные значения, если список не удалось разобрать (сеть, формат вывода)
if [ -z "$plat" ] || [ -z "$bt" ]; then
	warn "Не смогла определить свежие версии из списка — беру запасные"
	warn "Начало вывода sdkmanager --list:"
	head -n 8 "$list_file" >&2 || true
	plat="${plat:-platforms;android-36}"
	bt="${bt:-build-tools;36.0.0}"
fi

log "Ставлю: platform-tools $plat $bt"
"$SDKM" --sdk_root="$ANDROID_DIR" "platform-tools" "$plat" "$bt"

# Проверка результата: молча проглатывать провал нельзя
[ -d "$ANDROID_DIR/platforms" ] && [ -n "$(ls -A "$ANDROID_DIR/platforms" 2>/dev/null)" ] \
	|| die "В $ANDROID_DIR/platforms пусто — установка платформы не удалась"
[ -x "$ANDROID_DIR/platform-tools/adb" ] \
	|| die "adb не установился в $ANDROID_DIR/platform-tools"

# ---------- 5. Настройка Flutter ----------------------------------------------
export PUB_CACHE="$PUB_CACHE_DIR"
export GRADLE_USER_HOME="$GRADLE_DIR"
FLUTTER="$FLUTTER_DIR/bin/flutter"

log "Настраиваю flutter config..."
"$FLUTTER" config --android-sdk "$ANDROID_DIR"
"$FLUTTER" config --jdk-dir "$JAVA_HOME"
"$FLUTTER" config --no-enable-linux-desktop   # иначе doctor ругается на clang/cmake/GTK
"$FLUTTER" --disable-analytics >/dev/null 2>&1 || true

yes | "$FLUTTER" doctor --android-licenses >/dev/null 2>&1 || true

# Chrome для Flutter Web
CHROME_BIN=""
if ! command -v google-chrome >/dev/null 2>&1; then
	for c in google-chrome-stable chromium chromium-browser; do
		if command -v "$c" >/dev/null 2>&1; then
			CHROME_BIN="$(command -v "$c")"
			break
		fi
	done
fi

# ---------- 6. Файл окружения + подключение в rc ------------------------------
log "Пишу $ENV_FILE"
{
	echo "# Сгенерировано setup_flutter_campus.sh $(date '+%Y-%m-%d %H:%M')"
	echo "export FLUTTER_HOME=\"$FLUTTER_DIR\""
	echo "export JAVA_HOME=\"$JAVA_HOME\""
	echo "export ANDROID_HOME=\"$ANDROID_DIR\""
	echo "export ANDROID_SDK_ROOT=\"\$ANDROID_HOME\""
	echo "export ANDROID_AVD_HOME=\"$AVD_DIR\""
	echo "export PUB_CACHE=\"$PUB_CACHE_DIR\""
	echo "export GRADLE_USER_HOME=\"$GRADLE_DIR\""
	echo "export SETUP_FLUTTER_SCRIPT=\"$SCRIPT_PATH\""
	[ -n "$CHROME_BIN" ] && echo "export CHROME_EXECUTABLE=\"$CHROME_BIN\""
	cat <<'EOF'

# Добавить каталог в начало PATH, если его там ещё нет (без дублей при повторном source)
_fenv_prepend() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac; }
_fenv_prepend "$JAVA_HOME/bin"
_fenv_prepend "$ANDROID_HOME/cmdline-tools/latest/bin"
_fenv_prepend "$ANDROID_HOME/platform-tools"
_fenv_prepend "$PUB_CACHE/bin"
_fenv_prepend "$FLUTTER_HOME/bin"
export PATH
unset -f _fenv_prepend

# Напоминалка: на новой машине goinfre пустой
if [ ! -x "$FLUTTER_HOME/bin/flutter" ] || [ ! -d "$GRADLE_USER_HOME" ]; then
	echo "[flutter_env] На этой машине окружение неполное — запусти $SETUP_FLUTTER_SCRIPT" >&2
fi
EOF
} > "$ENV_FILE"

SOURCE_LINE='[ -f "$HOME/.flutter_env.sh" ] && . "$HOME/.flutter_env.sh"'
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
	if [ -f "$rc" ] && ! grep -qF '.flutter_env.sh' "$rc"; then
		printf '\n# Flutter / Android SDK\n%s\n' "$SOURCE_LINE" >> "$rc"
		log "Подключила окружение в $rc"
	fi
done

# ---------- 7. Проверка -------------------------------------------------------
log "Готово. Запускаю flutter doctor:"
"$FLUTTER" doctor || true

cat <<EOF

=====================================================================
 Дальше:  открой новый терминал (или: source ~/.flutter_env.sh)
          и проверь ещё раз:  flutter doctor -v
=====================================================================
EOF

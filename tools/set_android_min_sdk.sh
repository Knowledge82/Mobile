#!/usr/bin/env bash
# =============================================================================
# set_android_min_sdk.sh — поднимает minSdk Android-приложения до нужного
# значения (по умолчанию 24: так требуют плагины Firebase 7.x и выше).
#
# Использование:
#   tools/set_android_min_sdk.sh <проект>/android/app/build.gradle.kts [24]
#   tools/set_android_min_sdk.sh <проект>/android/app/build.gradle     [24]
#
# Что делает (идемпотентно, можно запускать сколько угодно раз):
#   minSdk = flutter.minSdkVersion     ->  minSdk = 24
#   minSdkVersion flutter.minSdkVersion ->  minSdkVersion 24
#   minSdk = 21 / minSdkVersion 21      ->  то же с 24 (если число меньше нужного)
# Если там уже число не меньше нужного, ничего не меняет.
# Перед первой правкой кладёт копию файла рядом с суффиксом .bak (он в .gitignore).
# =============================================================================
set -euo pipefail

die() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[ $# -ge 1 ] && [ $# -le 2 ] || die "Использование: $0 <build.gradle[.kts]> [minSdk]"
FILE="$1"
WANT="${2:-24}"
[ -f "$FILE" ] || die "Нет файла: $FILE"
case "$WANT" in ''|*[!0-9]*) die "minSdk должен быть числом, а не '$WANT'";; esac

[ -f "$FILE.bak" ] || cp "$FILE" "$FILE.bak"

python3 - "$FILE" "$WANT" <<'PY'
import re, sys

path, want = sys.argv[1], int(sys.argv[2])
text = open(path, encoding='utf-8').read()

# minSdk = ...   (Kotlin DSL)   и   minSdkVersion ... (Groovy, со знаком = или без)
pattern = re.compile(r'\b(minSdk(?:Version)?)(\s*=\s*|\s+)(flutter\.minSdkVersion|\d+)')
found = pattern.search(text)
if not found:
    sys.exit('Не нашла строку minSdk / minSdkVersion в %s: поправьте вручную.' % path)

def fix(m):
    value = m.group(3)
    if value.isdigit() and int(value) >= want:
        return m.group(0)  # уже достаточно
    return '%s%s%d' % (m.group(1), m.group(2), want)

new = pattern.sub(fix, text)
if new == text:
    print('minSdk уже не меньше %d, ничего не меняю.' % want)
else:
    open(path, 'w', encoding='utf-8').write(new)
    print('minSdk выставлен в %d.' % want)
PY

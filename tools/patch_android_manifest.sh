#!/usr/bin/env bash
# =============================================================================
# patch_android_manifest.sh — добавляет в AndroidManifest.xml разрешения,
# нужные приложению из модуля 02 (интернет и геолокация).
#
# Использование:
#   tools/patch_android_manifest.sh <проект>/android/app/src/main/AndroidManifest.xml
#
# Что добавляет (каждую строку только если её там ещё нет, поэтому скрипт
# можно запускать сколько угодно раз):
#   INTERNET               — без неё RELEASE-сборка не ходит в сеть
#                            (в debug-манифесте она есть, в основном нет)
#   ACCESS_COARSE_LOCATION — примерное местоположение
#   ACCESS_FINE_LOCATION   — точное (GPS)
#
# Строки вставляются сразу после открывающего тега <manifest ...>.
# Перед первой правкой рядом кладётся копия AndroidManifest.xml.bak (в .gitignore).
# =============================================================================
set -euo pipefail

die() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

[ $# -eq 1 ] || die "Использование: $0 <путь к AndroidManifest.xml>"
FILE="$1"
[ -f "$FILE" ] || die "Нет файла: $FILE"
grep -q '<manifest' "$FILE" || die "Это не AndroidManifest.xml: $FILE"

[ -f "$FILE.bak" ] || cp "$FILE" "$FILE.bak"

python3 - "$FILE" <<'PY'
import re, sys

path = sys.argv[1]
text = open(path, encoding='utf-8').read()

wanted = [
    'android.permission.INTERNET',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
]
missing = [p for p in wanted if p not in text]
if not missing:
    print('Всё уже на месте, ничего не меняю.')
    sys.exit(0)

m = re.search(r'<manifest\b[^>]*>', text, re.S)
if not m:
    sys.exit('Не нашёл тег <manifest ...>')

# отступ берём как у следующей строки (обычно 4 пробела)
indent = '    '
block = ''.join('\n%s<uses-permission android:name="%s" />' % (indent, p) for p in missing)
text = text[:m.end()] + block + text[m.end():]
open(path, 'w', encoding='utf-8').write(text)
print('Добавлено: ' + ', '.join(p.split('.')[-1] for p in missing))
PY

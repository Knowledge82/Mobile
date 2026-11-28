#!/usr/bin/env python3
"""Генерирует картинку с листвой для страницы входа diary_app (модуль 04).

Листья нарисованы кодом (заострённые овалы, повёрнутые в разные стороны, на
светлом фоне), поэтому у картинки нет автора и лицензии, а результат всегда
одинаковый (фиксированное зерно). Больше листьев сверху, внизу чистый светлый
фон: там стоит текст и кнопка.

Запуск (нужен только Pillow):
    python3 tools/make_leaves.py [выходной_файл]
По умолчанию пишет mobileModule04/diary_app/assets/images/leaves.jpg.
"""
import math
import random
import sys

from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else \
    "mobileModule04/diary_app/assets/images/leaves.jpg"
W, H = 1080, 1920
rnd = random.Random(11)  # фиксированное зерно

BG = (244, 248, 238)  # тот же светлый фон, что у Scaffold страницы входа
img = Image.new("RGB", (W, H), BG)


def leaf(cx, cy, length, width, angle, color):
    """Один лист: два дуговых края, заострённый с обоих концов, плюс жилка."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    pts = []
    n = 24
    for i in range(n + 1):  # верхний край
        t = i / n
        x = (t - 0.5) * length
        y = -math.sin(math.pi * t) * width / 2
        pts.append((x, y))
    for i in range(n, -1, -1):  # нижний край
        t = i / n
        x = (t - 0.5) * length
        y = math.sin(math.pi * t) * width / 2
        pts.append((x, y))
    a = math.radians(angle)
    ca, sa = math.cos(a), math.sin(a)
    rot = [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]
    d.polygon(rot, fill=color + (235,))
    # жилка по центру листа, чуть темнее
    p0 = (cx - length / 2 * ca, cy - length / 2 * sa)
    p1 = (cx + length / 2 * ca, cy + length / 2 * sa)
    dark = tuple(max(0, c - 40) for c in color)
    d.line([p0, p1], fill=dark + (200,), width=max(2, int(width / 18)))
    return layer


greens = [(46, 125, 50), (67, 160, 71), (102, 187, 106), (129, 199, 132), (27, 94, 32)]

# Листья гуще у верха и чуть в сторону (как на картинке в сабже), к низу редеют.
for _ in range(95):
    y = abs(rnd.gauss(0, 330))  # расстояние от верха
    if y > 900:
        continue
    x = rnd.uniform(-60, W + 60)
    length = rnd.uniform(220, 420)
    width = length * rnd.uniform(0.38, 0.55)
    angle = rnd.uniform(0, 360)
    color = rnd.choice(greens)
    layer = leaf(x, y, length, width, angle, color)
    img.paste(layer, (0, 0), layer)

img = img.filter(ImageFilter.GaussianBlur(0.8))
img.save(OUT, quality=84, optimize=True)
print("записано:", OUT)

#!/usr/bin/env python3
"""Генерирует фон приложения advanced_weather_app (закатное небо с облаками).

Зачем скрипт: картинка нарисована кодом, поэтому у неё нет автора и лицензии,
и её можно воспроизвести или поменять (цвета, облака, размер).
Запуск (нужны Pillow и numpy):
    python3 tools/make_background.py [выходной_файл]
По умолчанию пишет mobileModule03/advanced_weather_app/assets/images/background.jpg.
"""
import sys
import numpy as np
from PIL import Image, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else \
    "mobileModule03/advanced_weather_app/assets/images/background.jpg"
W, H = 1080, 1920
rng = np.random.default_rng(7)  # фиксированное зерно: результат всегда одинаковый


def lerp(a, b, t):
    return a + (b - a) * t


y = np.linspace(0, 1, H)[:, None]
top = np.array([14, 32, 74])
mid = np.array([52, 98, 150])
low = np.array([236, 150, 110])
hor = np.array([250, 205, 150])

t1 = np.clip(y / 0.55, 0, 1)
t2 = np.clip((y - 0.55) / 0.30, 0, 1)
t3 = np.clip((y - 0.85) / 0.15, 0, 1)
base = lerp(top, mid, t1[..., None])
base = lerp(base, low, t2[..., None] * (y[..., None] > 0.55))
base = lerp(base, hor, t3[..., None] * (y[..., None] > 0.85))
img = np.zeros((H, W, 3))
img[:] = base

# свечение у горизонта
yy, xx = np.mgrid[0:H, 0:W]
d = np.sqrt((xx - W * 0.72) ** 2 + (yy - H * 0.80) ** 2)
img = img + np.exp(-(d / 380) ** 2)[..., None] * np.array([255, 214, 160]) * 0.55


def noise(scale):
    small = rng.random((H // scale + 2, W // scale + 2))
    resized = Image.fromarray((small * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
    return np.asarray(resized, dtype=float) / 255


# облака: шум из трёх масштабов, больше всего в середине неба
n = 0.55 * noise(300) + 0.3 * noise(120) + 0.15 * noise(50)
mask = np.clip((n - 0.52) * 4.0, 0, 1) * np.exp(-((y - 0.45) / 0.28) ** 2)
mask = mask[..., None]
cloud = np.array([255, 236, 224]) * 0.9 + img * 0.1
img = img * (1 - 0.55 * mask) + cloud * (0.55 * mask)

Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)) \
    .filter(ImageFilter.GaussianBlur(1.2)) \
    .save(OUT, quality=82, optimize=True)
print("записано:", OUT)

#!/usr/bin/env python3
"""Recolours the Platformer Kit's blocks for each world.

The kit's grass and snow blocks take their colours from three gradient
swatches in Textures/colormap.png: the grass top (column 15), the snow top
(column 5) and the earth sides (column 7), each 32 by 128 pixels in the
second row. This writes a copy of the colour map per world with those
swatches replaced, to assets/palettes/<world>.png; Level.block_palette
points a level's blocks at one.

    python3 tools/palettes.py
"""
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SOURCE = os.path.join(ROOT, "assets/kenney/platformer-kit/Textures/colormap.png")
OUT = os.path.join(ROOT, "assets/palettes")

TOP, SNOW, SIDE = 15, 5, 7
ROW_Y = 256
SIZE = (32, 128)

# world: {swatch: (light, dark)}; swatches left out keep the kit's colours.
WORLDS = {
    "frosty": {SIDE: ("#a7b6d6", "#6d7ba3")},
    "pirate": {TOP: ("#f7e2a1", "#dcb468"), SNOW: ("#f7e2a1", "#dcb468"), SIDE: ("#d79f6a", "#9a6440")},
    "spooky": {TOP: ("#8f7fb8", "#4e3f7c"), SNOW: ("#b9b2c9", "#77708d"), SIDE: ("#6b6178", "#3b3446")},
    "snack": {TOP: ("#ffb3d9", "#f06fae"), SNOW: ("#fff3d6", "#f2d29b"), SIDE: ("#d9a066", "#a46a3a")},
    "gears": {TOP: ("#b8c2cf", "#7d8899"), SNOW: ("#e3c55a", "#c49a2c"), SIDE: ("#6f7584", "#434856")},
    "castle": {TOP: ("#86c46d", "#4f8c4a"), SNOW: ("#d9d4c7", "#a8a191"), SIDE: ("#a59d8e", "#6e675b")},
    "station": {TOP: ("#d4dbe6", "#97a3b8"), SNOW: ("#9fe3f0", "#4fb3cc"), SIDE: ("#5a6280", "#33394f")},
    "star": {TOP: ("#fff1a8", "#f2c94c"), SNOW: ("#fff8e0", "#ffe08a"), SIDE: ("#9d86f0", "#5a46b8")},
}


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lum(c):
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def recolour(img, column, light, dark):
    x0 = column * SIZE[0]
    a, b = hex_rgb(light), hex_rgb(dark)
    lums = [lum(img.getpixel((x0 + SIZE[0] // 2, ROW_Y + y))) for y in range(SIZE[1])]
    hi, lo = max(lums), min(lums)
    for y in range(SIZE[1]):
        # Follow the original's light-to-dark curve; flat swatches stay light.
        t = 0.0 if hi - lo < 1.0 else (hi - lums[y]) / (hi - lo)
        c = tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)
        for x in range(SIZE[0]):
            img.putpixel((x0 + x, ROW_Y + y), c)


def main():
    os.makedirs(OUT, exist_ok=True)
    for world, swatches in WORLDS.items():
        img = Image.open(SOURCE).convert("RGBA")
        for column, (light, dark) in swatches.items():
            recolour(img, column, light, dark)
        path = os.path.join(OUT, world + ".png")
        img.save(path, optimize=True)
        print("wrote", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()

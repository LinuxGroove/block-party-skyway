#!/usr/bin/env python3
"""Draws the game's icon: Zip the astronaut jumping for joy over a floating
grass island, under a rainbow Skyway, with a star to find. Writes icon.svg,
the snap's copy, and icon.png (512 px, with rsvg-convert):

    python3 tools/make_icon.py [--out=file.svg]

Shading is gradients and flat shapes rather than SVG filters, so Godot's
SVG importer draws it as a browser does. The colours are the game's own:
the Platformer Kit's grass and dirt, the Skyway's bands (SkywayBridge.BANDS)
and Zip's helmet and face.
"""

import math
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUTS = [ROOT / "icon.svg", ROOT / "snap/gui/block-party-skyway.svg"]
PNG = ROOT / "icon.png"

TILE = (16, 16, 480, 480, 92)
NAVY = "#1d2a55"

# The Skyway's bands, outside in (SkywayBridge.BANDS).
BANDS = ["#ff5a5f", "#ffa94d", "#ffe066", "#69db7c", "#4dabf7", "#9775fa"]
ARC_CENTRE = (256.0, 452.0)
ARC_OUTER = 300.0
BAND = 21.0

# The island: an isometric slab of grass blocks, 3 by 3, top centre ISLE,
# half width HW (the top face is a diamond HW by HW / 2).
ISLE = (256.0, 346.0)
HW = 132.0
GRASS = 18.0
DIRT = 52.0

# Zip: helmet centre and radius.
ZIP = (252.0, 200.0)
HELMET = 74.0

STAR = (404.0, 104.0, 50.0)


def f(v: float) -> str:
    return ("%.1f" % v).rstrip("0").rstrip(".")


def pts(p: list) -> str:
    return " ".join("%s,%s" % (f(x), f(y)) for x, y in p)


def poly(p: list, fill: str, extra: str = "") -> str:
    return '<polygon points="%s" fill="%s"%s/>' % (pts(p), fill, extra)


def circle(cx: float, cy: float, r: float, fill: str, extra: str = "") -> str:
    return '<circle cx="%s" cy="%s" r="%s" fill="%s"%s/>' % (f(cx), f(cy), f(r), fill, extra)


def ellipse(cx: float, cy: float, rx: float, ry: float, fill: str, extra: str = "") -> str:
    return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"%s/>' % (f(cx), f(cy), f(rx), f(ry), fill, extra)


def iso(u: float, v: float, h: float = 0.0) -> tuple:
    """A point on the island: u east-ish and v south-ish across the top,
    from -1 to 1, and h pixels down from the top face."""
    cx, cy = ISLE
    return (cx + (u - v) * HW / 2, cy + (u + v) * HW / 4 + h)


# --- Pieces ------------------------------------------------------------------

def sky() -> list:
    out = [
        '<rect x="0" y="0" width="512" height="512" fill="url(#sky)"/>',
        circle(120, 92, 150, "url(#sun)"),
    ]
    return out


def cloud(cx: float, cy: float, s: float, shade: str = "#d9ecff") -> list:
    """A puffy cloud: a flat-bottomed heap of circles, shaded underneath."""
    puffs = [(-1.0, 0.1, 0.55), (-0.45, -0.35, 0.7), (0.25, -0.5, 0.8), (0.9, -0.1, 0.6), (1.3, 0.2, 0.42)]
    out = []
    for dx, dy, r in puffs:
        out.append(circle(cx + dx * s, cy + dy * s + 0.12 * s, r * s, shade))
    for dx, dy, r in puffs:
        out.append(circle(cx + dx * s, cy + dy * s, r * s, "#ffffff"))
    return out


def rainbow() -> list:
    cx, cy = ARC_CENTRE
    out = []
    for i, c in enumerate(BANDS):
        r = ARC_OUTER - BAND * (i + 0.5)
        out.append('<path d="M %s %s A %s %s 0 0 1 %s %s" fill="none" stroke="%s" stroke-width="%s"/>' % (
            f(cx - r), f(cy), f(r), f(r), f(cx + r), f(cy), c, f(BAND + 0.6)))
    # A soft shine along the top of the outer band.
    r = ARC_OUTER - 4
    out.append('<path d="M %s %s A %s %s 0 0 1 %s %s" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="4"/>' % (
        f(cx - r), f(cy), f(r), f(r), f(cx + r), f(cy)))
    return out


def island() -> list:
    out = []
    # Hanging rock under the slab: two smaller steps and a tip.
    for k, (scale, drop, depth) in enumerate([(0.74, DIRT + GRASS, 34.0), (0.44, DIRT + GRASS + 34.0, 30.0)]):
        a = [iso(-scale, scale, drop), iso(scale, scale, drop), iso(scale, scale, drop + depth), iso(-scale, scale, drop + depth)]
        b = [iso(scale, scale, drop), iso(scale, -scale, drop), iso(scale, -scale, drop + depth), iso(scale, scale, drop + depth)]
        out.append(poly(a, "#d98a70"))
        out.append(poly(b, "#b0644f"))
    # The two dirt faces, then the grass lip round them.
    left = [iso(-1, 1, GRASS), iso(1, 1, GRASS), iso(1, 1, GRASS + DIRT), iso(-1, 1, GRASS + DIRT)]
    right = [iso(1, 1, GRASS), iso(1, -1, GRASS), iso(1, -1, GRASS + DIRT), iso(1, 1, GRASS + DIRT)]
    out.append(poly(left, "url(#dirtL)"))
    out.append(poly(right, "url(#dirtR)"))
    lip_l = [iso(-1, 1), iso(1, 1), iso(1, 1, GRASS), iso(-1, 1, GRASS)]
    lip_r = [iso(1, 1), iso(1, -1), iso(1, -1, GRASS), iso(1, 1, GRASS)]
    out.append(poly(lip_l, "#4cc496"))
    out.append(poly(lip_r, "#36a37b"))
    # Block seams on the dirt (three blocks a side).
    seams = []
    for t in (-1 / 3, 1 / 3):
        seams.append((iso(t, 1, GRASS), iso(t, 1, GRASS + DIRT)))
        seams.append((iso(1, t, GRASS), iso(1, t, GRASS + DIRT)))
    for a, b in seams:
        out.append('<path d="M %s %s L %s %s" fill="none" stroke="#8e5245" stroke-opacity="0.45" stroke-width="2.5"/>' % (f(a[0]), f(a[1]), f(b[0]), f(b[1])))
    # Grass drips over the dirt between the seams.
    for u in (-2 / 3, 0, 2 / 3):
        p = iso(u, 1, GRASS - 1)
        out.append(ellipse(p[0], p[1] + 2, 15, 7, "#4cc496"))
        q = iso(1, u, GRASS - 1)
        out.append(ellipse(q[0], q[1] + 2, 15, 7, "#36a37b"))
    # The top: nine blocks, checked light and dark.
    for i in range(3):
        for j in range(3):
            u0, u1 = -1 + 2 * i / 3, -1 + 2 * (i + 1) / 3
            v0, v1 = -1 + 2 * j / 3, -1 + 2 * (j + 1) / 3
            c = "#74dfb7" if (i + j) % 2 == 0 else "#68d6ad"
            out.append(poly([iso(u0, v0), iso(u1, v0), iso(u1, v1), iso(u0, v1)], c))
    # A rim of light along the back edges.
    out.append('<polyline points="%s" fill="none" stroke="#a6f2d3" stroke-width="4" stroke-linejoin="round"/>' % pts([iso(-1, 1), iso(-1, -1), iso(1, -1)]))
    # One block stacked on the back corner.
    out += block(1 / 3, 1, -1, -1 / 3)
    # Tufts and a flower.
    for u, v in ((-0.65, 0.35), (0.55, 0.55)):
        x, y = iso(u, v)
        out.append('<path d="M %s %s l -5 -10 l 5 4 l 3 -12 l 3 12 l 5 -4 l -5 10 Z" fill="#3fae86"/>' % (f(x - 3), f(y)))
    fx, fy = iso(-0.2, 0.75)
    for k in range(5):
        a = math.radians(72 * k - 90)
        out.append(circle(fx + 6 * math.cos(a), fy - 6 + 4 * math.sin(a), 4.5, "#ffffff"))
    out.append(circle(fx, fy - 6, 3.5, "#ffd23f"))
    return out


def block(u0: float, u1: float, v0: float, v1: float) -> list:
    """A grass block standing on the island over u0..u1, v0..v1."""
    h = (u1 - u0) * HW * 0.4
    top = [iso(u0, v0, -h), iso(u1, v0, -h), iso(u1, v1, -h), iso(u0, v1, -h)]
    left = [iso(u0, v1, -h), iso(u1, v1, -h), iso(u1, v1), iso(u0, v1)]
    right = [iso(u1, v1, -h), iso(u1, v0, -h), iso(u1, v0), iso(u1, v1)]
    lip = h * 0.3
    out = [
        poly(left, "#e39a80"),
        poly(right, "#bf7561"),
        poly([iso(u0, v1, -h), iso(u1, v1, -h), iso(u1, v1, -h + lip), iso(u0, v1, -h + lip)], "#4cc496"),
        poly([iso(u1, v1, -h), iso(u1, v0, -h), iso(u1, v0, -h + lip), iso(u1, v1, -h + lip)], "#36a37b"),
        poly(top, "#7fe5c0"),
        '<polyline points="%s" fill="none" stroke="#a6f2d3" stroke-width="3" stroke-linejoin="round"/>' % pts([top[3], top[0], top[1]]),
    ]
    p = iso((u0 + u1) / 2, v1, -h + lip - 1)
    out.append(ellipse(p[0], p[1] + 2, 12, 5.5, "#4cc496"))
    q = iso(u1, (v0 + v1) / 2, -h + lip - 1)
    out.append(ellipse(q[0], q[1] + 2, 12, 5.5, "#36a37b"))
    return out


def shadow() -> list:
    x, y = iso(-0.05, 0.05)
    return [ellipse(ZIP[0] + 4, y, 46, 14, NAVY, ' fill-opacity="0.22"')]


def zip_hero() -> list:
    """Zip mid-jump, arms up: the round white helmet, the blue face in its
    window, stubby arms and feet."""
    cx, cy = ZIP
    r = HELMET
    out = []
    body = "#7f86ee"
    body_dark = "#646bd8"
    # Feet below the helmet, and arms up either side.
    for dx, rot in ((-30, -18), (0, 0), (30, 18)):
        out.append(ellipse(cx + dx, cy + r * 0.88, 14, 19, body_dark, ' transform="rotate(%s %s %s)"' % (rot, f(cx + dx), f(cy + r * 0.88))))
    # Arms out from under the helmet, cheering: a stubby arm and a round hand.
    for side in (-1, 1):
        sx, sy = cx + side * r * 0.72, cy + r * 0.52
        hx, hy = cx + side * (r + 26), cy + r * 0.02
        out.append('<path d="M %s %s L %s %s" fill="none" stroke="%s" stroke-width="22" stroke-linecap="round"/>' % (f(sx), f(sy), f(hx), f(hy), body_dark))
        out.append(circle(hx, hy, 15, body))
        out.append(circle(hx - side * 3, hy - 4, 5, "#ffffff", ' fill-opacity="0.35"'))
    # The helmet.
    out.append(circle(cx, cy, r, "url(#helmet)"))
    out.append(circle(cx, cy, r - 1.5, "none", ' stroke="#b9c6e6" stroke-width="3"'))
    # The window: a dark ring round the face.
    wx, wy, wr = cx + 8, cy + 6, r * 0.66
    out.append(circle(wx, wy, wr, NAVY))
    out.append(circle(wx, wy + 2, wr - 9, "url(#face)"))
    # The face: two eyes with a glint, a smile, and the little crest.
    out.append(ellipse(wx, wy - wr + 15, 7, 6, body))
    for dx in (-15, 15):
        out.append(ellipse(wx + dx, wy + 2, 7.5, 11, NAVY))
        out.append(circle(wx + dx + 2.5, wy - 3, 2.8, "#ffffff"))
    out.append('<path d="M %s %s Q %s %s %s %s" fill="none" stroke="%s" stroke-width="4.5" stroke-linecap="round"/>' % (
        f(wx - 9), f(wy + 19), f(wx), f(wy + 27), f(wx + 9), f(wy + 19), NAVY))
    out.append(ellipse(wx - 25, wy + 16, 6, 4, "#ff9fd0", ' fill-opacity="0.8"'))
    out.append(ellipse(wx + 25, wy + 16, 6, 4, "#ff9fd0", ' fill-opacity="0.8"'))
    # Glass glare across the window, and a shine on the helmet.
    out.append('<path d="M %s %s A %s %s 0 0 1 %s %s" fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="5" stroke-linecap="round"/>' % (
        f(wx - wr * 0.62), f(wy - wr * 0.42), f(wr * 0.75), f(wr * 0.75), f(wx - wr * 0.1), f(wy - wr * 0.74)))
    out.append(ellipse(cx - r * 0.45, cy - r * 0.55, 15, 9, "#ffffff", ' transform="rotate(-35 %s %s)"' % (f(cx - r * 0.45), f(cy - r * 0.55))))
    return out


def star_shape(cx: float, cy: float, r: float, inner: float = 0.5, turn: float = -90.0) -> list:
    p = []
    for k in range(10):
        a = math.radians(turn + 36 * k)
        rr = r if k % 2 == 0 else r * inner
        p.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return p


def star() -> list:
    cx, cy, r = STAR
    out = [
        poly(star_shape(cx, cy + 4, r + 9), "#c46a00", ' stroke="#c46a00" stroke-width="10" stroke-linejoin="round"'),
        poly(star_shape(cx, cy, r + 4), "#e08a00", ' stroke="#e08a00" stroke-width="8" stroke-linejoin="round"'),
        poly(star_shape(cx, cy, r), "url(#gold)", ' stroke="#ffe680" stroke-width="3" stroke-linejoin="round"'),
    ]
    # A shine on the upper arms.
    out.append(poly(star_shape(cx - 8, cy - 10, r * 0.38, 0.5), "#ffffff", ' fill-opacity="0.3"'))
    # Sparkles.
    for sx, sy, s in ((cx - 66, cy - 22, 13), (cx + 30, cy + 64, 10), (cx + 62, cy - 50, 8)):
        out.append(poly(star_shape(sx, sy, s, 0.28, -90), "#ffffff"))
    return out


def coins() -> list:
    out = []
    for cx, cy, s in ((112, 214, 1.0), (88, 284, 0.8)):
        out.append(ellipse(cx, cy, 17 * s, 21 * s, "#d98a00"))
        out.append(ellipse(cx - 3 * s, cy, 15 * s, 20 * s, "#ffc533"))
        out.append(ellipse(cx - 3 * s, cy, 7 * s, 11 * s, "none", ' stroke="#d98a00" stroke-width="%s"' % f(4 * s)))
    return out


def defs() -> str:
    x, y, w, h, rx = TILE
    return "\n".join([
        "  <defs>",
        '    <clipPath id="tile"><rect x="%s" y="%s" width="%s" height="%s" rx="%s"/></clipPath>' % (x, y, w, h, rx),
        '    <linearGradient id="sky" gradientUnits="userSpaceOnUse" x1="0" y1="16" x2="0" y2="496">',
        '      <stop offset="0" stop-color="#2f7fe6"/><stop offset="0.6" stop-color="#7fc2f7"/><stop offset="1" stop-color="#c4e8ff"/>',
        "    </linearGradient>",
        '    <radialGradient id="sun" gradientUnits="userSpaceOnUse" cx="120" cy="92" r="150">',
        '      <stop offset="0" stop-color="#ffffff" stop-opacity="0.45"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/>',
        "    </radialGradient>",
        '    <radialGradient id="helmet" gradientUnits="userSpaceOnUse" cx="%s" cy="%s" r="%s">' % (f(ZIP[0] - 30), f(ZIP[1] - 34), f(HELMET * 1.5)),
        '      <stop offset="0" stop-color="#ffffff"/><stop offset="0.6" stop-color="#f1f5ff"/><stop offset="1" stop-color="#c9d4ee"/>',
        "    </radialGradient>",
        '    <radialGradient id="face" gradientUnits="userSpaceOnUse" cx="%s" cy="%s" r="%s">' % (f(ZIP[0]), f(ZIP[1]), f(HELMET * 0.7)),
        '      <stop offset="0" stop-color="#a3a8ff"/><stop offset="1" stop-color="#7b80ea"/>',
        "    </radialGradient>",
        '    <linearGradient id="gold" gradientUnits="userSpaceOnUse" x1="0" y1="%s" x2="0" y2="%s">' % (f(STAR[1] - STAR[2]), f(STAR[1] + STAR[2])),
        '      <stop offset="0" stop-color="#fff07a"/><stop offset="1" stop-color="#ffb21e"/>',
        "    </linearGradient>",
        '    <linearGradient id="dirtL" gradientUnits="userSpaceOnUse" x1="0" y1="%s" x2="0" y2="%s">' % (f(ISLE[1] + GRASS), f(ISLE[1] + HW / 2 + GRASS + DIRT)),
        '      <stop offset="0" stop-color="#eda287"/><stop offset="1" stop-color="#d4826a"/>',
        "    </linearGradient>",
        '    <linearGradient id="dirtR" gradientUnits="userSpaceOnUse" x1="0" y1="%s" x2="0" y2="%s">' % (f(ISLE[1] + GRASS), f(ISLE[1] + HW / 2 + GRASS + DIRT)),
        '      <stop offset="0" stop-color="#c97a64"/><stop offset="1" stop-color="#a95f4d"/>',
        "    </linearGradient>",
        "  </defs>",
    ])


def build() -> str:
    body = []
    body += sky()
    body += cloud(380, 300, 36, "#d6eafd")
    body += rainbow()
    body += cloud(64, 420, 46)
    body += cloud(452, 432, 44)
    body += cloud(58, 468, 40)
    body += cloud(456, 474, 38)
    body += coins()
    body += island()
    body += shadow()
    body += zip_hero()
    body += star()
    body += cloud(150, 494, 40)
    return "\n".join([
        '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">',
        "  <!-- Made by tools/make_icon.py: edit that and run it again. -->",
        defs(),
        '  <g clip-path="url(#tile)">',
        "\n".join("    " + b for b in body),
        "  </g>",
        "</svg>",
        "",
    ])


def main() -> None:
    svg = build()
    outs = [Path(a[6:]).resolve() for a in sys.argv if a.startswith("--out=")]
    for path in outs or OUTPUTS:
        path.write_text(svg)
        print("wrote", path)
    if not outs:
        if shutil.which("rsvg-convert"):
            subprocess.run(["rsvg-convert", "-w", "512", "-h", "512", str(OUTPUTS[0]), "-o", str(PNG)], check=True)
            print("wrote", PNG)
        else:
            print("rsvg-convert not found: icon.png is unchanged")


if __name__ == "__main__":
    main()

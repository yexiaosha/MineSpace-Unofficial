#!/usr/bin/env python3
"""Render the Minespace Unofficial mod logo.

Why this script exists
----------------------
The logo that Forge 1.12.2 shows in the mod list is not free-form: ``GuiModList$Info``
loads ``mcmod.info``'s ``logoFile`` and fits the image into a **200 x 65** pixel header
box, scaled *down* only (see ``getHeaderHeight()`` in ``GuiModList$Info``). Anything
authored as a square 256x256 icon therefore ends up as a 65x65 thumbnail with a lot of
dead space around it.

So the asset is authored as a 4:1 banner and rendered at exactly 2x the on-screen box
(400x130). ``GuiModList$Info`` then scales it by 0.5 into its own 200x65 box, which is a
clean 2x2 box filter - no shimmer, no half-pixel sampling.

Everything is drawn deterministically (seeded star field, no randomness between runs),
so the committed PNG can always be regenerated bit for bit from this file.

Usage
-----
    python tools/make-logo.py                    # the umbrella mark: logo.png, pack.png, docs/logo.png
    python tools/make-logo.py --module planets   # that module's own banner, in its own resource domain
    python tools/make-logo.py --all              # the umbrella mark plus all four module banners
    python tools/make-logo.py --preview          # ... and opens nothing; just prints paths

The four modules
----------------
This jar ships four mods (see MODULE-SPLIT-PLAN.md), and each one has its own resource namespace, so each
one can carry its own banner. They are drawn here rather than sourced from anywhere else so the five images
stay one family: same backdrop, same stars, same frame, same lighting - only the accent hue, the emblem and
the three lines of text change.

What Forge 1.12.2 actually shows, measured from ``GuiModList#updateCache``'s bytecode: the image in the mod
list comes from the resource pack's ``pack.png`` (``FMLClientHandler.getResourcePackFor(modId)`` ->
``getPackImage()``). The ``logoFile`` in ``mcmod.info`` is only consulted when the mod has *no* resource
pack, and that branch resolves the path against Forge's own class, so for a jar-based mod it finds nothing.
Every mod in this pack, without exception, ships no ``pack.png`` today - which is why the mod list shows no
logos at all. One jar is one resource pack, so the four entries share one ``pack.png``: the umbrella mark.
The per-module banners are real assets in their own domains (``logoFile`` points at them), but the mod list
itself can only ever show the umbrella one.

Requires Pillow (``python -m pip install pillow``).
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# --------------------------------------------------------------------------------------
# Geometry. All drawing code below works in this coordinate space; SS is the supersample
# factor used for anti-aliasing, so the master canvas is (W*SS, H*SS).
# --------------------------------------------------------------------------------------
W, H = 400, 130
SS = 6

# The on-screen box Forge fits this into (GuiModList$Info#getHeaderHeight).
ON_SCREEN = (200, 65)

ROOT = Path(__file__).resolve().parent.parent
OUT_JAR = ROOT / "src" / "main" / "resources" / "logo.png"
OUT_DOCS = ROOT / "docs" / "logo.png"
OUT_PACK = ROOT / "src" / "main" / "resources" / "pack.png"
ASSETS = ROOT / "src" / "main" / "resources" / "assets"

# --------------------------------------------------------------------------------------
# Palette
# --------------------------------------------------------------------------------------
BG_TOP = (9, 13, 26)
BG_BOTTOM = (20, 25, 49)
CYAN = (92, 220, 235)
CYAN_DIM = (78, 176, 196)
AMBER = (240, 172, 62)
STEEL_DIM = (110, 126, 152)
INK = (8, 11, 22)
GLOW = (44, 96, 128)


# --------------------------------------------------------------------------------------
# Palette and the five marks
#
# The drawing code below reads ACTIVE, and main() sets it before rendering. The umbrella
# default is the palette above, so running this script with no arguments still reproduces
# the committed logo.png bit for bit.
# --------------------------------------------------------------------------------------
class Palette:
    def __init__(self, accent, accent_dim, amber, rim, glow):
        self.accent = accent
        self.accent_dim = accent_dim
        self.amber = amber
        self.rim = rim
        self.glow = glow


DEFAULT_PALETTE = Palette(CYAN, CYAN_DIM, AMBER, (198, 245, 255), GLOW)
ACTIVE = DEFAULT_PALETTE


# One entry per module this jar ships. `mark` picks the emblem drawing, `mod_id` names the
# resource domain the banner is written into.
MODULES = {
    "core": {
        "mod_id": "minespace_core",
        "headline": "CORE",
        "kicker": "MINESPACE \u00b7 THE BASE",
        "tagline": "GEOLOGY, PLUGINS, THE OTHER MODS",
        "palette": DEFAULT_PALETTE,
        "mark": "gear_planet",
    },
    "planets": {
        "mod_id": "minespace_planets",
        "headline": "PLANETS",
        "kicker": "MINESPACE \u00b7 BODIES AND RUINS",
        "tagline": "106 BODIES, VEINS, RUINS, HAZARDS",
        "palette": Palette((238, 142, 72), (198, 112, 54), (255, 206, 130), (255, 226, 186), (128, 84, 48)),
        "mark": "strata",
    },
    "navigation": {
        "mod_id": "minespace_navigation",
        "headline": "NAVIGATION",
        "kicker": "MINESPACE \u00b7 MAP AND FLIGHT",
        "tagline": "STAR MAP, LANES, LAUNCH PLATFORMS",
        "palette": Palette((122, 178, 255), (84, 132, 208), (232, 176, 90), (206, 228, 255), (44, 84, 128)),
        "mark": "chart",
    },
    "cosmic": {
        "mod_id": "minespace_cosmic",
        "headline": "COSMIC",
        "kicker": "MINESPACE \u00b7 STAGE FIVE",
        "tagline": "RESEARCH, OBSERVATION, DYSON, FTL",
        "palette": Palette((196, 142, 255), (146, 100, 214), (255, 196, 120), (232, 214, 255), (96, 64, 128)),
        "mark": "dyson",
    },
}

FONT_DIR = Path("C:/Windows/Fonts")


def load_font(names: list[str], size: int) -> ImageFont.FreeTypeFont:
    """First font that exists, else Pillow's bundled default."""
    for name in names:
        path = FONT_DIR / name
        if path.is_file():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default(size)


def font_for(weight: str, size: int) -> ImageFont.FreeTypeFont:
    if weight == "bold":
        return load_font(["arialbd.ttf", "segoeuib.ttf", "tahomabd.ttf"], size)
    return load_font(["arial.ttf", "segoeui.ttf", "tahoma.ttf"], size)


def s(v: float) -> float:
    """Scale a base-space value into master-canvas space."""
    return v * SS


def box(coords: tuple[float, float, float, float]) -> tuple[float, float, float, float]:
    x0, y0, x1, y1 = coords
    return (s(x0), s(y0), s(x1), s(y1))


# --------------------------------------------------------------------------------------
# Layers
# --------------------------------------------------------------------------------------
def backdrop() -> Image.Image:
    """Deep-space gradient plus a soft glow behind the emblem."""
    img = Image.new("RGB", (W * SS, H * SS), BG_TOP)
    d = ImageDraw.Draw(img)

    for y in range(H * SS):
        t = y / (H * SS - 1)
        # ease so the gradient is darker along the top edge
        k = t ** 0.75
        d.line(
            [(0, y), (W * SS, y)],
            fill=tuple(round(a + (b - a) * k) for a, b in zip(BG_TOP, BG_BOTTOM)),
        )

    glow = Image.new("L", img.size, 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse(box((6, 18, 122, 118)), fill=70)
    gd.ellipse(box((132, 40, 400, 96)), fill=26)
    glow = glow.filter(ImageFilter.GaussianBlur(s(14)))
    img = Image.composite(Image.new("RGB", img.size, ACTIVE.glow), img, glow.point(lambda v: v))
    return img


def stars(rng: random.Random) -> Image.Image:
    layer = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(64):
        x = rng.uniform(0, W)
        y = rng.uniform(0, H)
        # keep the star field out of the wordmark block so the text stays clean
        if 92 < x < 396 and 14 < y < 116:
            continue
        r = rng.choice([0.45, 0.6, 0.75, 1.1])
        a = rng.randint(90, 210)
        d.ellipse(
            [(s(x - r), s(y - r)), (s(x + r), s(y + r))],
            fill=(220, 236, 255, a),
        )
    for _ in range(5):
        x = rng.uniform(0, W)
        y = rng.uniform(0, H)
        if 92 < x < 396 and 14 < y < 116:
            continue
        d.ellipse([(s(x - 1.6), s(y - 1.6)), (s(x + 1.6), s(y + 1.6))], fill=(190, 224, 255, 60))
        d.ellipse([(s(x - 0.7), s(y - 0.7)), (s(x + 0.7), s(y + 0.7))], fill=(255, 255, 255, 235))
    return layer.filter(ImageFilter.GaussianBlur(s(0.25)))


# The emblem is a ringed planet sitting on a gear: "mine" (industry) and "space"
# (Galacticraft) in one mark. Everything is centred on this point.
CX, CY = 40.0, 65.0


def canvas() -> Image.Image:
    return Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))


def disc(fill, radius: float) -> Image.Image:
    """A filled circle about the emblem centre."""
    layer = canvas()
    ImageDraw.Draw(layer).ellipse(
        box((CX - radius, CY - radius, CX + radius, CY + radius)), fill=fill
    )
    return layer


def directional_gradient(direction: tuple[float, float], size: int = 128) -> Image.Image:
    """Small linear-gradient ramp, upscaled later. ``direction`` points at the lit side."""
    img = Image.new("L", (size, size))
    px = img.load()
    dx, dy = direction
    for y in range(size):
        v = (y + 0.5) / size * 2 - 1
        for x in range(size):
            u = (x + 0.5) / size * 2 - 1
            t = 0.5 + (u * dx + v * dy) * 0.5
            px[x, y] = max(0, min(255, int(t * 255)))
    return img


def gear_shadow() -> Image.Image:
    """Dark toothed disc behind the planet, with a thin cyan edge so it stays visible."""
    layer = canvas()
    d = ImageDraw.Draw(layer)
    radius, teeth, tooth = 26.5, 12, 4.2
    outer = []
    for i in range(teeth * 2):
        r = radius + tooth if i % 2 == 0 else radius
        a = math.pi * 2 * i / (teeth * 2) - math.pi / 2
        outer.append((s(CX + math.cos(a) * r), s(CY + math.sin(a) * r)))
    d.polygon(outer, fill=(70, 88, 122, 255))
    d.ellipse(box((CX - 13.5, CY - 13.5, CX + 13.5, CY + 13.5)), fill=(0, 0, 0, 0))

    edge = Image.new("L", layer.size, 0)
    ImageDraw.Draw(edge).polygon(outer, outline=225)
    edge = edge.filter(ImageFilter.GaussianBlur(s(0.6)))
    glow = canvas()
    glow.paste(Image.new("RGBA", layer.size, ACTIVE.accent + (255,)), (0, 0), edge)
    layer.alpha_composite(glow)
    return layer


def planet() -> Image.Image:
    """Rocky planet: directional shading, craters, cyan rim light on the lit side."""
    layer = canvas()
    r = 22.5
    gradient = directional_gradient((-0.78, -0.62)).resize(
        (int(s(r * 2)), int(s(r * 2))), Image.BICUBIC
    )
    body = Image.composite(
        Image.new("RGBA", (int(s(r * 2)), int(s(r * 2))), (176, 194, 220, 255)),
        Image.new("RGBA", (int(s(r * 2)), int(s(r * 2))), (32, 40, 62, 255)),
        gradient,
    )

    sphere = canvas()
    sphere.alpha_composite(body, (int(s(CX - r)), int(s(CY - r))))
    cd = ImageDraw.Draw(sphere)
    for x, y, cr, col in [
        (33.0, 56.0, 5.4, (74, 88, 116)),
        (48.5, 73.0, 6.8, (62, 74, 100)),
        (35.5, 79.0, 3.6, (86, 100, 128)),
        (50.0, 53.0, 3.2, (96, 112, 142)),
    ]:
        cd.ellipse(box((x - cr, y - cr, x + cr, y + cr)), fill=col + (255,))
        cd.arc(
            box((x - cr, y - cr, x + cr, y + cr)),
            190, 340, fill=(178, 194, 220, 110), width=max(1, int(s(0.7))),
        )
    sphere = sphere.filter(ImageFilter.GaussianBlur(s(0.45)))

    # clip to the silhouette, then add the rim light
    clip = Image.new("L", layer.size, 0)
    ImageDraw.Draw(clip).ellipse(box((CX - r, CY - r, CX + r, CY + r)), fill=255)
    layer.paste(sphere, (0, 0), clip)

    rim = Image.new("L", layer.size, 0)
    ImageDraw.Draw(rim).arc(
        box((CX - r + 0.8, CY - r + 0.8, CX + r - 0.8, CY + r - 0.8)),
        150, 305, fill=225, width=max(1, int(s(0.85))),
    )
    rim = rim.filter(ImageFilter.GaussianBlur(s(0.55)))
    rim_layer = canvas()
    rim_layer.paste(Image.new("RGBA", layer.size, ACTIVE.rim + (255,)), (0, 0), rim)
    layer.alpha_composite(rim_layer)
    return layer


def ring() -> Image.Image:
    """Tilted ring, drawn on a full canvas so the rotation cannot clip it."""
    layer = canvas()
    d = ImageDraw.Draw(layer)
    half_w, half_h = 33.0, 9.5
    for inset, col, width in [
        (0.0, (58, 146, 176, 175), 0.9),
        (2.4, (128, 236, 248, 240), 1.15),
        (5.2, (44, 118, 150, 140), 0.8),
    ]:
        d.ellipse(
            box((CX - half_w + inset, CY - half_h + inset * 0.45,
                 CX + half_w - inset, CY + half_h - inset * 0.45)),
            outline=col,
            width=max(1, int(s(width))),
        )
    # sunlit (near) arc picks up the amber accent
    d.arc(
        box((CX - half_w + 2.4, CY - half_h + 1.1, CX + half_w - 2.4, CY + half_h - 1.1)),
        15, 165, fill=ACTIVE.amber + (210,), width=max(1, int(s(1.0))),
    )
    layer = layer.filter(ImageFilter.GaussianBlur(s(0.3)))
    # rotate about the emblem centre, not the canvas centre, or the ring drifts off the planet
    return layer.rotate(-18, resample=Image.BICUBIC, center=(s(CX), s(CY)), expand=False)


def split_ring(ring_layer: Image.Image) -> tuple[Image.Image, Image.Image]:
    """Back half (above the planet centre) and front half (below it), softly blended."""
    ramp = Image.new("L", (1, H * SS))
    px = ramp.load()
    for y in range(H * SS):
        t = y / (H * SS - 1)
        px[0, y] = max(0, min(255, int((t * 130 - CY - 1.4) * 255)))
    front_mask = ramp.resize(ring_layer.size, Image.BILINEAR).filter(ImageFilter.GaussianBlur(s(0.5)))
    back_mask = Image.eval(front_mask, lambda v: 255 - v)
    back = canvas()
    back.paste(ring_layer, (0, 0), back_mask)
    front = canvas()
    front.paste(ring_layer, (0, 0), front_mask)
    return back, front


def emblem(mark: str = "gear_planet") -> Image.Image:
    """The emblem block. `mark` picks which body it draws - see MODULES."""
    if mark == "strata":
        return mark_strata()
    if mark == "chart":
        return mark_chart()
    if mark == "dyson":
        return mark_dyson()
    ring_layer = ring()
    back, front = split_ring(ring_layer)
    layer = canvas()
    layer.alpha_composite(gear_shadow())
    layer.alpha_composite(back)
    layer.alpha_composite(planet())
    layer.alpha_composite(front)
    return layer


# --- the three module emblems ---------------------------------------------------------
#
# Each one keeps the umbrella emblem's language - a dark silhouette, one accent rim light,
# one amber highlight - and changes only the subject: the bodies, the chart, the star.


def mark_strata() -> Image.Image:
    """A planet cut open: crust, mantle and core in bands, with one moon on its orbit."""
    r = 26.0
    layer = canvas()
    layer.alpha_composite(disc((52, 38, 30, 255), r))

    # The bands are drawn flat and clipped to the disc, which is what makes it read as a
    # cross-section instead of a striped circle.
    clip = Image.new("L", layer.size, 0)
    ImageDraw.Draw(clip).ellipse(box((CX - r, CY - r, CX + r, CY + r)), fill=255)
    bands = canvas()
    bd = ImageDraw.Draw(bands)
    for y0, y1, colour in [
        (CY - r, CY - r + 11.5, (216, 148, 84, 255)),
        (CY - r + 11.5, CY - r + 20.5, (164, 108, 72, 255)),
        (CY - r + 20.5, CY + r, (112, 86, 80, 255)),
    ]:
        bd.rectangle(box((CX - r, y0, CX + r, y1)), fill=colour)
    layer.paste(bands, (0, 0), clip)

    rim = Image.new("L", layer.size, 0)
    ImageDraw.Draw(rim).arc(
        box((CX - r + 1.0, CY - r + 1.0, CX + r - 1.0, CY + r - 1.0)),
        150, 305, fill=210, width=max(1, int(s(1.1))),
    )
    rim = rim.filter(ImageFilter.GaussianBlur(s(0.5)))
    rim_layer = canvas()
    rim_layer.paste(Image.new("RGBA", layer.size, ACTIVE.rim + (255,)), (0, 0), rim)
    layer.alpha_composite(rim_layer)

    # One moon on a dotted orbit: the part of the mark that says "bodies", not "rock".
    orbit = canvas()
    od = ImageDraw.Draw(orbit)
    for angle in range(-40, 215, 13):
        t = math.radians(angle)
        x, y = CX + 30.0 * math.cos(t), CY + 29.0 * math.sin(t)
        od.ellipse(box((x - 0.7, y - 0.7, x + 0.7, y + 0.7)), fill=ACTIVE.accent + (160,))
    od.ellipse(box((CX + 30.0 - 4.0, CY - 4.0, CX + 30.0 + 4.0, CY + 4.0)), fill=(230, 216, 202, 255))
    od.arc(
        box((CX + 30.0 - 4.6, CY - 4.6, CX + 30.0 + 4.6, CY + 4.6)),
        120, 300, fill=(120, 96, 76, 210), width=max(1, int(s(0.8))),
    )
    layer.alpha_composite(orbit.filter(ImageFilter.GaussianBlur(s(0.3))))
    return layer


def mark_chart() -> Image.Image:
    """A plotted course on an instrument face: two orbit arcs, a route, a heading marker."""
    layer = canvas()
    d = ImageDraw.Draw(layer)
    r = 27.0
    d.ellipse(box((CX - r, CY - r, CX + r, CY + r)), outline=(78, 96, 128, 255), width=max(1, int(s(1.4))))
    d.line([(s(CX - r), s(CY)), (s(CX + r), s(CY))], fill=(70, 88, 118, 190), width=max(1, int(s(0.7))))
    d.line([(s(CX), s(CY - r)), (s(CX), s(CY + r))], fill=(70, 88, 118, 190), width=max(1, int(s(0.7))))

    for radius, start, end, squash in [(21.0, 205, 342, 0.62), (13.5, 25, 158, 0.58)]:
        d.arc(
            box((CX - radius, CY - radius * squash, CX + radius, CY + radius * squash)),
            start, end, fill=ACTIVE.accent + (205,), width=max(1, int(s(1.1))),
        )

    route = [(CX - 17.0, CY + 13.0), (CX - 5.0, CY + 3.0), (CX + 9.0, CY - 7.0)]
    d.line([(s(x), s(y)) for x, y in route], fill=(238, 246, 255, 235), width=max(1, int(s(1.7))))
    for x, y in route[:-1]:
        d.ellipse(box((x - 1.7, y - 1.7, x + 1.7, y + 1.7)), fill=(238, 246, 255, 255))

    # The destination is the only amber in the mark, the way the umbrella mark uses it once.
    dx, dy = route[-1]
    d.polygon(
        [(s(dx + 8.4), s(dy - 4.5)), (s(dx - 1.0), s(dy - 2.2)), (s(dx + 1.6), s(dy + 4.6))],
        fill=ACTIVE.amber + (255,),
    )
    return layer.filter(ImageFilter.GaussianBlur(s(0.35)))


def mark_dyson() -> Image.Image:
    """A star inside a segmented shell: the swarm rather than the finished sphere."""
    layer = canvas()

    glow = Image.new("L", layer.size, 0)
    ImageDraw.Draw(glow).ellipse(box((CX - 20.0, CY - 20.0, CX + 20.0, CY + 20.0)), fill=155)
    glow = glow.filter(ImageFilter.GaussianBlur(s(6.5)))
    glow_layer = canvas()
    glow_layer.paste(Image.new("RGBA", layer.size, ACTIVE.amber + (255,)), (0, 0), glow)
    layer.alpha_composite(glow_layer)

    core = Image.new("L", layer.size, 0)
    ImageDraw.Draw(core).ellipse(box((CX - 8.5, CY - 8.5, CX + 8.5, CY + 8.5)), fill=255)
    core = core.filter(ImageFilter.GaussianBlur(s(1.1)))
    core_layer = canvas()
    core_layer.paste(Image.new("RGBA", layer.size, (255, 250, 238, 255)), (0, 0), core)
    layer.alpha_composite(core_layer)

    shell = canvas()
    sd = ImageDraw.Draw(shell)
    for angle in range(0, 360, 15):
        t = math.radians(angle)
        x, y = CX + 28.0 * math.cos(t), CY + 28.0 * 0.45 * math.sin(t)
        sd.ellipse(box((x - 1.5, y - 1.5, x + 1.5, y + 1.5)), fill=ACTIVE.accent + (215,))
    sd.arc(
        box((CX - 31.5, CY - 31.5 * 0.45, CX + 31.5, CY + 31.5 * 0.45)),
        200, 340, fill=(120, 96, 84, 170), width=max(1, int(s(0.8))),
    )
    layer.alpha_composite(shell.filter(ImageFilter.GaussianBlur(s(0.35))))
    return layer


# --------------------------------------------------------------------------------------
# Text helpers
# --------------------------------------------------------------------------------------
def tracked_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    font: ImageFont.FreeTypeFont,
    tracking: float,
    fill,
    anchor_x: str = "left",
) -> float:
    """Draw text with extra letter spacing; returns the total advance in base units."""
    widths = [draw.textlength(ch, font=font) / SS for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x, y = xy
    if anchor_x == "center":
        x -= total / 2
    elif anchor_x == "right":
        x -= total
    for ch, w in zip(text, widths):
        draw.text((s(x), s(y)), ch, font=font, fill=fill)
        x += w + tracking
    return total


def tracked_width(text: str, font: ImageFont.FreeTypeFont, tracking: float) -> float:
    """The advance `tracked_text` draws with, in base units - used to fit a headline."""
    return sum(font.getlength(ch) / SS for ch in text) + tracking * (len(text) - 1)


def fit_size(text: str, weight: str, tracking: float, limit: float, start: int, floor: int) -> int:
    """The largest size at or below `start` whose tracked text stays inside `limit` base units.

    Nothing about these banners is free text: a headline that overruns simply loses its last
    letters off the right edge, which is how the first four module taglines shipped broken.
    """
    size = start
    while size > floor and tracked_width(text, font_for(weight, int(s(size))), tracking) > limit:
        size -= 1
    return size


def text_mask(
    text: str,
    font: ImageFont.FreeTypeFont,
    xy: tuple[float, float],
    tracking: float,
) -> Image.Image:
    mask = Image.new("L", (W * SS, H * SS), 0)
    tracked_text(ImageDraw.Draw(mask), xy, text, font, tracking, 255)
    return mask


def gradient_fill(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    grad = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(grad)
    for y in range(H * SS):
        t = y / (H * SS - 1)
        d.line(
            [(0, y), (W * SS, y)],
            fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,),
        )
    return grad


def wordmark(
    img: Image.Image,
    draw: ImageDraw.ImageDraw,
    headline_text: str = "MINESPACE",
    kicker_text: str = "UNOFFICIAL",
    tagline_text: str = "GTCEu + GALACTICRAFT ADDON",
) -> None:
    """Headline with its kicker and tagline underneath. The type only shrinks if it must."""
    x = 96.0
    tracking = 1.6

    f_big = font_for("bold", int(s(fit_size(headline_text, "bold", tracking, W - x - 2, 40, 18))))

    # drop shadow so the wordmark survives on top of the star field
    shadow = text_mask(headline_text, f_big, (x + 1.2, 17.2), tracking)
    shadow = shadow.filter(ImageFilter.GaussianBlur(s(1.6))).point(lambda v: int(v * 0.75))
    shadow_layer = Image.new("RGBA", img.size, INK + (255,))
    shadow_layer.putalpha(shadow)
    img.alpha_composite(shadow_layer)

    face = text_mask(headline_text, f_big, (x, 16.0), tracking)
    img.alpha_composite(
        Image.composite(gradient_fill((255, 255, 255), ACTIVE.accent), canvas(), face)
    )

    # hairline under the headline, fading out to the right
    rule = canvas()
    rd = ImageDraw.Draw(rule)
    for i in range(int(294 * SS)):
        t = i / (294 * SS - 1)
        rd.line(
            [(s(96) + i, s(56.0)), (s(96) + i, s(57.1))],
            fill=ACTIVE.accent + (int(215 * (1 - t) ** 1.6),),
        )
    img.alpha_composite(rule)

    f_kicker = font_for("bold", int(s(fit_size(kicker_text, "bold", 3.3, W - x - 6, 13, 8))))
    tracked_text(draw, (x + 0.4, 63.0), kicker_text, f_kicker, 3.3, ACTIVE.amber + (245,))

    f_tagline = font_for("regular", int(s(fit_size(tagline_text, "regular", 1.6, W - x - 6, 11, 7))))
    tracked_text(
        draw, (x + 0.4, 86.0), tagline_text, f_tagline, 1.6, ACTIVE.accent_dim + (255,)
    )


def frame(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(
        box((1.2, 1.2, W - 1.2, H - 1.2)),
        radius=s(9),
        outline=STEEL_DIM + (150,),
        width=max(1, int(s(2.0))),
    )
    d.rounded_rectangle(
        box((3.4, 3.4, W - 3.4, H - 3.4)),
        radius=s(7),
        outline=(30, 44, 70, 170),
        width=max(1, int(s(0.7))),
    )
    for cx, cy, sx, sy in [
        (2.6, 2.6, 1, 1),
        (W - 2.6, 2.6, -1, 1),
        (2.6, H - 2.6, 1, -1),
        (W - 2.6, H - 2.6, -1, -1),
    ]:
        d.line([(s(cx), s(cy)), (s(cx + sx * 16), s(cy))], fill=ACTIVE.accent + (245,), width=max(1, int(s(2.2))))
        d.line([(s(cx), s(cy)), (s(cx), s(cy + sy * 16))], fill=ACTIVE.accent + (245,), width=max(1, int(s(2.2))))
    img.alpha_composite(layer)


def divider(img: Image.Image) -> None:
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    top, bottom, x = 26.0, 104.0, 80.0
    steps = int((bottom - top) * SS)
    for i in range(steps):
        t = i / (steps - 1)
        a = int(150 * math.sin(math.pi * t) ** 0.8)
        d.line(
            [(s(x), s(top) + i), (s(x) + max(1, int(s(0.8))), s(top) + i)],
            fill=ACTIVE.accent + (a,),
        )
    img.alpha_composite(layer)


def render(
    headline_text: str = "MINESPACE",
    kicker_text: str = "UNOFFICIAL",
    tagline_text: str = "GTCEu + GALACTICRAFT ADDON",
    mark: str = "gear_planet",
) -> Image.Image:
    rng = random.Random(20261008)
    img = backdrop().convert("RGBA")
    img.alpha_composite(stars(rng))
    img.alpha_composite(emblem(mark))
    divider(img)
    draw = ImageDraw.Draw(img)
    wordmark(img, draw, headline_text, kicker_text, tagline_text)
    frame(img)
    return img


def write(master: Image.Image, banner: Path, large: Path) -> None:
    """The banner at 1x for the jar and 4x for the docs."""
    banner.parent.mkdir(parents=True, exist_ok=True)
    large.parent.mkdir(parents=True, exist_ok=True)
    master.resize((W, H), Image.LANCZOS).save(banner, "PNG", optimize=True)
    master.resize((W * 4, H * 4), Image.LANCZOS).save(large, "PNG", optimize=True)
    print(f"{banner}  ({W}x{H})")
    print(f"{large}  ({W * 4}x{H * 4})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", choices=sorted(MODULES), help="render one module's own banner")
    parser.add_argument("--all", action="store_true", help="the umbrella mark plus every module banner")
    parser.add_argument("--preview", action="store_true", help="only report output paths")
    args = parser.parse_args()

    global ACTIVE

    if args.module:
        module = MODULES[args.module]
        ACTIVE = module["palette"]
        write(
            render(module["headline"], module["kicker"], module["tagline"], module["mark"]),
            ASSETS / module["mod_id"] / "logo.png",
            ROOT / "docs" / f"logo-{args.module}.png",
        )
    else:
        ACTIVE = DEFAULT_PALETTE
        master = render()
        write(master, OUT_JAR, OUT_DOCS)
        # pack.png is the image Forge actually puts in the mod list (see the module docstring):
        # one jar is one resource pack, so all four entries show this same umbrella mark.
        master.resize((W, H), Image.LANCZOS).save(OUT_PACK, "PNG", optimize=True)
        print(f"{OUT_PACK}  ({W}x{H})  <- the mod list reads this one")

    if args.all:
        for name in sorted(MODULES):
            module = MODULES[name]
            ACTIVE = module["palette"]
            write(
                render(module["headline"], module["kicker"], module["tagline"], module["mark"]),
                ASSETS / module["mod_id"] / "logo.png",
                ROOT / "docs" / f"logo-{name}.png",
            )

    print(f"on-screen in the mod list: {ON_SCREEN[0]}x{ON_SCREEN[1]} (exact 0.5x downscale)")


if __name__ == "__main__":
    main()

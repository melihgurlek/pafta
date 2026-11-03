#!/usr/bin/env python3
"""Build the Pafta window decorations (Aurorae SVG themes): PaftaPaper and PaftaNight.

A window is an inset on the map: square, a 1px keyline, a narrow mat of header paper around
the content, and the title set flush left like a map label. Buttons are thin line glyphs;
close fills with road red under the pointer, the others with a raised paper tile.

    python3 -I plasma/aurorae/build.py [--install]
"""
import shutil
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PAL = tomllib.loads((ROOT / "palette.toml").read_text())
DEST = ROOT / "home/.local/share/aurorae/themes"

P = 28          # shadow padding around the frame
B = 4           # side and bottom border: 1px keyline + 3px mat
T = 32          # title bar height, keyline included
BW, BH = 30, 26  # button cell


def shadow_stops(strength):
    # a gaussian-ish falloff from the frame outwards
    pts = [(0, 1), (0.12, 0.72), (0.3, 0.38), (0.5, 0.15), (0.72, 0.04), (1, 0)]
    return "".join(f'<stop offset="{o}" stop-color="#000" stop-opacity="{a * strength:.3f}"/>' for o, a in pts)


def frame(prefix, p, active, maximized=False):
    bg = p["header"]
    line = p["ink"] if active else p["rule"]
    lop = 0.55 if active else 1.0
    strength = 0.26 if active else 0.14
    pad, bd, top = (0, 1, T - 1) if maximized else (P, B, T)
    sid = prefix.replace("-", "")
    defs = (f'<linearGradient id="{sid}gv" x1="0" y1="1" x2="0" y2="0">{shadow_stops(strength)}</linearGradient>'
            f'<linearGradient id="{sid}gh" x1="1" y1="0" x2="0" y2="0">{shadow_stops(strength)}</linearGradient>'
            f'<radialGradient id="{sid}gr" cx="1" cy="1" r="1" fx="1" fy="1">{shadow_stops(strength)}</radialGradient>')
    W_ = pad + bd           # left/right column width
    TOP = pad + top         # top row height
    BOT = pad + bd          # bottom row height
    E = 8                   # stretchable piece size
    ox, oy = 10, 10
    parts = []

    def piece(name, x, y, w, h, body):
        parts.append(f'<g id="{prefix}{name}" transform="translate({ox + x},{oy + y})">'
                     f'<rect width="{w}" height="{h}" fill="#000" fill-opacity="0"/>{body}</g>')

    # shadows are drawn in each piece's padding band
    def corner_tl(h_frame):
        out = ""
        if pad:
            out += f'<rect width="{pad}" height="{pad}" fill="url(#{sid}gr)"/>'
            out += f'<rect y="{pad}" width="{pad}" height="{h_frame}" fill="url(#{sid}gh)"/>'
            out += f'<rect x="{pad}" width="{bd}" height="{pad}" fill="url(#{sid}gv)"/>'
        return out

    # top-left: shadow corner, then title bar corner with keyline
    tl = corner_tl(top)
    tl += f'<rect x="{pad}" y="{pad}" width="{bd}" height="{top}" fill="{bg}"/>'
    if not maximized:
        tl += f'<rect x="{pad}" y="{pad}" width="{bd}" height="1" fill="{line}" fill-opacity="{lop}"/>'
        tl += f'<rect x="{pad}" y="{pad + 1}" width="1" height="{top - 1}" fill="{line}" fill-opacity="{lop}"/>'
    piece("topleft", 0, 0, W_, TOP, tl)

    top_body = (f'<rect width="{E}" height="{pad}" fill="url(#{sid}gv)"/>' if pad else "")
    top_body += f'<rect y="{pad}" width="{E}" height="{top}" fill="{bg}"/>'
    if not maximized:
        top_body += f'<rect y="{pad}" width="{E}" height="1" fill="{line}" fill-opacity="{lop}"/>'
    piece("top", W_ + 4, 0, E, TOP, top_body)

    piece("topright", W_ + E + 8, 0, W_, TOP,
          f'<g transform="translate({W_},0) scale(-1,1)">{tl}</g>')

    left = (f'<rect width="{pad}" height="{E}" fill="url(#{sid}gh)"/>' if pad else "")
    left += f'<rect x="{pad}" width="{bd}" height="{E}" fill="{bg}"/>'
    if not maximized:
        left += f'<rect x="{pad}" width="1" height="{E}" fill="{line}" fill-opacity="{lop}"/>'
    piece("left", 0, TOP + 4, W_, E, left)
    piece("center", W_ + 4, TOP + 4, E, E, f'<rect width="{E}" height="{E}" fill="{p["window"]}"/>')
    piece("right", W_ + E + 8, TOP + 4, W_, E, f'<g transform="translate({W_},0) scale(-1,1)">{left}</g>')

    bl = ""
    if pad:
        bl += f'<rect y="{bd}" width="{pad}" height="{pad}" fill="url(#{sid}gr)" transform="translate(0,{BOT + bd}) scale(1,-1)"/>'
        bl += f'<rect width="{pad}" height="{bd}" fill="url(#{sid}gh)"/>'
        bl += f'<rect x="{pad}" y="{bd}" width="{bd}" height="{pad}" fill="url(#{sid}gv)" transform="translate(0,{BOT + bd}) scale(1,-1)"/>'
    bl += f'<rect x="{pad}" width="{bd}" height="{bd}" fill="{bg}"/>'
    if not maximized:
        bl += f'<rect x="{pad}" width="1" height="{bd}" fill="{line}" fill-opacity="{lop}"/>'
        bl += f'<rect x="{pad}" y="{bd - 1}" width="{bd}" height="1" fill="{line}" fill-opacity="{lop}"/>'
    piece("bottomleft", 0, TOP + E + 8, W_, BOT, bl)
    bot = f'<rect width="{E}" height="{bd}" fill="{bg}"/>'
    if pad:
        bot += f'<rect y="{bd}" width="{E}" height="{pad}" fill="url(#{sid}gv)" transform="translate(0,{BOT + bd}) scale(1,-1)"/>'
    if not maximized:
        bot += f'<rect y="{bd - 1}" width="{E}" height="1" fill="{line}" fill-opacity="{lop}"/>'
    piece("bottom", W_ + 4, TOP + E + 8, E, BOT, bot)
    piece("bottomright", W_ + E + 8, TOP + E + 8, W_, BOT, f'<g transform="translate({W_},0) scale(-1,1)">{bl}</g>')
    return defs, "".join(parts)


def decoration_svg(p):
    defs, body = [], []
    y = 0
    for prefix, active, maxi in (("decoration-", True, False), ("decoration-inactive-", False, False),
                                 ("decoration-maximized-", True, True),
                                 ("decoration-maximized-inactive-", False, True)):
        d, b = frame(prefix, p, active, maxi)
        defs.append(d)
        body.append(f'<g transform="translate(0,{y})">{b}</g>')
        y += 200
    # mask: the content rectangle, square
    body.append('<g transform="translate(400,0)">' + "".join(
        f'<rect id="mask-{n}" x="{i * 12}" y="0" width="8" height="8" fill="#000"/>'
        for i, n in enumerate(("topleft", "top", "topright", "left", "center", "right",
                               "bottomleft", "bottom", "bottomright"))) + "</g>")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="600" height="{y}">'
            f'<defs>{"".join(defs)}</defs>{"".join(body)}</svg>')


GLYPHS = {
    "close": lambda c, w: (f'<path d="M-4.5,-4.5 L4.5,4.5 M4.5,-4.5 L-4.5,4.5" stroke="{c}" stroke-width="{w}" '
                           f'stroke-linecap="square" fill="none"/>'),
    "maximize": lambda c, w: f'<rect x="-4.5" y="-4.5" width="9" height="9" stroke="{c}" stroke-width="{w}" fill="none"/>',
    "restore": lambda c, w: (f'<rect x="-4.5" y="-2" width="7" height="7" stroke="{c}" stroke-width="{w}" fill="none"/>'
                             f'<path d="M-2,-2 V-4.5 H5 V2.5 H2.5" stroke="{c}" stroke-width="{w}" fill="none"/>'),
    "minimize": lambda c, w: f'<path d="M-4.5,3.5 H4.5" stroke="{c}" stroke-width="{w}" fill="none"/>',
    "alldesktops": lambda c, w: f'<circle r="3" stroke="{c}" stroke-width="{w}" fill="none"/>',
    "keepabove": lambda c, w: f'<path d="M-4,2 L0,-2.5 L4,2" stroke="{c}" stroke-width="{w}" fill="none"/>',
    "keepbelow": lambda c, w: f'<path d="M-4,-2 L0,2.5 L4,-2" stroke="{c}" stroke-width="{w}" fill="none"/>',
}


def button_svg(kind, p):
    paper = PAL["paper"]["view"]
    states = {
        "active": (None, p["ink2"]),
        "inactive": (None, p["ink3"]),
        "hover": ((p["red"], 1) if kind == "close" else (p["raised"], 1), paper if kind == "close" else p["ink"]),
        "pressed": ((p["red"], 0.8) if kind == "close" else (p["rule"], 1), paper if kind == "close" else p["ink"]),
        "deactivated": (None, p["rule"]),
    }
    out = []
    for i, (state, (bg, fg)) in enumerate(states.items()):
        x = i * (BW + 6)
        tile = f'<rect x="3" y="3" width="{BW - 6}" height="{BH - 6}" fill="{bg[0]}" fill-opacity="{bg[1]}"/>' if bg else ""
        out.append(f'<g id="{state}-center" transform="translate({x},0)">'
                   f'<rect width="{BW}" height="{BH}" fill="#000" fill-opacity="0"/>{tile}'
                   f'<g transform="translate({BW / 2},{BH / 2})">{GLYPHS[kind](fg, 1.2)}</g></g>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{len(states) * (BW + 6)}" height="{BH}">{"".join(out)}</svg>'


def rc(p):
    c = lambda h: ",".join(str(int(h[i:i + 2], 16)) for i in (1, 3, 5))
    return f"""[General]
ActiveTextColor={c(p['ink'])}
InactiveTextColor={c(p['ink3'])}
TitleAlignment=Left
TitleVerticalAlignment=Center
UseTextShadow=false
Shadow=true
Animation=0
DecorationPosition=0

[Layout]
BorderLeft={B}
BorderRight={B}
BorderBottom={B}
TitleEdgeTop=3
TitleEdgeBottom=3
TitleEdgeLeft=14
TitleEdgeRight=4
TitleBorderLeft=0
TitleBorderRight=8
TitleHeight={T - 6}
ButtonWidth={BW}
ButtonHeight={BH}
ButtonSpacing=0
ButtonMarginTop=0
ExplicitButtonSpacer=8
PaddingTop={P}
PaddingBottom={P}
PaddingLeft={P}
PaddingRight={P}
TitleEdgeTopMaximized=2
TitleEdgeBottomMaximized=3
TitleEdgeLeftMaximized=14
TitleEdgeRightMaximized=4
"""


def build(name, title, p):
    out = DEST / name
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / "decoration.svg").write_text(decoration_svg(p))
    for kind in GLYPHS:
        (out / f"{kind}.svg").write_text(button_svg(kind, p))
    (out / f"{name}rc").write_text(rc(p))
    (out / "metadata.desktop").write_text(
        f"[Desktop Entry]\nName={title}\nX-KDE-PluginInfo-Author=Claude, for Melih\n"
        f"X-KDE-PluginInfo-Name={name}\nX-KDE-PluginInfo-Version=1.0\nX-KDE-PluginInfo-License=GPL_V3\n"
        "X-KDE-PluginInfo-EnabledByDefault=true\n")


def main():
    build("PaftaPaper", "Pafta Paper", PAL["paper"])
    build("PaftaNight", "Pafta Night", PAL["night"])
    print("built", DEST)
    if "--install" in sys.argv:
        target = Path.home() / ".local/share/aurorae/themes"
        for n in ("PaftaPaper", "PaftaNight"):
            if (target / n).exists():
                shutil.rmtree(target / n)
            shutil.copytree(DEST / n, target / n)
        print("installed")


if __name__ == "__main__":
    main()

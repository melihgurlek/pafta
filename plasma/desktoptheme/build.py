#!/usr/bin/env python3
"""Build the Pafta Plasma styles: pafta-paper (day) and pafta-night.

Panels are the sheet's margin: flat, square, with one hairline where they meet the map.
Popups are legend boxes: square, a keyline and a thin inner rule. Task buttons get graticule
ticks on the screen edge: a short ink tick for a running app, a longer magenta overprint tick
for the active one (the only magenta on the rail besides the north arrow), ochre for
attention, a faint one for minimised windows, and a second short tick for several windows.

Plasma's SVG colour classes have no role for an accent other than the selection colour, so
the colours are written into the SVGs and each style carries its own colour scheme; the sun
service switches between the two.

    python3 -I plasma/desktoptheme/build.py [--install]
"""
import gzip
import json
import shutil
import subprocess
import sys
import tomllib
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BREEZE = Path("/usr/share/plasma/desktoptheme/default")
PAL = tomllib.loads((ROOT / "palette.toml").read_text())
DEST = ROOT / "home/.local/share/plasma/desktoptheme"
SVG = "http://www.w3.org/2000/svg"
K = 6

FRAME_IDS = {p + s for p in ("", "mask-") for s in (
    "top", "bottom", "left", "right", "center", "topleft", "topright", "bottomleft", "bottomright")}
FRAME_IDS |= {f"hint-{s}-margin" for s in ("top", "bottom", "left", "right")}
FRAME_IDS.add("hint-tile-center")


def frame(prefix, fill, alpha, lines, ox, oy):
    """Nine square pieces. lines = [(offset, colour, opacity)], drawn as filled 1px rects."""
    f = f"fill:{fill};fill-opacity:{alpha}"
    def corner():
        out = [f'<rect width="{K}" height="{K}" style="{f}"/>']
        for d, c, a in lines:
            st = f"fill:{c};fill-opacity:{a}"
            out.append(f'<rect x="{d}" y="{d}" width="{K - d}" height="1" style="{st}"/>')
            out.append(f'<rect x="{d}" y="{d + 1}" width="1" height="{K - d - 1}" style="{st}"/>')
        return "".join(out)
    def edge():
        out = [f'<rect width="{K}" height="{K}" style="{f}"/>']
        for d, c, a in lines:
            out.append(f'<rect y="{d}" width="{K}" height="1" style="fill:{c};fill-opacity:{a}"/>')
        return "".join(out)
    c, e = corner(), edge()
    s = K + 4
    X, Y = [ox, ox + s, ox + 2 * s], [oy, oy + s, oy + 2 * s]
    place = {
        "topleft": (c, f"translate({X[0]},{Y[0]})"),
        "topright": (c, f"translate({X[2] + K},{Y[0]}) scale(-1,1)"),
        "bottomleft": (c, f"translate({X[0]},{Y[2] + K}) scale(1,-1)"),
        "bottomright": (c, f"translate({X[2] + K},{Y[2] + K}) scale(-1,-1)"),
        "top": (e, f"translate({X[1]},{Y[0]})"),
        "bottom": (e, f"translate({X[1]},{Y[2] + K}) scale(1,-1)"),
        "left": (e, f"matrix(0,1,1,0,{X[0]},{Y[1]})"),
        "right": (e, f"matrix(0,1,-1,0,{X[2] + K},{Y[1]})"),
        "center": (f'<rect width="{K}" height="{K}" style="{f}"/>', f"translate({X[1]},{Y[1]})"),
    }
    return "".join(f'<g id="{prefix}{n}" transform="{t}">{b}</g>' for n, (b, t) in place.items())


def hints(ox, oy, m, prefix=""):
    if isinstance(m, int):
        m = dict(top=m, bottom=m, left=m, right=m)
    return (f'<rect id="{prefix}hint-top-margin" x="{ox}" y="{oy}" width="1" height="{m["top"]}"/>'
            f'<rect id="{prefix}hint-bottom-margin" x="{ox + 4}" y="{oy}" width="1" height="{m["bottom"]}"/>'
            f'<rect id="{prefix}hint-left-margin" x="{ox + 8}" y="{oy}" width="{m["left"]}" height="1"/>'
            f'<rect id="{prefix}hint-right-margin" x="{ox + 8}" y="{oy + 4}" width="{m["right"]}" height="1"/>')


def register_namespaces(raw, tmpdir):
    tmp = tmpdir / ".tmp.svg"
    tmp.write_bytes(raw)
    for _, (pfx, uri) in ET.iterparse(tmp, events=["start-ns"]):
        ET.register_namespace(pfx, uri)
    tmp.unlink()


def restyle(src, dst, extra):
    """A Breeze frame file with its frame pieces swapped for ours (Breeze's shadows kept)."""
    raw = gzip.decompress(src.read_bytes())
    dst.parent.mkdir(parents=True, exist_ok=True)
    register_namespaces(raw, dst.parent)
    root = ET.fromstring(raw)
    for parent in list(root.iter()):
        for child in list(parent):
            if child.get("id") in FRAME_IDS:
                parent.remove(child)
    for el in ET.fromstring(f'<g xmlns="{SVG}">{extra}</g>'):
        root.append(el)
    write(dst, ET.tostring(root, encoding="unicode"))


def write(dst, text):
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(gzip.compress(text.encode(), mtime=0))


# ---------------------------------------------------------------- task ticks
EDGES = {"": "bottom", "north-": "top", "west-": "left", "east-": "right"}
TASK_MARGINS = (8, 5)  # across the panel, along it: 32px icons on the 48px rail


def task_states(p):
    ink, mag, och, ink3, raised = p["ink"], p["magenta"], p["ochre"], p["ink3"], p["raised"]
    return {  # wash (colour, opacity), tick (colour, opacity, length-mode)
        "normal": ((raised, 0), (ink, 0.85, "short")),
        "hover": ((raised, 0.55), None),
        "focus": ((raised, 0.75), (mag, 1, "long")),
        "attention": ((och, 0.14), (och, 1, "long")),
        "minimized": ((raised, 0), (ink3, 0.8, "short")),
        "progress": ((p["blue"], 0.18), None),
        "normal-hover": ((raised, 0.55), (ink, 0.85, "short")),
        "focus-hover": ((raised, 0.9), (mag, 1, "long")),
        "attention-hover": ((och, 0.2), (och, 1, "long")),
        "minimized-hover": ((raised, 0.55), (ink3, 0.8, "short")),
        "launcher-hover": ((raised, 0.55), None),
    }


def task_svg(p):
    """Each state is drawn for a bottom panel, then rotated for the other edges. The tick lies on
    the screen edge; its length comes from how much of the edge the corner pieces keep blank."""
    out, y = [], 0
    states = task_states(p)
    for prefix, side in EDGES.items():
        for state, (wash, tick) in states.items():
            out.append(task_frame(prefix, state, side, wash, tick, 0, y))
            y += 70
    # several windows: a second, shorter tick next to the first (drawn 4px inside it)
    gx = 600
    for side, (gw, gh, lx, ly, lw, lh) in {
        "bottom": (10, 6, 0, 1, 10, 2), "top": (10, 6, 0, 3, 10, 2),
        "left": (6, 10, 3, 0, 2, 10), "right": (6, 10, 1, 0, 2, 10),
    }.items():
        out.append(f'<g id="group-expander-{side}" transform="translate({gx},0)">'
                   f'<rect width="{gw}" height="{gh}" style="fill:#000;fill-opacity:0"/>'
                   f'<rect x="{lx}" y="{ly}" width="{lw}" height="{lh}" style="fill:{p["ink"]};fill-opacity:0.55"/></g>')
        gx += 20
    # explicit margins for every edge and state: without them Plasma takes the corner pieces
    # (sized to keep the tick short) as the button's padding and the rail's slots grow to 82px
    hx = 700
    for prefix in EDGES:
        for state in states:
            across, along = TASK_MARGINS
            m = (dict(left=across, right=across, top=along, bottom=along) if prefix in ("west-", "east-")
                 else dict(top=across, bottom=across, left=along, right=along))
            out.append(hints(hx, 0, m, f"{prefix}{state}-"))
            hx += 20
    return f'<svg xmlns="{SVG}" width="{hx + 40}" height="{y}">{"".join(out)}</svg>'


def task_frame(prefix, state, side, wash, tick, ox, oy):
    # piece sizes for a bottom panel: corners CW wide, the bottom edge holds the tick
    CW, CH, E = 14, 6, 2
    wash_st = f"fill:{wash[0]};fill-opacity:{wash[1]}"
    rect = lambda x, y, w, h, st: f'<rect x="{x}" y="{y}" width="{w}" height="{h}" style="{st}"/>'
    blank = lambda w, h: rect(0, 0, w, h, "fill:#000;fill-opacity:0")
    ins = 3  # wash inset from the button edges
    # wider corners = shorter tick: on the rail's 48px slots, about 12px running, 28px focused
    cw = 18 if tick and tick[2] == "short" else 10
    pieces = {
        "topleft": (cw, CH, blank(cw, CH) + rect(ins, ins, cw - ins, CH - ins, wash_st)),
        "topright": (cw, CH, blank(cw, CH) + rect(0, ins, cw - ins, CH - ins, wash_st)),
        "bottomleft": (cw, CH, blank(cw, CH) + rect(ins, 0, cw - ins, CH - ins, wash_st)),
        "bottomright": (cw, CH, blank(cw, CH) + rect(0, 0, cw - ins, CH - ins, wash_st)),
        "top": (E, CH, blank(E, CH) + rect(0, ins, E, CH - ins, wash_st)),
        "bottom": (E, CH, blank(E, CH) + rect(0, 0, E, CH - ins, wash_st)),
        "left": (cw, E, blank(cw, E) + rect(ins, 0, cw - ins, E, wash_st)),
        "right": (cw, E, blank(cw, E) + rect(0, 0, cw - ins, E, wash_st)),
        "center": (E, E, rect(0, 0, E, E, wash_st)),
    }
    if tick:
        w, h, body = pieces["bottom"]
        pieces["bottom"] = (w, h, body + rect(0, h - 3, w, 3, f"fill:{tick[0]};fill-opacity:{tick[1]}"))
    flips = {"bottom": "", "top": "v", "right": "t", "left": "th"}[side]
    rename = {
        "v": {"top": "bottom", "bottom": "top", "topleft": "bottomleft", "bottomleft": "topleft",
              "topright": "bottomright", "bottomright": "topright"},
        "t": {"top": "left", "left": "top", "bottom": "right", "right": "bottom",
              "topright": "bottomleft", "bottomleft": "topright"},
        "h": {"left": "right", "right": "left", "topleft": "topright", "topright": "topleft",
              "bottomleft": "bottomright", "bottomright": "bottomleft"},
    }
    out, x = [], ox
    for name, (w, h, body) in pieces.items():
        for f in flips:
            name = rename[f].get(name, name)
        if "t" in flips:
            w, h = h, w
        t = f"translate({x},{oy})"
        t += {"": "", "v": f" translate(0,{h}) scale(1,-1)", "t": " matrix(0,1,1,0,0,0)",
              "th": f" translate({w},0) scale(-1,1) matrix(0,1,1,0,0,0)"}[flips]
        out.append(f'<g id="{prefix}{state}-{name}" transform="{t}">{body}</g>')
        x += max(w, h) + 4
    return "".join(out)


def tabbar(p, dst):
    """Breeze's tab bar with the accent line in ink (also the panel's open-popup mark)."""
    raw = gzip.decompress((BREEZE / "widgets/tabbar.svgz").read_bytes())
    register_namespaces(raw, dst.parent if dst.parent.exists() else ROOT)
    root = ET.fromstring(raw)
    for el in root.iter():
        if el.get("class") == "ColorScheme-ButtonFocus":
            del el.attrib["class"]
            st = el.get("style", "").replace("currentColor", p["ink"])
            el.set("style", st if p["ink"] in st else f"fill:{p['ink']};" + st)
    write(dst, ET.tostring(root, encoding="unicode"))


def build(sid, name, p, scheme):
    out = DEST / sid
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    panel = frame("", p["header"], 1, [(0, p["rule"], 1)], 500, 500) + \
        frame("mask-", "#000", 1, [], 540, 500) + hints(580, 500, 4)
    popup = frame("", p["window"], 1, [(0, p["ink"], 0.55), (3, p["rule"], 1)], 500, 500) + \
        frame("mask-", "#000", 1, [], 540, 500) + hints(580, 500, 9)
    tip = frame("", p["header"], 1, [(0, p["ink"], 0.4)], 500, 500) + \
        frame("mask-", "#000", 1, [], 540, 500) + hints(580, 500, 7)
    for variant in ("", "translucent/", "solid/"):
        for rel, extra in (("widgets/panel-background", panel), ("dialogs/background", popup),
                           ("widgets/tooltip", tip)):
            src = BREEZE / f"{variant}{rel}.svgz"
            if not src.exists():
                src = BREEZE / f"{rel}.svgz"
            restyle(src, out / f"{variant}{rel}.svgz", extra)
    write(out / "widgets/tasks.svgz", task_svg(p))
    tabbar(p, out / "widgets/tabbar.svgz")
    shutil.copy(BREEZE / "plasmarc", out / "plasmarc")
    with open(out / "plasmarc", "a") as f:
        f.write("\n[ContrastEffect]\nenabled=false\n")
    shutil.copy(ROOT / "home/.local/share/color-schemes" / f"{scheme}.colors", out / "colors")
    (out / "metadata.json").write_text(json.dumps({
        "KPlugin": {
            "Authors": [{"Name": "Claude, for Melih"}],
            "Description": "Pafta: the margin of a map sheet, legend boxes for popups",
            "Id": sid, "Name": name, "License": "LGPL", "Version": "1.0",
        },
        "X-Plasma-API": "5.0",
    }, indent=4) + "\n")


def main():
    build("pafta-paper", "Pafta Paper", PAL["paper"], "PaftaPaper")
    build("pafta-night", "Pafta Night", PAL["night"], "PaftaNight")
    print("built", DEST)
    if "--install" in sys.argv:
        target = Path.home() / ".local/share/plasma/desktoptheme"
        for sid in ("pafta-paper", "pafta-night"):
            if (target / sid).exists():
                shutil.rmtree(target / sid)
            shutil.copytree(DEST / sid, target / sid)
        shutil.rmtree(Path.home() / ".cache/ksvg-elements", ignore_errors=True)
        active = subprocess.run(["kreadconfig6", "--file", "plasmarc", "--group", "Theme", "--key", "name"],
                                capture_output=True, text=True).stdout.strip()
        if active.startswith("pafta"):
            subprocess.run(["plasma-apply-desktoptheme", "default"], stdout=subprocess.DEVNULL)
            subprocess.run(["plasma-apply-desktoptheme", active], stdout=subprocess.DEVNULL)
        print("installed")


if __name__ == "__main__":
    main()

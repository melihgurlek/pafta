# Pafta: design notes

The vision, rules and decisions behind this rice, written so a later session can keep designing in the same voice. Read it before changing anything visual.

## The idea

*Pafta* is Turkish for a map sheet: one numbered sheet of a national topographic survey. The desktop is such a sheet. Real terrain (Ağrı Dağı, Nemrut's caldera, Erciyes, the Bosphorus) is drawn as a shaded relief with contour lines, set in a printed frame with a graticule, minute bands and a title block.

The sheet comes as two fixed plates: paper by day, lit from the north-west as map makers light relief, and at night a chart, copper contours on slate. They're printed once; the desktop changes plate at sunrise and sunset with the colours. An earlier version reprinted the sheet every ten minutes under the real sun, which cost a render each time for a change you couldn't notice. What does move, the clock, the sun and moon, the weather, lives in the title-block widget. Nothing is a stock wallpaper: the elevation is the public SRTM model and every pixel is computed by `bin/pafta-print`.

Why this and not another dark rice: Ukiyo, the rice before this one, is a dark woodblock print. Pafta is light first, because Melih found the dark desktop gloomy by day and likes his white browser. It goes dark only when it's dark outside, the way a ship's chart display changes palette at dusk.

## Test every change against the plates

A printed topo map is made from a few plates, one ink each. Every colour in Pafta belongs to one of them (`palette.toml`):

| Plate | Day | Night | Used for |
|---|---|---|---|
| paper | `#F3F1EA` window, `#FBFAF6` view, `#EAE7DE` header | `#141A1F`, `#0F1418`, `#10151A` | surfaces |
| black | `#24282D` ink, `#5E6266`, `#8F918C` | `#C3C7C0`, `#8C9296`, `#5F676C` | type, frames, keylines |
| brown | `#9A6A42` | `#B08458` | contours, keywords, folders |
| blue | `#2F6690`, `#D4E3EA` | `#5B93BD`, `#23465F` | water, selection, links, focus |
| green / red / ochre | `#4F7A3A` `#B5452F` `#A87B1F` | lighter | vegetation, roads, warnings; strings, numbers, types |
| magenta overprint | `#A8336F` | `#CF6A9E` | rare: peaks on the map, the active window's tick, the cursor |

Rules:

- **Magenta is the overprint**, the "you are here" ink. It marks the one thing that is current: the active task on the rail, the summit triangles, the cursor. If it shows up on a surface, it's a mistake.
- **Square corners.** A map sheet, an inset and a legend box are rectangles. Windows, popups and the rail have no rounding.
- **Keylines, not shadows, separate things.** A window is a map inset: a 1px keyline and a narrow mat. A popup is a legend box: a keyline and a thin inner rule. Shadows stay soft and short.
- **Type is the survey's**: IBM Plex Sans for the UI, Plex Mono for coordinates and numbers, Plex Serif Italic for water (the cartographic convention), small caps letter-spaced for legend text. Map text is in Turkish: it is a Turkish survey sheet.

## Layout

- **One rail on the left, docked, 48px.** A 16:9 laptop has width to spare and height to save, so the panel stands up. It is the sheet's margin: flat header paper with one hairline where it meets the map. Top to bottom: the north arrow (launcher), pinned apps, a spacer, the tray, and the clock as hours over minutes.
- **Task ticks** sit on the screen edge like graticule ticks: a short ink tick for a running app, a long magenta one for the active app, ochre for attention, faint for minimised.
- **The legend widget** (`org.pafta.legend`) is the sheet's title block, live: sheet name (click for the next sheet, right-click for the previous), region and coordinates, a scale bar true to this 15.6" screen, the contour interval, the time, the sun or moon, and the weather (Open-Meteo). It sits in the corner the print leaves for it.
- **No tiling.** Windows float, as insets on the sheet.

## How the print is made (`bin/pafta-print`)

1. Elevation tiles (AWS Terrarium, zoom 12, about 30 m per pixel), cached in `~/.cache/pafta/dem`.
2. The sun and moon are computed locally (low-precision almanac formulas, no network). The light is the sun's when it is up, the moon's at night, and a faint fixed sky light otherwise.
3. **The light's path is mirrored to cross the top of the sheet.** A relief lit from the bottom of the screen reads inside out (valleys look like ridges), so a southern sun is reflected to the north: morning light comes from the right, noon from the top and evening from the left.
4. Shading: a soft sky light plus the key light with ray-marched cast shadows. Shadows are violet-blue and lit slopes warm (Imhof); both turn gold when the sun is low.
5. Water is found as perfectly flat ground (or ground below sea level) and drawn with the engraver's **water lines** along the shore.
6. Contours come from a generalised surface: thin every interval, heavy every index. Labels are knocked out of the map with a halo, as on a printed sheet.
7. The frame: a paper margin, outer and inner rules with minute bands between them, coordinates in the margin, and graticule crosses every five minutes.

## Day and night

Kigae's `[daynight]` switches the window colours, the Plasma style and the decoration at sunrise and sunset (two of each: paper and night). kitty, VS Code, Neovim and Claude Code follow the system's light/dark preference. The print follows the sun on its own: day, golden hour, blue hour, night.

## Decisions

- Two Plasma styles (and two decorations) instead of one that follows the colour scheme: Plasma's SVG colour classes have no role for an accent other than the selection colour, and the ticks need the overprint magenta.
- Kaçkar was dropped as a sheet: at any zoom it is a wall of ridges, too busy behind windows.
- The title block is a live widget rather than baked into the print, so the time is current and the sheet can be turned by clicking it. `pafta-print` without `--no-legend` still bakes it in, for a lock screen print.

# Pafta: design notes

The vision, rules and decisions behind this rice, written so a later session can keep designing in the same voice. Read it before changing anything visual.

## The idea

*Pafta* is Turkish for a map sheet. The desktop is one: a nautical chart of İstanbul, where the Bosphorus, the Golden Horn and the Marmara meet, set in a printed frame with a graticule, minute bands and a title block. It is İstanbul because Melih lives there; the mountain sheets of the first version (Ağrı, Nemrut, Erciyes) were well drawn but felt random to him, and were dropped.

The sheet comes as two fixed plates: paper by day and a night chart on slate. They're printed once; the desktop changes plate at sunrise and sunset with the colours. An earlier version reprinted the sheet every ten minutes under the real sun, which cost a render each time for a change you couldn't notice. What does move, the clock, the sun and moon, the weather, lives in the title-block widget. Nothing is a stock wallpaper: the elevation is the public SRTM model and every pixel is computed by `bin/pafta-print`.

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
- **Type is the survey's**: IBM Plex Sans for the UI, Plex Mono for coordinates and numbers, Plex Serif Italic for water (the cartographic convention), small caps letter-spaced for legend text. Place names stay Turkish (they are names); everything else, legend lines, days, months, units, is English. Melih asked for that; don't "restore" Turkish legend text for authenticity.
- **Subtract before adding.** When the sheet feels busy or generic, the fix has been to take a layer away (the street grid, the parks, the live reprint), not to add one (a skyline, landmarks, a star disc were all tried and rejected).

## Layout

- **One rail on the left, docked, 48px.** A 16:9 laptop has width to spare and height to save, so the panel stands up. It is the sheet's margin: flat header paper with one hairline where it meets the map. Top to bottom: the north arrow (launcher), pinned apps, a spacer, the tray, and the clock as hours over minutes.
- **Task ticks** sit on the screen edge like graticule ticks: a short ink tick for a running app, a long magenta one for the active app, ochre for attention, faint for minimised.
- **The legend widget** (`org.pafta.legend`) is the sheet's title block, live: sheet name, region and coordinates, a scale bar true to this 15.6" screen, what the numbers on the sheet mean, the time, the sun or moon, and the weather (Open-Meteo). It sits in the bottom-right corner, over land.
- **No tiling.** Windows float, as insets on the sheet.

## How the print is made (`bin/pafta-print`)

The chart style (İstanbul):

1. **Water is the subject.** The coast from OpenStreetMap water polygons (tiles cut the sea into pieces; ponds are dropped by their merged size, never piece by piece, or the shore gets square bites). Depths from EMODnet as five tint bands from shallow blue to deep paper, isobaths, a dark shore line. Soundings only in open water, 650 m from any shore (EMODnet's 115 m cells average the narrows into their banks).
2. **Land the way charts draw it, not web maps.** Flat paper; the town as one quiet tint where the street network is dense (streets are used only to find the town, never drawn); 50 m contours in the brown plate, heavier every 100 m, from the SRTM surface; spot heights on the highest hilltops; only motorways as a hairline. No parks, no street grid: those are what made it read as Google Maps. A breath of relief (7%).
3. **The marks**, on a 2x overlay: ferry routes dashed, bridges as cased lines, lights with magenta flares, conspicuous objects as ⊙, the compass rose a shade under the ink. Water names in Plex Serif Italic, lettered along a strait when the sheet gives an `angle`.
4. **The frame**: a paper margin, outer and inner rules with a minute band a tone under the ink between them, longitudes in the margin, latitudes inside the neatline, graticule crosses every five minutes.

The topographic style (any mountain sheet added to `sheets/`) is still there: shaded relief with cast shadows, Imhof colours, contours, water lines. Its light's path is mirrored to cross the top of the sheet, because relief lit from the bottom of the screen reads inside out.

## Day and night

Kigae's `[daynight]` switches the window colours, the Plasma style, the decoration, the wallpaper plate and the lock screen image at sunrise and sunset (two of each: paper and night); its hook points the fastfetch inset at the matching plate. kitty, VS Code, Neovim and Claude Code follow the system's light/dark preference. The plates are static: the earlier live reprint every 10 minutes cost hundreds of MB per render for a change nobody noticed.

## Decisions

- Two Plasma styles (and two decorations) instead of one that follows the colour scheme: Plasma's SVG colour classes have no role for an accent other than the selection colour, and the ticks need the overprint magenta.
- Kaçkar was dropped as a sheet: at any zoom it is a wall of ridges, too busy behind windows. Later the whole atlas went: İstanbul is the sheet.
- A star chart (the sky over İstanbul, and as a star-finder disc on the chart) was built and shelved on branch `sky-test`: beautiful, but it competed with the chart and its point, being live, didn't survive going static.
- The title block is a live widget rather than baked into the print, so the time and the weather are current. `pafta-print` without `--no-legend` still bakes it in, for a lock screen print.

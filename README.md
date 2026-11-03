# Pafta

*Pafta* is Turkish for a map sheet. This KDE Plasma 6 rice turns the desktop into one: a nautical chart of İstanbul, where the Bosphorus, the Golden Horn and the Marmara meet, printed on paper by day and as a night chart after dark. The prints are fixed plates, made once; what moves (the time, the sun and moon, the weather) is in the title-block widget.

![the paper plate](docs/desktop.jpg)

![the night plate](docs/night.jpg)

## What's in it

- **The print** (`bin/pafta-print`): the water is the subject, drawn the way a harbour chart draws it: EMODnet depth bands and isobaths, soundings in open water, ferry routes, lights with magenta flares, conspicuous objects and a compass rose. The land is drawn the way charts draw land, not the way web maps do: flat paper, the town as one tint (generalised from street density), 50 m contours in the brown plate from the SRTM elevation model, spot heights, and only the motorways. A graticule frame with minute bands holds it. `pafta-sun prints` makes the paper and night plates of the current sheet once (again only when the sheet or the renderer changes); Kigae puts up the one for the hour at sunrise and sunset, and the timer only refreshes the widgets' almanac.
- **The sheet** (`sheets/istanbul.toml`): a small TOML file with the centre, zoom, labels, lights, landmarks and the rose. The renderer still draws mountain sheets (shaded relief, contours, cast shadows) if you add one; `pafta-sun sheet <id>` puts it up.
- **Rail**: one docked 48px panel on the left, the sheet's margin. It holds a north-arrow launcher, apps with graticule ticks (magenta for the active one), the tray, and `org.pafta.railclock` (hours over minutes, plus a calendar with sunrise and sunset).
- **Legend** (`org.pafta.legend`): the sheet's title block as a live widget. It shows the name, coordinates, a scale bar true to a 15.6" screen, the time, the sun or moon, and the weather (Open-Meteo).
- **Plasma styles** `pafta-paper` and `pafta-night`: square legend-box popups with a keyline and an inner rule.
- **Window decoration** `PaftaPaper` / `PaftaNight` (Aurorae): square map insets, a 1px keyline, flush-left titles, thin glyph buttons.
- **Colour schemes** `PaftaPaper` / `PaftaNight`, generated from `palette.toml`. Every colour is a printing plate.
- **Apps**: kitty, Konsole, Kate/KWrite, VS Code (`apps/vscode/pafta-theme`), Neovim (`~/.config/pafta/nvim`), and a p10k prompt. All switch between paper and night.
- **Type**: IBM Plex Sans, Plex Mono, Plex Serif Italic (water names), BlexMono Nerd Font in the terminal.

- **Lock screen** (`plasma/lockscreen/org.pafta.lockscreen`): the desktop's legend box plus a password field, over the print with even margins. Picked through `plasmashellrc [Shell] ShellPackage`; a plasmashell drop-in names the desktop shell explicitly so plasmashell never loads the lock package, and the package falls back to `org.kde.plasma.desktop` regardless. `pafta-sun` writes the box's sheet details to `kscreenlockerrc`, and the lock image follows the paper or night plate.
- **Login** (`sddm/`): the same box over the paper or night plate, chosen by the sun at login. `sddm/build.sh && pkexec sddm/install-sddm-theme.sh`; undo with `pkexec sddm/revert-sddm-theme.sh`; try it first with `sddm/preview.sh`.

Design notes and rules are in [DESIGN.md](DESIGN.md).

## Install

Needs KDE Plasma 6 (Wayland), [uv](https://docs.astral.sh/uv/) (the renderer is a uv script with numpy, scipy and pillow), jq, a network connection the first time (elevation, map and depth data are downloaded once and cached), and these fonts in `~/.local/share/fonts/pafta`: [IBM Plex](https://github.com/IBM/plex/releases) Sans, Mono and Serif, and BlexMono from [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/releases). Icons: [Tela-circle](https://github.com/vinceliuice/Tela-circle-icon-theme) in the contour brown: `./install.sh 9A6A42` (not `-c`, which makes the folders circular).

With [Kigae](https://github.com/melihgurlek/Kigae) (live rice switching):

```sh
ln -s ~/Code/Rice ~/.config/kigae/manifests/pafta
ln -s ~/Code/Rice/kigae/pafta.toml ~/.config/kigae/manifests/pafta.toml
kigae install pafta && kigae apply pafta
kigae deep pafta      # the login screen too (one password prompt; needs sddm/ installed first)
```

Without it: `./install.sh` copies everything, prints the plates and applies the day look with its wallpaper and lock screen (`--night` for the night one; without Kigae it doesn't follow the sun). `./install.sh --panels` also replaces your panels and desktop widgets with the rail and the legend (it does not save your old layout). If the lock screen ever fails to load: Ctrl+Alt+F3, log in, `loginctl unlock-session`.

Settings live in `~/.config/pafta/pafta.toml`, and all of them are optional:

```toml
lat = 41.01            # where the sun is computed for (default Istanbul)
lon = 28.98
screen_inches = 15.6   # for the true scale bar
size = "1920x1080"
rail = 48              # the print leaves this much margin on the left for the panel
sheet = "istanbul"     # the first sheet; `pafta-sun sheet <id>` changes it after that
```

`pafta-print --plate night --out night.png` prints a plate; `pafta-print --at 2026-11-03T17:40 --out dusk.png` prints the sheet under the sun of any moment.

## Credits

Elevation: SRTM via the [AWS Terrain Tiles](https://registry.opendata.aws/terrain-tiles/) open dataset. Coast, streets (for the built-up tint), motorways, bridges and ferries: © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors, served as vector tiles by [OpenFreeMap](https://openfreemap.org). Depths: [EMODnet Bathymetry](https://emodnet.ec.europa.eu/en/bathymetry). Weather: [Open-Meteo](https://open-meteo.com). Fonts: IBM Plex (OFL).

Designed and built by Claude for Melih Gürlek.

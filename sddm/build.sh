#!/usr/bin/env bash
# Assemble the Pafta SDDM theme in sddm/build/pafta: the QML from sddm/pafta, four prints of the
# current sheet (dawn, day, dusk, night: the greeter picks one by where the sun is) and the Plex
# fonts (the sddm user can't see ~/.local/share/fonts). Nothing outside the repo changes.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
out=build/pafta
rm -rf "$out" && mkdir -p "$out/prints" "$out/fonts"
cp pafta/* "$out/"
print=../bin/pafta-print
state=$(mktemp)
scratch=$(mktemp -d)
"$print" --no-legend --state "$state" --out "$scratch/desk.jpg" --lock-out "$out/prints/day.jpg" --at "$(date +%F)T12:40" 2>/dev/null >/dev/null
rise=$(jq -r .sun.rise "$state"); set_=$(jq -r .sun.set "$state")
at() { date -d "@$(( $(date -d "$(date +%F) $1" +%s) + $2 * 60 ))" +%FT%H:%M; }
"$print" --no-legend --out "$scratch/desk.jpg" --lock-out "$out/prints/dawn.jpg" --at "$(at "$rise" 25)" 2>/dev/null >/dev/null
"$print" --no-legend --out "$scratch/desk.jpg" --lock-out "$out/prints/dusk.jpg" --at "$(at "$set_" -15)" 2>/dev/null >/dev/null
"$print" --no-legend --out "$scratch/desk.jpg" --lock-out "$out/prints/night.jpg" --at "$(date +%F)T23:30" 2>/dev/null >/dev/null
# what the legend box says about the sheet
{
    echo "[General]"
    jq -r '"sheetName=\(.name)\nsheetRegion=\(.region)\nsheetCoords=\(.coords)\nsheetScale=\(.scale)\npxPerKm=\(.px_per_km)\ncontour=\(.contour)\nsegPx=\(.seg_px)\nbarKm=\(.bar_km)\nnote=\(.note)\nlat=\(.home.lat)\nlon=\(.home.lon)"' "$state"
    echo "demo=false"
} > "$out/theme.conf"
rm -rf "$state" "$scratch"
f=$HOME/.local/share/fonts/pafta
cp "$f"/IBMPlexSans-{Light,Regular,Medium,SemiBold}.otf "$f"/IBMPlexMono-Regular.otf "$out/fonts/"
echo "$out"

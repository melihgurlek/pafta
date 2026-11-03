#!/usr/bin/env bash
# Assemble the Pafta SDDM theme in sddm/build/pafta: the QML from sddm/pafta, the sheet's paper
# and night plates (the greeter picks one by where the sun is) and the Plex fonts (the sddm user
# can't see ~/.local/share/fonts). Nothing outside the repo changes.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
out=build/pafta
rm -rf "$out" && mkdir -p "$out/prints" "$out/fonts"
cp pafta/* "$out/"
print=../bin/pafta-print
plates=${XDG_DATA_HOME:-$HOME/.local/share}/pafta/prints
state=$(mktemp)
"$print" --state-only --state "$state" >/dev/null || [[ $? == 3 ]]
for p in paper night; do  # the even-margin prints pafta-sun made for the lock screen, or fresh ones
    if [[ -f $plates/lock-$p.jpg ]]; then
        cp -L "$plates/lock-$p.jpg" "$out/prints/$p.jpg"
    else
        scratch=$(mktemp -d)
        "$print" --plate "$p" --no-legend --out "$scratch/desk.jpg" --lock-out "$out/prints/$p.jpg" >/dev/null
        rm -rf "$scratch"
    fi
done
# what the legend box says about the sheet
{
    echo "[General]"
    jq -r '"sheetName=\(.name)\nsheetRegion=\(.region)\nsheetCoords=\(.coords)\nsheetScale=\(.scale)\npxPerKm=\(.px_per_km)\ncontour=\(.contour)\nsegPx=\(.seg_px)\nbarKm=\(.bar_km)\nnote=\(.note)\nlat=\(.home.lat)\nlon=\(.home.lon)"' "$state"
    echo "demo=false"
} > "$out/theme.conf"
rm -f "$state"
f=$HOME/.local/share/fonts/pafta
cp "$f"/IBMPlexSans-{Light,Regular,Medium,SemiBold}.otf "$f"/IBMPlexMono-Regular.otf "$out/fonts/"
echo "$out"

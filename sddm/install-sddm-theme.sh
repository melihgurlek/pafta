#!/usr/bin/env bash
# Install the Pafta login: build it as yourself, then install it as root.
#   ~/Code/Rice/sddm/build.sh && pkexec ~/Code/Rice/sddm/install-sddm-theme.sh
# Copies sddm/build/pafta to /usr/share/sddm/themes/pafta and changes only [Theme] Current in
# /etc/sddm.conf (backup: /etc/sddm.conf.pre-pafta). Undo: revert-sddm-theme.sh
# Re-run both to refresh the prints (they are made for the sheet and season of the build).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with pkexec"; exit 1; }
src=$(dirname "$(readlink -f "$0")")/build/pafta
dst=/usr/share/sddm/themes/pafta
conf=/etc/sddm.conf
for f in Main.qml metadata.desktop theme.conf prints/dawn.jpg prints/day.jpg prints/dusk.jpg prints/night.jpg \
         fonts/IBMPlexSans-Regular.otf fonts/IBMPlexMono-Regular.otf; do
  [[ -f $src/$f ]] || { echo "missing $f (run build.sh first), nothing changed"; exit 1; }
done
grep -q '^[[:space:]]*Current=' "$conf" || { echo "no Current= line in $conf, nothing changed"; exit 1; }
[[ -f $conf.pre-pafta ]] || cp -a "$conf" "$conf.pre-pafta"
rm -rf "$dst"
mkdir -p "$dst"
cp -r --no-preserve=all "$src/." "$dst/"
sed -i 's/^demo=.*/demo=false/; /^phase=/d' "$dst/theme.conf"
chmod -R a+rX "$dst"
command -v restorecon >/dev/null && restorecon -R "$dst"
sed -i 's/^\([[:space:]]*\)Current=.*/\1Current=pafta/' "$conf"
echo "installed: $(grep -m1 'Current=' "$conf" | tr -d ' ')"
echo "it shows at the next login. If it ever fails: Ctrl+Alt+F3, log in, run"
echo "  sudo $(dirname "$(readlink -f "$0")")/revert-sddm-theme.sh"

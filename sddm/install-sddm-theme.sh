#!/usr/bin/env bash
# Install the Pafta login: build it as yourself, then install it as root.
#   ~/Code/Rice/sddm/build.sh && pkexec ~/Code/Rice/sddm/install-sddm-theme.sh
# Copies sddm/build/pafta to /usr/share/sddm/themes/pafta and sets [Theme] Current: in
# /etc/sddm.conf when it has a Current= line (backup: /etc/sddm.conf.pre-pafta), otherwise in a
# file of its own, /etc/sddm.conf.d/zz-pafta.conf (stock Fedora). Undo: revert-sddm-theme.sh
# Re-run both to refresh the prints after the sheet changes.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with pkexec"; exit 1; }
src=$(dirname "$(readlink -f "$0")")/build/pafta
dst=/usr/share/sddm/themes/pafta
conf=/etc/sddm.conf
for f in Main.qml metadata.desktop theme.conf prints/paper.jpg prints/night.jpg \
         fonts/IBMPlexSans-Regular.otf fonts/IBMPlexMono-Regular.otf; do
  [[ -f $src/$f ]] || { echo "missing $f (run build.sh first), nothing changed"; exit 1; }
done
rm -rf "$dst"
mkdir -p "$dst"
cp -r --no-preserve=all "$src/." "$dst/"
sed -i 's/^demo=.*/demo=false/; /^phase=/d' "$dst/theme.conf"
chmod -R a+rX "$dst"
command -v restorecon >/dev/null && restorecon -R "$dst"
if [[ -f $conf ]] && grep -q '^[[:space:]]*Current=' "$conf"; then
  [[ -f $conf.pre-pafta ]] || cp -a "$conf" "$conf.pre-pafta"
  sed -i 's/^\([[:space:]]*\)Current=.*/\1Current=pafta/' "$conf"
  echo "installed: $(grep -m1 'Current=' "$conf" | tr -d ' ') in $conf"
else
  mkdir -p /etc/sddm.conf.d
  printf '[Theme]\nCurrent=pafta\n' > /etc/sddm.conf.d/zz-pafta.conf
  echo "installed: Current=pafta in /etc/sddm.conf.d/zz-pafta.conf"
fi
echo "it shows at the next login. If it ever fails: Ctrl+Alt+F3, log in, run"
echo "  sudo $(dirname "$(readlink -f "$0")")/revert-sddm-theme.sh"

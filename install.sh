#!/usr/bin/env bash
# Install Pafta without Kigae: copy the assets into $HOME, start the print timer and apply the
# day look. With --panels it also replaces your panels and desktop widgets with Pafta's rail
# and legend (your current layout is not saved: back it up first if you care about it).
#
#   ./install.sh [--panels] [--night]
#
# Needs: KDE Plasma 6, uv (the renderer is a uv script), kitty for the terminal theme,
# IBM Plex Sans/Mono/Serif and BlexMono Nerd Font (see README).
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
panels=0; look=paper
for a in "$@"; do
    case $a in
        --panels) panels=1 ;;
        --night) look=night ;;
        *) sed -n '2,10p' "$0"; exit 1 ;;
    esac
done

echo "· building generated themes"
python3 -I plasma/colors.py >/dev/null
python3 -I plasma/desktoptheme/build.py >/dev/null
python3 -I plasma/aurorae/build.py >/dev/null

echo "· copying files"
cp -r home/. "$HOME/"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/pafta" "$HOME/.local/share/plasma/plasmoids"
install -m755 bin/pafta-print bin/pafta-sun "$HOME/.local/bin/"
rm -rf "$HOME/.local/share/pafta/sheets" && cp -r sheets "$HOME/.local/share/pafta/sheets"
for p in plasma/plasmoids/*; do
    rm -rf "$HOME/.local/share/plasma/plasmoids/${p##*/}" && cp -r "$p" "$HOME/.local/share/plasma/plasmoids/"
done

echo "· applying the $look look"
if [[ $look == paper ]]; then scheme=PaftaPaper style=pafta-paper deco=PaftaPaper; else scheme=PaftaNight style=pafta-night deco=PaftaNight; fi
plasma-apply-colorscheme "$scheme" >/dev/null
plasma-apply-desktoptheme "$style" >/dev/null
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__$deco"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight IAX
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
qdbus-qt6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

if (( panels )); then
    echo "· replacing panels with the rail"
    shim='var kigae = { launchers: "applications:org.kde.dolphin.desktop,applications:kitty.desktop,applications:code.desktop,applications:firefox.desktop",
        tray: function (t, cfg) { for (var g in cfg) { t.currentConfigGroup = [g]; for (var k in cfg[g]) t.writeConfig(k, cfg[g][k]); } },
        desktop: function (type, x, y, w, h) { desktops()[0].addWidget(type, x, y, w, h); } };
    panels().forEach(function (p) { p.remove(); });
    desktops().forEach(function (d) { d.widgets().forEach(function (w) { w.remove(); }); });'
    qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$shim $(cat plasma/layout.js)" >/dev/null
fi

echo "· starting the print timer"
systemctl --user daemon-reload
systemctl --user enable --now pafta-sun.timer >/dev/null
"$HOME/.local/bin/pafta-sun"
echo "done. Terminal: add 'include pafta.conf' to kitty.conf and link dark-theme.auto.conf /"
echo "light-theme.auto.conf to pafta-night.conf / pafta-paper.conf."

#!/usr/bin/env bash
# Put the login back as it was before Pafta: pkexec ~/Code/Rice/sddm/revert-sddm-theme.sh
# Removes /etc/sddm.conf.d/zz-pafta.conf, or restores [Theme] Current from /etc/sddm.conf.pre-pafta;
# the theme folder stays (harmless).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with pkexec"; exit 1; }
conf=/etc/sddm.conf
if [[ -f /etc/sddm.conf.d/zz-pafta.conf ]]; then
  rm /etc/sddm.conf.d/zz-pafta.conf
  echo "removed /etc/sddm.conf.d/zz-pafta.conf"
  exit 0
fi
[[ -f $conf.pre-pafta ]] || { echo "no $conf.pre-pafta, nothing to revert"; exit 1; }
before=$(grep -m1 '^[[:space:]]*Current=' "$conf.pre-pafta" | sed 's/.*Current=//')
sed -i "s/^\([[:space:]]*\)Current=.*/\1Current=$before/" "$conf"
echo "login theme back to: $before"

#!/usr/bin/env bash
# Preview the Pafta login in SDDM's test mode (a window; nothing in /etc changes).
# Demo mode: any password + Enter plays the login, an empty one plays the misregistration.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
dir=$(./build.sh)
sed -i 's/^demo=false/demo=true/' "$dir/theme.conf"
sddm-greeter-qt6 --test-mode --theme "$PWD/$dir"

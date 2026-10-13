#!/bin/bash
set -Eeuo pipefail
QUEUE="HP_LaserJet_1020"
BUNDLE="/Library/Printers/hp/laserjet/hplaserjetzjs.bundle"
PPD="/Library/Printers/PPDs/Contents/Resources/HP LaserJet 1022.ppd"
STATE="/var/db/hp-laserjet-1020-macos"
MARKER="$STATE/installed-by-project"

[[ "$(uname -s)" == Darwin ]] || { echo "macOS only." >&2; exit 1; }
if [[ $EUID -ne 0 ]]; then exec sudo "$0" "$@"; fi
[[ -f "$MARKER" ]] || { echo "Project marker not found; refusing to remove unverified files."; exit 1; }
echo "Remove queue '$QUEUE' and this project's installed bundle and PPD?"
printf "Type yes to continue: "; read -r answer
[[ "$answer" == yes ]] || { echo "Cancelled."; exit 0; }
if /usr/sbin/lpstat -p "$QUEUE" >/dev/null 2>&1; then /usr/sbin/lpadmin -x "$QUEUE"; fi
/bin/rm -rf "$BUNDLE"
/bin/rm -f "$PPD" "$MARKER"
rmdir "$STATE" 2>/dev/null || true
echo "Uninstall complete. Rosetta and unrelated files were not removed."

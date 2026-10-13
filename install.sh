#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

QUEUE="HP_LaserJet_1020"
DMG_NAME="HewlettPackardPrinterDrivers.dmg"
BUNDLE_REL="Library/Printers/hp/laserjet/hplaserjetzjs.bundle"
PPD_GZ_REL="Library/Printers/PPDs/Contents/Resources/HP LaserJet 1022.gz"
BUNDLE_DEST="/Library/Printers/hp/laserjet/hplaserjetzjs.bundle"
PPD_DEST="/Library/Printers/PPDs/Contents/Resources/HP LaserJet 1022.ppd"
STATE_DIR="/var/db/hp-laserjet-1020-macos"
MARKER="$STATE_DIR/installed-by-project"
DRY=0; CHECK=0; TMP=""; MOUNTED=0

usage() { echo "Usage: ./install.sh [--check|--dry-run]"; }
die() { echo "[hp1020] ERROR: $*" >&2; exit 1; }
log() { echo "[hp1020] $*"; }

for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $arg" ;;
  esac
done

if [[ $EUID -ne 0 && $CHECK -eq 0 && $DRY -eq 0 ]]; then exec sudo "$0" "$@"; fi
if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]]; then
  USER_HOME="$(/usr/bin/dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}')"
else
  USER_HOME="$HOME"
fi
[[ -d "$USER_HOME" ]] || die "Could not determine user's home directory."
DMG="$USER_HOME/Downloads/$DMG_NAME"

cleanup() {
  if [[ $MOUNTED -eq 1 && -n "$TMP" ]]; then /usr/bin/hdiutil detach "$TMP/mount" -quiet >/dev/null 2>&1 || true; fi
  [[ -z "$TMP" || ! -d "$TMP" ]] || /bin/rm -rf "$TMP"
}
trap cleanup EXIT

[[ "$(uname -s)" == Darwin ]] || die "macOS only."
for cmd in /usr/bin/hdiutil /usr/sbin/pkgutil /usr/bin/cupstestppd /usr/sbin/lpadmin /usr/sbin/lpinfo /usr/bin/cpio /usr/bin/gzip /usr/bin/ditto; do
  [[ -x "$cmd" ]] || die "Required tool missing: $cmd"
done
[[ -f "$DMG" ]] || die "Place $DMG_NAME in $USER_HOME/Downloads first."
log "macOS $(/usr/bin/sw_vers -productVersion), architecture $(uname -m)"
log "Driver DMG found: $DMG"
if [[ $CHECK -eq 1 ]]; then log "Preflight passed; no changes made."; exit 0; fi
if [[ $DRY -eq 1 ]]; then log "Dry run passed; would extract, patch, validate, install, detect USB, and create queue $QUEUE. No changes made."; exit 0; fi

[[ ! -e "$BUNDLE_DEST" ]] || die "Bundle already exists at $BUNDLE_DEST; refusing to overwrite."
[[ ! -e "$PPD_DEST" ]] || die "PPD already exists at $PPD_DEST; refusing to overwrite."
[[ ! -e "$MARKER" ]] || die "Project marker already exists; inspect current installation."

TMP="$(/usr/bin/mktemp -d /tmp/hp1020.XXXXXX)"
/bin/mkdir -p "$TMP/mount" "$TMP/expanded" "$TMP/extracted"
/usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$TMP/mount" "$DMG" >/dev/null
MOUNTED=1
OUTER="$(/usr/bin/find "$TMP/mount" -maxdepth 3 -name HewlettPackardPrinterDrivers.pkg -print -quit)"
[[ -n "$OUTER" && -d "$OUTER" ]] || die "Could not find HewlettPackardPrinterDrivers.pkg in DMG."
/usr/sbin/pkgutil --expand "$OUTER" "$TMP/expanded"
PAYLOAD="$(/usr/bin/find "$TMP/expanded" -path '*/HewlettPackardPrinterDrivers.pkg/Payload' -type f -print -quit)"
[[ -n "$PAYLOAD" ]] || PAYLOAD="$(/usr/bin/find "$TMP/expanded" -name Payload -type f -print -quit)"
[[ -n "$PAYLOAD" ]] || die "Could not find package Payload."

/usr/bin/gzip -dc "$PAYLOAD" | (cd "$TMP/extracted" && /usr/bin/cpio -id "./Library/Printers/hp/laserjet/hplaserjetzjs.bundle*" "./Library/Printers/PPDs/Contents/Resources/HP LaserJet 1022.gz")
STAGED_BUNDLE="$TMP/extracted/$BUNDLE_REL"
STAGED_GZ="$TMP/extracted/$PPD_GZ_REL"
[[ -x "$STAGED_BUNDLE/Contents/MacOS/rasterToHPZJS" ]] || die "rasterToHPZJS missing."
[[ -x "$STAGED_BUNDLE/Contents/MacOS/commandToHPZJS" ]] || die "commandToHPZJS missing."
[[ -f "$STAGED_BUNDLE/Contents/Resources/HP LaserJet 1022.icns" ]] || die "Printer icon missing."
[[ -f "$STAGED_GZ" ]] || die "PPD missing."

/usr/bin/gzip -dc "$STAGED_GZ" > "$TMP/original.ppd"
/usr/bin/sed \
  -e 's/^\*CloseUI: \*JamRecovery$/\*JCLCloseUI: *JamRecovery/' \
  -e 's/^\*CloseUI: \*PrintDensity$/\*JCLCloseUI: *PrintDensity/' \
  "$TMP/original.ppd" > "$TMP/corrected.ppd"

/bin/mkdir -p /Library/Printers/hp/laserjet /Library/Printers/PPDs/Contents/Resources
/usr/bin/ditto "$STAGED_BUNDLE" "$BUNDLE_DEST"
/usr/sbin/chown -R root:wheel "$BUNDLE_DEST"
/bin/chmod 755 "$BUNDLE_DEST/Contents/MacOS/rasterToHPZJS" "$BUNDLE_DEST/Contents/MacOS/commandToHPZJS"
/bin/chmod 644 "$BUNDLE_DEST/Contents/Resources/HP LaserJet 1022.icns"

if ! /usr/bin/cupstestppd "$TMP/corrected.ppd"; then
  /bin/rm -rf "$BUNDLE_DEST"
  die "PPD validation failed; bundle removed and no queue created."
fi
/usr/bin/install -o root -g wheel -m 644 "$TMP/corrected.ppd" "$PPD_DEST"

URIS="$(/usr/sbin/lpinfo -v | /usr/bin/awk '$1=="direct" && $2 ~ /^usb:\/\/Hewlett-Packard\/HP%20LaserJet%20102[02]/ { $1=""; sub(/^ /,""); print }')"
if [[ -z "$URIS" ]]; then
  /bin/rm -f "$PPD_DEST"; /bin/rm -rf "$BUNDLE_DEST"
  die "No matching USB printer detected. Connect it and rerun."
fi
COUNT="$(printf '%s\n' "$URIS" | /usr/bin/awk 'NF{n++} END{print n+0}')"
if [[ "$COUNT" -eq 1 ]]; then
  URI="$URIS"
else
  log "Multiple matching USB printers found:"
  printf '%s\n' "$URIS" | /usr/bin/nl -ba
  printf "Choose a number: "; read -r n
  [[ "$n" =~ ^[0-9]+$ ]] || die "Invalid selection."
  URI="$(printf '%s\n' "$URIS" | /usr/bin/sed -n "${n}p")"
  [[ -n "$URI" ]] || die "Invalid selection."
fi

if /usr/sbin/lpstat -p "$QUEUE" >/dev/null 2>&1; then
  /bin/rm -f "$PPD_DEST"; /bin/rm -rf "$BUNDLE_DEST"
  die "Queue $QUEUE already exists; refusing to replace it."
fi
if ! /usr/sbin/lpadmin -p "$QUEUE" -E -v "$URI" -P "$PPD_DEST"; then
  /bin/rm -f "$PPD_DEST"; /bin/rm -rf "$BUNDLE_DEST"
  die "lpadmin failed; driver files removed."
fi
/bin/mkdir -p "$STATE_DIR"
/usr/bin/touch "$MARKER"
/usr/sbin/chown root:wheel "$STATE_DIR" "$MARKER"
/bin/chmod 755 "$STATE_DIR"; /bin/chmod 644 "$MARKER"
log "Installed. Verify: lpstat -p $QUEUE -l"
log "Test print: printf 'HP LaserJet 1020 test print\\n' | lp -d $QUEUE"

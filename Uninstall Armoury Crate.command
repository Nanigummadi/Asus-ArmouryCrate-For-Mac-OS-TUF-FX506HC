#!/bin/bash
# Armoury Crate for ASUS TUF Gaming F15 FX506HC — userspace uninstaller.
# OpenCore files (RogControl.kext, SSDT-FX506HC.aml) are deliberately left alone.
set -euo pipefail

ASSUME_YES=0
KEEP_SETTINGS=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --keep-settings) KEEP_SETTINGS=1 ;;
        -h|--help)
            echo "Usage: Uninstall Armoury Crate.command [--yes] [--keep-settings]"
            echo "  --yes            do not ask for confirmation"
            echo "  --keep-settings  keep config.json, state.json and rogd.log"
            exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Armoury Crate needs administrator access to remove its helper and daemon."
    echo "You will be asked for your macOS password."
    echo
    exec sudo -- "$0" "$@"
fi

fail() { echo "ERROR: $*" >&2; exit 1; }
ok()   { echo "  [ OK ] $*"; }
warn() { echo "  [WARN] $*"; }

confirm() {
    (( ASSUME_YES )) && return 0
    local reply=""
    read -r -p "$1 [y/N] " reply || true
    [[ "$reply" =~ ^[Yy]$ ]]
}

APP="/Applications/Armoury Crate.app"
HELPER="/usr/local/libexec/armouryctl"
BOOST_HELPER="/usr/local/libexec/ArmouryBoost"
BOOST_LABEL="com.pengubow.armouryboost"
DAEMON_PLIST="/Library/LaunchDaemons/com.pengubow.rogd.plist"
SUDOERS="/etc/sudoers.d/armouryctl"
DATA_DIR="/Library/Application Support/RogControl"
LOG="/Library/Logs/rogd.log"

CONSOLE_USER="$(stat -f %Su /dev/console 2>/dev/null || true)"
if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" || "$CONSOLE_USER" == "loginwindow" ]]; then
    CONSOLE_USER="${SUDO_USER:-}"
fi
CONSOLE_UID=0
if [[ -n "$CONSOLE_USER" && "$CONSOLE_USER" != "root" ]]; then
    CONSOLE_UID="$(id -u "$CONSOLE_USER" 2>/dev/null || echo 0)"
fi
CONSOLE_HOME=""
if [[ "$CONSOLE_UID" -ne 0 ]]; then
    CONSOLE_HOME="$(dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
fi

echo "============================================================"
echo " Armoury Crate — uninstall"
echo "============================================================"
echo
echo "This removes:"
echo "  • $APP"
echo "  • $HELPER and the sudoers rule"
echo "  • $BOOST_HELPER and its login agent"
echo "  • rogd, rogctl, tufrgb and the rogd LaunchDaemon"
if (( KEEP_SETTINGS )); then
    echo "  • settings, state and logs will be KEPT"
else
    echo "  • $DATA_DIR (settings and state)"
    echo "  • $LOG"
fi
echo
echo "This does NOT remove RogControl.kext or SSDT-FX506HC.aml from your EFI."
echo "Remove those from OpenCore config.plist and EFI/OC yourself, then reboot."
echo

confirm "Uninstall Armoury Crate?" || { echo "Cancelled."; exit 0; }

# Quit the app and daemon first.
if [[ "$CONSOLE_UID" -ne 0 ]]; then
    pkill -u "$CONSOLE_USER" -x ArmouryCrate 2>/dev/null || true
    for _ in 1 2 3 4 5 6; do
        pgrep -u "$CONSOLE_USER" -x ArmouryCrate >/dev/null 2>&1 || break
        sleep 0.4
    done
    launchctl bootout "gui/$CONSOLE_UID/$BOOST_LABEL" >/dev/null 2>&1 || true
    pkill -u "$CONSOLE_USER" -x ArmouryBoost 2>/dev/null || true
fi

launchctl bootout system/com.pengubow.rogd >/dev/null 2>&1 || true
for _ in 1 2 3 4 5 6 7 8; do
    launchctl print system/com.pengubow.rogd >/dev/null 2>&1 || break
    sleep 0.25
done
pkill -x rogd 2>/dev/null || true
ok "Stopped the app and rogd"

rm -f "$DAEMON_PLIST" "$SUDOERS" "$HELPER" "$BOOST_HELPER" \
      /usr/local/bin/rogd /usr/local/bin/rogctl /usr/local/bin/tufrgb \
      /var/run/rogd.pid
rm -rf "$APP"
if [[ -n "$CONSOLE_HOME" ]]; then
    rm -f "$CONSOLE_HOME/Library/LaunchAgents/$BOOST_LABEL.plist"
    rm -rf "$CONSOLE_HOME/Library/Application Support/ArmouryBoost"
fi
ok "Removed the app, helpers, command line tools and daemon"

# Remove the per-user launch agent and preferences for the desktop user.
for home in /Users/*; do
    [[ -d "$home" ]] || continue
    for label in com.pengubow.armourycrate.plist "$BOOST_LABEL.plist"; do
        agent="$home/Library/LaunchAgents/$label"
        [[ -f "$agent" ]] && rm -f "$agent"
    done
done
if [[ "$CONSOLE_UID" -ne 0 ]]; then
    sudo -u "$CONSOLE_USER" defaults delete com.pengubow.ArmouryCrate >/dev/null 2>&1 || true
fi
ok "Removed login items and app preferences"

if (( KEEP_SETTINGS )); then
    echo "  [INFO] Kept $DATA_DIR and $LOG"
else
    rm -rf "$DATA_DIR"
    rm -f "$LOG"
    ok "Removed settings, state and logs"
fi

echo
echo "Uninstallation complete."
echo
echo "The OpenCore pieces are still present:"
echo "  • EFI/OC/Kexts/RogControl.kext"
echo "  • EFI/OC/ACPI/SSDT-FX506HC.aml"
echo "Remove them from config.plist and from the EFI partition, then reboot."
echo "If you only wanted to reinstall the userspace components, reboot is not required."

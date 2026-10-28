#!/bin/bash
# Armoury Crate for ASUS TUF Gaming F15 FX506HC — userspace installer.
# The OpenCore kext and SSDT are not installed by this script; see OpenCore/README.md.
set -euo pipefail

VERSION="2.2.0"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SRC="$HERE/Armoury Crate.app"
TOOLS="$HERE/Tools"
SUPPORT="$HERE/Support"
KEXT_SRC="$HERE/OpenCore/Kexts/RogControl.kext"
SSDT_SRC="$HERE/OpenCore/ACPI/SSDT-FX506HC.aml"

APP_DEST="/Applications/Armoury Crate.app"
HELPER="/usr/local/libexec/armouryctl"
BOOST_HELPER="/usr/local/libexec/ArmouryBoost"
BOOST_LABEL="com.pengubow.armouryboost"
DAEMON_PLIST="/Library/LaunchDaemons/com.pengubow.rogd.plist"
CONFIG="/Library/Application Support/RogControl/config.json"
SUDOERS="/etc/sudoers.d/armouryctl"

ASSUME_YES=0
FORCE=0
for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --force) FORCE=1 ;;
        -h|--help)
            echo "Usage: Install Armoury Crate.command [--yes] [--force]"
            echo "  --yes    do not ask for confirmation"
            echo "  --force  continue on a non-FX506HC CPU (not recommended)"
            exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Armoury Crate needs administrator access to install its helper and daemon."
    echo "You will be asked for your macOS password."
    echo
    exec sudo -- "$0" "$@"
fi

fail()  { echo "ERROR: $*" >&2; exit 1; }
ok()    { echo "  [ OK ] $*"; }
warn()  { echo "  [WARN] $*"; }
info()  { echo "  [INFO] $*"; }

confirm() {
    (( ASSUME_YES )) && return 0
    local reply=""
    read -r -p "$1 [Y/n] " reply || true
    [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

# ---------------------------------------------------------------------------
# Environment and package checks
# ---------------------------------------------------------------------------
echo "============================================================"
echo " Armoury Crate $VERSION — ASUS TUF Gaming F15 FX506HC"
echo "============================================================"
echo

[[ "$(uname -s)" == "Darwin" ]] || fail "This installer runs on macOS only."
[[ "$(uname -m)" == "x86_64" ]] || fail "This build is for Intel Macs (x86_64) only."

for path in "$APP_SRC" "$KEXT_SRC" "$SSDT_SRC" "$TOOLS/armouryctl" \
            "$TOOLS/ArmouryBoost" "$TOOLS/rogd" "$TOOLS/rogctl" "$TOOLS/tufrgb" \
            "$SUPPORT/config.json" "$SUPPORT/com.pengubow.rogd.plist" \
            "$SUPPORT/com.pengubow.armouryboost.plist"; do
    [[ -e "$path" ]] || fail "The package is incomplete: missing $path"
done

OS_VERSION="$(sw_vers -productVersion)"
OS_MAJOR="${OS_VERSION%%.*}"
if [[ "$OS_MAJOR" -lt 13 ]]; then
    fail "macOS 13 Ventura or newer is required (found $OS_VERSION)."
fi
ok "macOS $OS_VERSION"

CPU="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
if [[ "$CPU" != *"i5-11400H"* ]]; then
    if (( FORCE )); then
        warn "CPU is “${CPU:-unknown}”, not an i5-11400H. Continuing because --force was used."
    else
        fail "This package is for the FX506HC (Intel Core i5-11400H). Found: ${CPU:-unknown}. Use --force only if you understand the risk."
    fi
else
    ok "CPU: $CPU"
fi

CONSOLE_USER="$(stat -f %Su /dev/console 2>/dev/null || true)"
if [[ -z "$CONSOLE_USER" || "$CONSOLE_USER" == "root" || "$CONSOLE_USER" == "loginwindow" ]]; then
    CONSOLE_USER="${SUDO_USER:-}"
fi
CONSOLE_UID=0
if [[ -n "$CONSOLE_USER" && "$CONSOLE_USER" != "root" ]]; then
    CONSOLE_UID="$(id -u "$CONSOLE_USER" 2>/dev/null || echo 0)"
fi
if [[ "$CONSOLE_UID" -ne 0 ]]; then
    ok "Desktop user: $CONSOLE_USER"
else
    warn "No graphical desktop user was detected. The app will be installed, but you must launch it after logging in."
fi

CONSOLE_HOME=""
CONSOLE_GROUP=""
if [[ "$CONSOLE_UID" -ne 0 ]]; then
    CONSOLE_HOME="$(dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
    CONSOLE_GROUP="$(id -gn "$CONSOLE_USER" 2>/dev/null || echo staff)"
    if [[ -z "$CONSOLE_HOME" || ! -d "$CONSOLE_HOME" ]]; then
        warn "Could not determine the home folder for $CONSOLE_USER; the audio helper will not be loaded until next login."
        CONSOLE_HOME=""
    fi
fi
BOOST_AGENT=""
BOOST_DATA=""
if [[ -n "$CONSOLE_HOME" ]]; then
    BOOST_AGENT="$CONSOLE_HOME/Library/LaunchAgents/$BOOST_LABEL.plist"
    BOOST_DATA="$CONSOLE_HOME/Library/Application Support/ArmouryBoost"
fi

if [[ "$CONSOLE_UID" -ne 0 ]] && ! dseditgroup -o checkmember -m "$CONSOLE_USER" admin >/dev/null 2>&1; then
    warn "$CONSOLE_USER is not in the admin group; the app's sudo-based controls will not work."
fi

KEXT_LOADED=0
# Capture output first: grep -q exits early, which can SIGPIPE the producer
# and fail the pipeline under `set -o pipefail`.
KEXT_LIST="$(kmutil showloaded --list-only 2>/dev/null || true)"
if grep -q "com.pengubow.RogControl" <<<"$KEXT_LIST"; then
    KEXT_LOADED=1
fi

if (( KEXT_LOADED )); then
    ok "RogControl.kext is loaded"
else
    warn "RogControl.kext is not loaded in this boot."
    echo "         Hardware controls need the kext injected through OpenCore."
    echo "         See OpenCore/README.md, then reboot. The app can still be installed now."
fi

echo
echo "The installer will:"
echo "  • install $APP_DEST"
echo "  • install the root helper $HELPER"
echo "  • install the audio helper $BOOST_HELPER and its login agent"
echo "  • install rogd, rogctl and tufrgb in /usr/local"
echo "  • install the rogd LaunchDaemon"
echo "  • allow administrators to run the helper through sudo without a password"
echo "  • install a default 80% charge limit only if no configuration exists"
echo
echo "It will NOT modify your EFI. RogControl.kext and SSDT-FX506HC.aml must be"
echo "added to OpenCore manually (see OpenCore/README.md)."
echo

confirm "Continue with the userspace installation?" || { echo "Cancelled."; exit 0; }

# ---------------------------------------------------------------------------
# Stop the old app and daemon
# ---------------------------------------------------------------------------
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
sleep 0.3

# ---------------------------------------------------------------------------
# Install the app
# ---------------------------------------------------------------------------
rm -rf "$APP_DEST"
ditto "$APP_SRC" "$APP_DEST"
chown -R root:wheel "$APP_DEST"
chmod -R go-w "$APP_DEST"
xattr -dr com.apple.quarantine "$APP_DEST" 2>/dev/null || true
ok "Installed Armoury Crate.app"

# ---------------------------------------------------------------------------
# Install helpers and tools
# ---------------------------------------------------------------------------
install -d -o root -g wheel -m 755 /usr/local/libexec /usr/local/bin
install -d -o root -g wheel -m 755 "/Library/Application Support/RogControl"
install -d -o root -g wheel -m 755 /Library/LaunchDaemons

install -o root -g wheel -m 755 "$TOOLS/armouryctl" "$HELPER"
install -o root -g wheel -m 755 "$TOOLS/rogd" /usr/local/bin/rogd
install -o root -g wheel -m 755 "$TOOLS/rogctl" /usr/local/bin/rogctl
install -o root -g wheel -m 755 "$TOOLS/tufrgb" /usr/local/bin/tufrgb
install -o root -g wheel -m 755 "$TOOLS/ArmouryBoost" "$BOOST_HELPER"
xattr -d com.apple.quarantine "$HELPER" /usr/local/bin/rogd /usr/local/bin/rogctl /usr/local/bin/tufrgb "$BOOST_HELPER" 2>/dev/null || true
ok "Installed armouryctl, rogd, rogctl, tufrgb and ArmouryBoost"

if [[ -n "$BOOST_AGENT" ]]; then
    install -d -o "$CONSOLE_USER" -g "$CONSOLE_GROUP" -m 755 "$CONSOLE_HOME/Library/LaunchAgents"
    install -o "$CONSOLE_USER" -g "$CONSOLE_GROUP" -m 644 \
        "$SUPPORT/com.pengubow.armouryboost.plist" "$BOOST_AGENT"
    launchctl bootout "gui/$CONSOLE_UID/$BOOST_LABEL" >/dev/null 2>&1 || true
    if launchctl asuser "$CONSOLE_UID" /bin/launchctl bootstrap \
            "gui/$CONSOLE_UID" "$BOOST_AGENT" 2>/dev/null; then
        ok "Loaded the ArmouryBoost login agent"
    else
        warn "The ArmouryBoost login agent was installed but did not load."
        echo "         It will start at the next login; the app can also start it on demand."
    fi
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        [[ -S "$BOOST_DATA/boost.sock" ]] && break
        sleep 0.2
    done
    if [[ -S "$BOOST_DATA/boost.sock" ]]; then
        ok "ArmouryBoost is ready"
    else
        warn "ArmouryBoost is not listening yet. It will be started when Volume Boost is enabled."
    fi
else
    warn "Skipped the ArmouryBoost login agent because no desktop user was detected."
fi

if [[ -f "$CONFIG" ]]; then
    info "Kept the existing configuration at $CONFIG"
else
    install -o root -g wheel -m 644 "$SUPPORT/config.json" "$CONFIG"
    ok "Installed the default configuration (80% charge limit, static keyboard lighting)"
fi

# ---------------------------------------------------------------------------
# Sudoers rule for the root helper
# ---------------------------------------------------------------------------
install -d -o root -g wheel -m 755 /etc/sudoers.d
SUDOERS_TMP="$(mktemp /tmp/armoury-sudoers.XXXXXX)"
trap 'rm -f "$SUDOERS_TMP"' EXIT
cat > "$SUDOERS_TMP" <<'SUDOERS'
# Armoury Crate privileged helper.
# Installed by “Install Armoury Crate.command”; the helper validates every command and value.
%admin ALL=(root) NOPASSWD: /usr/local/libexec/armouryctl
SUDOERS
if ! visudo -cf "$SUDOERS_TMP" >/dev/null 2>&1; then
    fail "The generated sudoers rule did not validate. The previous rule (if any) was left untouched."
fi
install -o root -g wheel -m 440 "$SUDOERS_TMP" "$SUDOERS"
ok "Installed the passwordless helper rule for the admin group"

# ---------------------------------------------------------------------------
# rogd daemon
# ---------------------------------------------------------------------------
install -o root -g wheel -m 644 "$SUPPORT/com.pengubow.rogd.plist" "$DAEMON_PLIST"
launchctl enable system/com.pengubow.rogd >/dev/null 2>&1 || true
if launchctl bootstrap system "$DAEMON_PLIST" 2>/dev/null; then
    ok "Started rogd"
else
    sleep 1
    if launchctl bootstrap system "$DAEMON_PLIST" 2>/dev/null; then
        ok "Started rogd"
    else
        warn "rogd did not start automatically. Run:"
        echo "         sudo launchctl bootstrap system $DAEMON_PLIST"
        echo "         sudo launchctl print system/com.pengubow.rogd"
    fi
fi

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
HELPER_VERSION="$("$HELPER" version 2>/dev/null || true)"
if [[ "$HELPER_VERSION" == "$VERSION" ]]; then
    ok "Helper responds: $HELPER_VERSION"
else
    warn "The helper did not report version $VERSION (got “${HELPER_VERSION:-no response}”)."
fi

BOOST_VERSION="$("$BOOST_HELPER" --version 2>/dev/null || true)"
if [[ "$BOOST_VERSION" == "$VERSION" ]]; then
    ok "ArmouryBoost responds: $BOOST_VERSION"
else
    warn "ArmouryBoost did not report version $VERSION (got “${BOOST_VERSION:-no response}”)."
fi

if [[ "$CONSOLE_UID" -ne 0 ]]; then
    if sudo -u "$CONSOLE_USER" /usr/bin/sudo -n "$HELPER" version >/dev/null 2>&1; then
        ok "Passwordless helper access works for $CONSOLE_USER"
    else
        warn "Could not verify passwordless helper access for $CONSOLE_USER."
        echo "         Check that the user is in the admin group and that $SUDOERS is installed."
    fi
fi

if (( KEXT_LOADED )); then
    if STATUS="$("$HELPER" status 2>&1)"; then
        ok "RogControl.kext is answering"
    else
        warn "The kext is loaded but the helper could not read it:"
        echo "$STATUS" | sed 's/^/         /'
    fi
fi

if launchctl print system/com.pengubow.rogd >/dev/null 2>&1; then
    ok "rogd LaunchDaemon is loaded"
else
    warn "rogd LaunchDaemon is not loaded"
fi

if [[ "$CONSOLE_UID" -ne 0 ]]; then
    if launchctl print "gui/$CONSOLE_UID/$BOOST_LABEL" >/dev/null 2>&1; then
        ok "ArmouryBoost login agent is loaded"
    else
        warn "ArmouryBoost login agent is not loaded"
    fi
fi

echo
echo "============================================================"
echo " Userspace installation complete"
echo "============================================================"
echo "  App        : $APP_DEST"
echo "  Helper     : $HELPER"
echo "  Audio      : $BOOST_HELPER"
echo "  Config     : $CONFIG"
echo "  Daemon log : /Library/Logs/rogd.log"
echo
if (( KEXT_LOADED )); then
    echo "Next: open Armoury Crate from /Applications."
    echo "If the charge limit is still pending, wait a minute and use Devices → Battery → Retry."
else
    echo "Next steps — install the OpenCore pieces, then reboot:"
    echo "  1. Copy $KEXT_SRC to EFI/OC/Kexts/."
    echo "  2. Copy $SSDT_SRC to EFI/OC/ACPI/."
    echo "  3. Add both to config.plist (see OpenCore/README.md)."
    echo "  4. Reboot, run “Check Installation.command”, then open Armoury Crate."
    echo
    echo "Recommended boot arguments: -rogcontrolnocppc -rogcontrolnohid"
fi
echo

if [[ "$CONSOLE_UID" -ne 0 ]] && confirm "Open Armoury Crate now?"; then
    if ! launchctl asuser "$CONSOLE_UID" /usr/bin/sudo -u "$CONSOLE_USER" /usr/bin/open -a "$APP_DEST" 2>/dev/null; then
        warn "Could not open the app automatically. Open it from /Applications."
    fi
fi

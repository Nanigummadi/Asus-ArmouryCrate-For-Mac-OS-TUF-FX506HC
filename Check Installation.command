#!/bin/bash
# Armoury Crate for ASUS TUF Gaming F15 FX506HC — installation check.
# Reads only. Does not install, delete, or ask for an administrator password.
set -uo pipefail

APP="/Applications/Armoury Crate.app"
HELPER="/usr/local/libexec/armouryctl"
BOOST_HELPER="/usr/local/libexec/ArmouryBoost"
BOOST_LABEL="com.pengubow.armouryboost"
BOOST_AGENT="$HOME/Library/LaunchAgents/$BOOST_LABEL.plist"
DAEMON_PLIST="/Library/LaunchDaemons/com.pengubow.rogd.plist"
CONFIG="/Library/Application Support/RogControl/config.json"
SUDOERS="/etc/sudoers.d/armouryctl"

PASS=0
WARN=0
FAIL=0

pass() { printf '  [ OK ] %s\n' "$*"; PASS=$((PASS + 1)); }
warn() { printf '  [WARN] %s\n' "$*"; WARN=$((WARN + 1)); }
fail() { printf '  [FAIL] %s\n' "$*"; FAIL=$((FAIL + 1)); }
info() { printf '  [INFO] %s\n' "$*"; }

echo "============================================================"
echo " Armoury Crate — installation check"
echo "============================================================"
echo
printf '  macOS   : %s\n' "$(sw_vers -productVersion)"
printf '  CPU     : %s\n' "$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
printf '  Arch    : %s\n' "$(uname -m)"
echo

# ---------------------------------------------------------------------------
# Userspace
# ---------------------------------------------------------------------------
if [[ -d "$APP" ]]; then
    APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
                   "$APP/Contents/Info.plist" 2>/dev/null || echo "?")"
    pass "App installed: $APP (version $APP_VERSION)"
else
    fail "App is not installed in /Applications"
fi

if [[ -x "$HELPER" ]]; then
    HELPER_VERSION="$("$HELPER" version 2>/dev/null || true)"
    if [[ -n "$HELPER_VERSION" ]]; then
        pass "Privileged helper installed: version $HELPER_VERSION"
    else
        warn "Helper exists at $HELPER but did not answer"
    fi
else
    fail "Privileged helper is missing: $HELPER"
fi

if [[ -x "$BOOST_HELPER" ]]; then
    BOOST_VERSION="$("$BOOST_HELPER" --version 2>/dev/null || true)"
    if [[ -n "$BOOST_VERSION" ]]; then
        pass "Audio helper installed: version $BOOST_VERSION"
    else
        warn "Audio helper exists at $BOOST_HELPER but did not answer"
    fi
    if [[ -f "$BOOST_AGENT" ]]; then
        pass "Audio helper login agent installed"
    else
        warn "Audio helper login agent is missing: $BOOST_AGENT"
    fi
    if launchctl print "gui/$(id -u)/$BOOST_LABEL" >/dev/null 2>&1; then
        pass "Audio helper login agent is loaded"
    else
        warn "Audio helper login agent is not loaded; it starts when Volume Boost is enabled"
    fi
    if [[ -S "$HOME/Library/Application Support/ArmouryBoost/boost.sock" ]]; then
        pass "Audio helper is listening"
    else
        info "Audio helper socket is not present; enable Volume Boost to start it"
    fi
else
    fail "Audio helper is missing: $BOOST_HELPER"
fi

if [[ -f "$SUDOERS" ]]; then
    if [[ -x "$HELPER" ]] && sudo -n "$HELPER" version >/dev/null 2>&1; then
        pass "Passwordless helper access works for $(id -un)"
    else
        warn "Sudoers file exists, but passwordless access did not work. Run the installer again."
    fi
else
    fail "Sudoers rule is missing: $SUDOERS"
fi

if launchctl print system/com.pengubow.rogd >/dev/null 2>&1; then
    pass "rogd LaunchDaemon is loaded"
else
    fail "rogd LaunchDaemon is not loaded"
fi

if [[ -f "$DAEMON_PLIST" ]]; then
    pass "rogd plist installed: $DAEMON_PLIST"
else
    fail "rogd plist is missing: $DAEMON_PLIST"
fi

if [[ -f "$CONFIG" ]]; then
    info "Configuration: $CONFIG"
else
    warn "No configuration file; defaults will be used when a setting is applied"
fi

if pgrep -x ArmouryCrate >/dev/null 2>&1; then
    pass "Armoury Crate is running"
else
    info "Armoury Crate is not running"
fi

# ---------------------------------------------------------------------------
# Kext and SSDT
# ---------------------------------------------------------------------------
KEXT_LIST="$(kmutil showloaded --list-only 2>/dev/null || true)"
if grep -q "com.pengubow.RogControl" <<<"$KEXT_LIST"; then
    pass "RogControl.kext is loaded"
    if [[ -x "$HELPER" ]]; then
        echo
        echo "  Hardware status:"
        if STATUS="$("$HELPER" status 2>&1)"; then
            printf '%s\n' "$STATUS" | sed 's/^/    /'
        else
            warn "The helper could not read the kext:"
            printf '%s\n' "$STATUS" | sed 's/^/    /'
        fi
    fi
else
    fail "RogControl.kext is not loaded"
    info "Add it to EFI/OC/Kexts and config.plist after Lilu and VirtualSMC, then reboot."
fi

if [[ -f "$APP/Contents/Resources/armouryctl" ]]; then
    pass "Bundled fallback helper is present in the app"
else
    warn "Bundled fallback helper is missing from the app"
fi

# ---------------------------------------------------------------------------
# Helpful hints
# ---------------------------------------------------------------------------
echo
echo "  Notes:"
info "The SSDT (SSDT-FX506HC.aml) cannot be verified from userspace; check ACPI → Add in config.plist."
info "Battery charge limit: give the firmware up to a minute after boot/resume, then use Devices → Battery → Retry."
info "Volume Boost: the first enable asks for System Audio Recording permission for ArmouryBoost; a later helper update may ask once more."
info "Logs: /Library/Logs/rogd.log · diagnostics: sudo /usr/local/libexec/armouryctl diagnostics"

echo
echo "============================================================"
printf ' Result: %d OK, %d warning(s), %d failure(s)\n' "$PASS" "$WARN" "$FAIL"
echo "============================================================"

if (( FAIL > 0 )); then
    exit 1
fi
exit 0

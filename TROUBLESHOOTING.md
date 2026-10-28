# Troubleshooting

Run **Check Installation.command** first. It reports the app, helpers, audio login agent,
`sudoers` rule, `rogd` and kext state without changing anything.

For a full report:

```sh
sudo /usr/local/libexec/armouryctl diagnostics
sudo /usr/local/libexec/armouryctl status
tail -100 /Library/Logs/rogd.log
```

Use **Settings → Copy diagnostics** in the app to copy the userspace report to the clipboard.

---

## The app says “KEXT OFFLINE” or the helper cannot find the kext

Check whether the kext is loaded:

```sh
kmutil showloaded --list-only | grep -i RogControl
ioreg -l | grep -i RogControl
```

If there is no output:

1. Confirm `RogControl.kext` is in `EFI/OC/Kexts` and enabled in `Kernel → Add`.
2. Confirm **Lilu** and **VirtualSMC** are enabled and load *before* RogControl.
3. Confirm `SSDT-FX506HC.aml` is in `EFI/OC/ACPI` and enabled in `ACPI → Add`.
4. Remove old `SSDT-ROG`/FX507 tables that may define a conflicting `RGSN`.
5. Add `-rogcontrolnocppc -rogcontrolnohid` to `boot-args`.
6. Reset NVRAM from the OpenCore picker and reboot.
7. Check the OpenCore log or `sudo dmesg | grep -i rogcontrol`.

The kext is built for x86_64. It will not load on an Apple Silicon Mac.

If the kext is loaded but the app still says offline, open **Settings** and check the helper
status. The app needs both the kext and the installed helper.

---

## The app says the privileged helper is not installed

Re-run **Install Armoury Crate.command**. Then verify:

```sh
ls -l /usr/local/libexec/armouryctl
/usr/local/libexec/armouryctl version
```

Expected: `2.2.0`.

If the file exists, check the `sudoers` rule:

```sh
sudo visudo -cf /etc/sudoers.d/armouryctl
sudo -n /usr/local/libexec/armouryctl version
```

`sudo -n` must return `2.2.0` without asking for a password. If it asks for a password:

- Confirm your account is in the `admin` group:
  ```sh
  dseditgroup -o checkmember -m "$USER" admin
  ```
- Reinstall so `/etc/sudoers.d/armouryctl` is recreated with mode `0440`.
- Do not edit the rule by hand unless you understand `sudoers` syntax.

The app runs the installed helper through `/usr/bin/sudo -n`. If you removed the helper but the
app still finds its bundled fallback, only read-only commands (`status`, `diagnostics`,
`version`) are allowed; controls will still show “helper not installed”.

---

## Battery charge limit stays pending or is rejected

The app displays the exact firmware result in **Devices → Battery** and in
`armouryctl diagnostics`.

- **Pending** — the request is saved. Wait up to a minute, then press **Retry**. The kext also
  retries after boot and resume.
- **`DEVS returned 0xFFFFFFFE`** — this firmware reports the RSOC endpoint as unsupported.
  The request cannot be applied through this WMI method on this BIOS.
- **`DEVS returned 0`** — the firmware rejected the value. Try 80% or 60%; some firmware
  versions accept only specific values.
- **No write attempted** — connect the charger, wait for the EC to settle, and press Retry.

Useful commands:

```sh
sudo /usr/local/libexec/armouryctl charge 80
/usr/local/libexec/armouryctl diagnostics | grep -i charge
sudo /usr/local/bin/rogctl charge 80   # equivalent direct path
```

>The charge-limit code in this release always probes `DEVS 0x00120057`; it does not depend on
the OEM `DSTS` method. If the firmware still returns `0xFFFFFFFE`, the limit is not available
through this interface.

**This path has not been confirmed on a physical FX506HC.** If it fails, keep the diagnostics
output and do not repeatedly rewrite the EC.

---

## Operating mode will not switch

The app validates the mode reported by the kext after a write. A failure means the firmware
did not accept the request.

```sh
sudo /usr/local/libexec/armouryctl mode balanced
sudo rogctl events
```

- Make sure the laptop is on AC power for Turbo.
- Some BIOS versions ignore mode changes while the EC is busy; retry after a few seconds.
- `Fn + F5` cycles modes through the kext. If the hotkey works but the app does not, the helper
  or `sudoers` path is the problem, not the firmware.
- If the mode changes but the fans do not, the OEM thermal policy may take 30–60 seconds to
  ramp.

---

## No CPU/GPU temperature or fan RPM

- Confirm the SSDT is loaded and the EC path matches your DSDT
  (`\_SB.PC00.LPCB.EC0`, `FRMS` at `0x66`, `FRS2` at `0x68`, `CTMP` at `0x58`).
- Compare with a BIOS/Windows reading. The SSDT converts the fan tachometer period with
  `1,425,600 / period`; the result can differ from ASUS's percentage-based display.
- GPU temperature is **not** exposed by an unambiguous EC field on this DSDT. The app
  supplements it from IOAccelerator/NVIDIA telemetry. If the NVIDIA driver is not loaded, GPU
  temperature may show `—` while CPU/fan data still works.
- If you changed the SSDT, recompile it with ACPICA `iasl` and reboot.

---

## Keyboard backlight or RGB does not change

The FX506HC TUF keyboard is **single-zone** and is not an ASUS N-KEY HID device. It is driven
through ASUS WMI `DEVS 0x00100056` with a `{mode, R, G, B, speed}` payload.

- Brightness: `sudo /usr/local/libexec/armouryctl kbd 3`, or `Fn + F2` / `Fn + F3`.
- RGB: `sudo /usr/local/libexec/armouryctl rgb static ffd15c med`.
- Direct: `sudo tufrgb static ff0000`, `sudo tufrgb cycle slow`.
- The four supported effects are Static, Breathe, Rainbow Cycle and Strobe. Richer Aura modes
  are not available on this keyboard.
- If `KeyboardFound` is false in diagnostics, that is expected; the TUF path does not use the
  N-KEY device.
- The keyboard may stay dark until macOS has finished booting; the kext retries the saved
  brightness when its driver is ready.
- This has not been observed on physical FX506HC hardware. If nothing changes, collect
  `armouryctl diagnostics` and the output of `sudo rogctl events`.

---

## Touchpad / brightness

- Touchpad control needs VoodooI2C (or another driver) to answer. `Fn + F10` also goes through
  the kext; if the driver is missing, the app reports that no touchpad driver answered.
- Display brightness uses the macOS display path, not an EC write. If the slider does nothing,
  check your backlight driver and `BrightnessKeys`.
- Brightness and touchpad state are restored by `rogd` after login.

---

## rogd is not running

```sh
sudo launchctl print system/com.pengubow.rogd
tail -100 /Library/Logs/rogd.log
```

Restart it:

```sh
sudo launchctl bootout system/com.pengubow.rogd 2>/dev/null || true
sudo launchctl bootstrap system /Library/LaunchDaemons/com.pengubow.rogd.plist
```

Common causes:

- `/usr/local/bin/rogd` is missing or not executable → reinstall.
- The LaunchDaemon plist is missing → reinstall.
- The kext is not loaded yet; `rogd` keeps running and retries, but settings cannot apply.
- A malformed `config.json` → `rogd` logs a config error and keeps the previous settings. Fix
  the JSON or reinstall the default config.

`rogd` is only for persistence and per-profile settings. The app's direct helper commands work
even if `rogd` is stopped.

---

## App will not open, or macOS says it is damaged

The app is ad-hoc signed, not notarised. Remove quarantine:

```sh
xattr -dr com.apple.quarantine "/Applications/Armoury Crate.app"
open -a "Armoury Crate"
```

If macOS says the app is damaged after you modified its contents, reinstall it with the
installer. Do not run `codesign --deep` on the installed app; the installer already signs the
release build.

Check the signature:

```sh
codesign --verify --deep --strict "/Applications/Armoury Crate.app"
```

---

## “No MUX” / Ultimate mode is missing

Correct. The FX506HC is an Optimus laptop with no MUX switch. There is no dGPU-only mode to
offer. On macOS, graphics support for the RTX 3050 comes from
[nmx-intel](https://github.com/kitsuneislife/nmx-intel); this package does not install a GPU
driver.

---

## Volume boost asks for permission, or audio goes quiet

The boost uses a Core Audio process tap owned by the per-user **ArmouryBoost** login agent.
macOS gates the tap behind **System Audio Recording**. The first time you turn on
**Devices → Audio → Volume Boost**, allow the prompt for **ArmouryBoost**. If it was denied,
open **System Settings → Privacy & Security → Screen & System Audio Recording**, enable
**ArmouryBoost**, then turn boost on again. The card also has an **Open Privacy Settings**
button.

Reinstalling an update replaces the helper, which changes its binary hash. macOS treats that
as a new program and may ask for **System Audio Recording** again. Approve it; the saved boost
level and enabled state are not lost.

If the boost reports **Starting** while the Mac is idle, that is normal: the IOProc does not
run until an app starts playing audio. The helper verifies callbacks as soon as playback
begins. If audio is playing and boost still fails to deliver it, the helper destroys the tap
automatically, which restores normal sound, and the card changes to **Failed**. Check
`tail -40 /tmp/ArmouryBoost.err` for the reason. Do not leave a failed boost enabled.

If the card stays on **Unavailable** or **Starting**:

```sh
launchctl print "gui/$(id -u)/com.pengubow.armouryboost"
ls -l "$HOME/Library/Application Support/ArmouryBoost/boost.sock"
/usr/local/libexec/ArmouryBoost --version
tail -40 /tmp/ArmouryBoost.err
```

Reinstall with **Install Armoury Crate.command** if the helper or its login agent is missing.
The app can start the login agent, but it cannot install it without administrator access.

While boost is active, audio is routed through a private aggregate device. Turning boost off
returns audio to the normal path immediately. Audio is never recorded. If the output device
changes (for example, headphones are connected), the boost rebuilds against the new default
output automatically.

---

## Fans are loud / temperatures are high

- Try **Silent** or **Balanced** mode.
- Do not use custom fan curves on this machine; the OEM DSDT marks the fan-curve and
  power-limit WMI devices unsupported. The app intentionally offers only firmware thermal
  policies.
- Check that the vents are clear and the laptop is on a hard surface.
- If fan RPM reads erratically, compare with the BIOS. The SSDT conversion is based on the OEM
  tachometer formula; a BIOS/EC difference may need a corrected table.

---

## Collecting a useful bug report

Include:

```sh
sw_vers
uname -m
sysctl -n machdep.cpu.brand_string
kmutil showloaded --list-only | grep -iE 'Lilu|VirtualSMC|RogControl'
sudo /usr/local/libexec/armouryctl diagnostics
tail -200 /Library/Logs/rogd.log
```

and the exact steps that failed, plus whether the charger was connected. Remove serial
numbers or other personal data before posting publicly.

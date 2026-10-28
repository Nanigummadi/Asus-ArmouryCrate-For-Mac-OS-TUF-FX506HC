# Installation

This guide installs Armoury Crate for the **ASUS TUF Gaming F15 FX506HC** on macOS with
OpenCore.

There are two halves:

1. **OpenCore components** — `RogControl.kext` and `SSDT-FX506HC.aml`. These load at boot and
   provide the hardware bridge.
2. **Userspace components** — the app, `armouryctl`, `rogd`, `rogctl`, `tufrgb` and the
   `sudoers` rule. **Install Armoury Crate.command** installs these.

Do the OpenCore half first, then install the app.

---

## 0. Before you start

You need:

- ASUS TUF Gaming F15 **FX506HC**, i5-11400H, RTX 3050 Laptop.
- macOS 13 or newer, booting through OpenCore with **Lilu** and **VirtualSMC**.
- A backup of your EFI folder. Keep a second bootable USB if possible.
- An administrator account (member of the `admin` group).

Do **not** use this package on FX507, other TUF models, or AMD machines. The EC layout and WMI
device IDs are specific to the FX506HC.

### Gatekeeper / “unidentified developer”

The package is ad-hoc signed, not notarised. If macOS blocks the `.command` file:

- Right-click the file and choose **Open**, then confirm; or
- Remove the quarantine attribute from the extracted folder:

  ```sh
  xattr -dr com.apple.quarantine "/path/to/ArmouryCrate-FX506HC-2.2.0"
  ```

The same applies to the app, but the installer removes its quarantine attribute when copying
it to `/Applications`.

---

## 1. Copy the OpenCore files

Mount your EFI partition (for example with MountEFI or `diskutil`), then copy:

| From the package | To your EFI |
|---|---|
| `OpenCore/Kexts/RogControl.kext` | `EFI/OC/Kexts/RogControl.kext` |
| `OpenCore/ACPI/SSDT-FX506HC.aml` | `EFI/OC/ACPI/SSDT-FX506HC.aml` |

Do not rename the files. The kext is a bundle; copy the whole folder.

If you previously used an older `SSDT-ROG.aml` or `SSDT-FX507*.aml`, disable or remove it so
two tables do not define the same `RGSN` method.

---

## 2. Add both to `config.plist`

Open `EFI/OC/config.plist` with ProperTree, OpenCore Configurator or a text editor. Back it up
first.

### ACPI → Add

Add an entry for the SSDT:

```xml
<dict>
    <key>Comment</key>
    <string>SSDT-FX506HC EC sensors</string>
    <key>Enabled</key>
    <true/>
    <key>Path</key>
    <string>SSDT-FX506HC.aml</string>
</dict>
```

### Kernel → Add

Add the kext **after Lilu and VirtualSMC**. Order matters: Lilu must load first, then
VirtualSMC, then RogControl.

```xml
<dict>
    <key>Arch</key>
    <string>x86_64</string>
    <key>BundlePath</key>
    <string>RogControl.kext</string>
    <key>Comment</key>
    <string>RogControl FX506HC</string>
    <key>Enabled</key>
    <true/>
    <key>ExecutablePath</key>
    <string>Contents/MacOS/RogControl</string>
    <key>MaxKernel</key>
    <string></string>
    <key>MinKernel</key>
    <string></string>
    <key>PlistPath</key>
    <string>Contents/Info.plist</string>
</dict>
```

Do not set `MinKernel` unless you know you need it. The package targets macOS 13–26.

### Boot arguments

In `NVRAM → Add → 7C436110-AB2A-4BBB-A880-FE41995C9F82 → boot-args`, add:

```
-rogcontrolnocppc -rogcontrolnohid
```

- `-rogcontrolnocppc` leaves the Intel CPU's CPPC/EPP handling alone.
- `-rogcontrolnohid` disables the N-KEY keyboard hook. The FX506HC TUF keyboard is not an
  N-KEY device; its backlight goes through ASUS WMI instead.

Optional, only if you want settings applied by the kext without `rogd`:

```
rogcharge=80 rogmode=0
```

`rogmode=0|1|2` = Balanced / Turbo / Silent. The installed `rogd` and the app are the normal
way to change settings.

---

## 3. Reboot and verify the kext

Reboot, then run:

```sh
kmutil showloaded --list-only | grep -i RogControl
```

You should see `com.pengubow.RogControl`. Also check:

```sh
ioreg -l | grep -i RogControl
```

If the kext is missing, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) before installing the
userspace half.

---

## 4. Install the userspace components

1. Double-click **Install Armoury Crate.command**.
2. Enter your administrator password when Terminal asks.
3. Read the summary and confirm.

The installer:

- copies **Armoury Crate.app** to `/Applications`;
- installs `armouryctl` and `ArmouryBoost` to `/usr/local/libexec`;
- installs `rogd`, `rogctl` and `tufrgb` to `/usr/local/bin`;
- installs `/Library/LaunchDaemons/com.pengubow.rogd.plist` and starts `rogd`;
- installs the per-user `com.pengubow.armouryboost` login agent and starts the audio helper;
- installs `/etc/sudoers.d/armouryctl`, allowing members of the `admin` group to run the
  helper without a password;
- installs a default configuration (80% charge limit, static ROG-red keyboard lighting) **only
  if no configuration exists**;
- optionally opens the app.

It does **not** modify your EFI or install the kext.

If the installer warns that the kext is not loaded, you can continue, but hardware controls
will not work until you finish step 2–3 and reboot.

### Manual userspace installation

If you cannot run the `.command` file, the equivalent commands are:

```sh
sudo install -d -o root -g wheel -m 755 /usr/local/libexec /usr/local/bin \
  "/Library/Application Support/RogControl"
sudo install -o root -g wheel -m 755 Tools/armouryctl /usr/local/libexec/armouryctl
sudo install -o root -g wheel -m 755 Tools/ArmouryBoost /usr/local/libexec/ArmouryBoost
sudo install -o root -g wheel -m 755 Tools/rogd Tools/rogctl Tools/tufrgb /usr/local/bin/
sudo install -o root -g wheel -m 644 Support/config.json \
  "/Library/Application Support/RogControl/config.json"
sudo install -o root -g wheel -m 644 Support/com.pengubow.rogd.plist \
  /Library/LaunchDaemons/com.pengubow.rogd.plist
sudo install -o root -g wheel -m 440 Support/armouryctl.sudoers \
  /etc/sudoers.d/armouryctl
sudo launchctl bootstrap system /Library/LaunchDaemons/com.pengubow.rogd.plist
sudo ditto "Armoury Crate.app" "/Applications/Armoury Crate.app"
install -d -m 755 "$HOME/Library/LaunchAgents"
install -m 644 Support/com.pengubow.armouryboost.plist \
  "$HOME/Library/LaunchAgents/com.pengubow.armouryboost.plist"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.pengubow.armouryboost.plist"
```

Then remove quarantine from the app:

```sh
sudo xattr -dr com.apple.quarantine "/Applications/Armoury Crate.app"
```

---

## 5. First run

Open **Armoury Crate** from `/Applications`.

Check these pages:

1. **Home** — CPU/GPU temperatures, fan RPM and battery should be live. The sidebar should say
   **HARDWARE ONLINE**, not **KEXT OFFLINE**.
2. **Operating Modes** — try Silent, Balanced and Turbo. The firmware result is checked; a
   rejected switch shows an error instead of a false success.
3. **Devices → System** — confirm the kext, helper and ACPI sensor status.
4. **Devices → Battery** — set 60%, 80% or 100%. Wait up to a minute after boot or wake, then
   press **Retry** if the status is still pending.
5. **Lighting** — set brightness and an effect. The FX506HC has a single-zone TUF keyboard
   (Static, Breathe, Rainbow Cycle, Strobe).
6. **Devices → Audio → Volume Boost** — enable it and allow **System Audio Recording** for
   **ArmouryBoost** when macOS asks. Drag the gain slider to hear the change immediately.
   After a later helper update, macOS may ask once more because the binary changed; approve
   it and the saved setting continues to work. Closing the window leaves the app running;
   click the Dock icon to reopen it.
7. **Resource Monitor** — verify live graphs and per-thread load.

Then run **Check Installation.command** for a read-only summary.

### Demo preview

To explore the UI without hardware:

```sh
open -a "Armoury Crate" --args --demo
```

Demo mode uses simulated sensors and does not write to hardware. Close and reopen the app
normally to leave demo mode.

---

## 6. Configuration

The default config is:

```
/Library/Application Support/RogControl/config.json
```

It is plain JSON. The important keys:

```json
{
  "charge_limit": 80,
  "auto_profile": {
    "enabled": false,
    "on_ac": "balanced",
    "on_battery": "quiet"
  }
}
```

Profile names are `quiet`, `balanced` and `performance` (the UI calls them Silent, Balanced
and Turbo). After editing, either use the app or tell `rogd` to reload:

```sh
sudo kill -HUP "$(cat /var/run/rogd.pid)"
```

Changing `charge_limit` in the file does **not** write to the firmware by itself. Apply it
from the app or with:

```sh
sudo /usr/local/libexec/armouryctl charge 80
```

---

## 7. Updating

1. Quit Armoury Crate.
2. Replace `RogControl.kext` and `SSDT-FX506HC.aml` in your EFI if the release notes say they
   changed.
3. Run the new **Install Armoury Crate.command**. It keeps your existing configuration.
4. Reboot.

The app version and helper version are shown in **Settings**; both should read `2.2.0`.

---

## 8. Uninstalling

Run **Uninstall Armoury Crate.command**. It removes the app, helpers, daemon, command-line
tools, `sudoers` rule, audio login agent and (by default) settings/logs.

It deliberately leaves the OpenCore files alone. To remove them:

1. Remove the `RogControl.kext` and `SSDT-FX506HC.aml` entries from `config.plist`.
2. Delete the files from `EFI/OC/Kexts` and `EFI/OC/ACPI`.
3. Reboot.

Use `--keep-settings` if you want to keep
`/Library/Application Support/RogControl` and `/Library/Logs/rogd.log`.

---

## Security notes

- The `sudoers` rule allows any member of the `admin` group to run **only**
  `/usr/local/libexec/armouryctl` without a password. The helper validates all arguments
  before writing to hardware.
- The helper and tools are installed root-owned and are not writable by normal users.
- The app never runs as root. It invokes the installed helper through `sudo -n`.
- Volume boost uses a private Core Audio process tap owned by the per-user
  **ArmouryBoost** login agent, and is active only while the boost is enabled. macOS asks for
  **System Audio Recording** permission for ArmouryBoost the first time; audio is processed
  in memory for playback and is never recorded. Revoke it any time in
  **System Settings → Privacy & Security → Screen & System Audio Recording**.
- The audio helper runs as your normal user, not as root, and only accepts commands over a
  `0700` per-user socket.
- Do not weaken the `sudoers` rule or replace the helper with a script you do not trust.

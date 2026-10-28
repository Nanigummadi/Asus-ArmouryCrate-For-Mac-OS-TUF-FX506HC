# Armoury Crate for macOS — ASUS TUF Gaming F15 (FX506HC)

**Version 2.2.0** • **Target Hardware:** ASUS TUF Gaming F15 FX506HC (Intel Core i5-11400H • NVIDIA GeForce RTX 3050 Laptop GPU • 8 GB RAM) • **Platform:** macOS 13 Ventura – macOS 26 Tahoe (`x86_64`) • **Bootloader:** OpenCore (`Lilu` + `VirtualSMC`)

A native macOS hardware control center and kernel driver suite purpose-built for the **ASUS TUF Gaming F15 FX506HC** running macOS via OpenCore. Rebuilt around the Republic of Gamers (ROG) dark visual system, Armoury Crate brings real-time embedded controller (EC) telemetry, firmware thermal profile switching, manual dual-fan duty control with thermal guard protection, battery charge-limit management, single-zone TUF RGB lighting, and a real-time 100–200% system-audio volume booster to macOS.

---

## Interface & Sample Gallery (Hardware-Verified on FX506HC)

All screenshots below were captured live on an **ASUS TUF Gaming F15 FX506HC** (`11th Gen Intel Core i5-11400H @ 2.70 GHz`, `NVIDIA GeForce RTX 3050 Laptop GPU`, `8 GB RAM`) with `RogControl.kext`, `SSDT-FX506HC.aml`, `armouryctl`, `rogd`, and `ArmouryBoost` active (`EC ONLINE`).

### 1. Dashboard Overview



The **Dashboard** provides an immediate, 1-second refresh command center for the FX506HC:

* **Device Summary Card:** Identifies the **TUF Gaming F15 FX506HC** hardware configuration, active thermal policy (`TURBO MODE • BATTERY`), live CPU temperature (`57°C`), and a direct shortcut to **Device Settings**.
* **System Monitor (`LIVE • 1 S`):** Displays two-column live telemetry across **CPU** (`2.68 GHz` base clock, `5%` usage, `57 °C` temperature, `2376 RPM` fan speed, `12` threads), **GPU** (`2387 RPM` fan speed), **Fan** (`Automatic` control, `Normal` Thermal Guard), and **Memory** (`6.11 GB / 8 GB` RAM, `40.28 GB / 173.15 GB` storage, `50%` battery with `60%` limit, `13m` uptime).
* **System Configuration & Storage/Power:** Provides quick status tiles (`Fan: Automatic`, `Keyboard: Level 3`, `Charge Limit: 60%`, `Touchpad: Enabled`) alongside live battery health (`75% • 248 cycles`) and power draw (`45.6 W • 0h 38m left`).
* **Operating Mode Bar:** Switches instantly between **Silent**, **Balanced**, **Turbo**, and **Manual** fan profiles.

### 2. Operating Mode & Scenario Profiles



The **Operating Mode** view manages ASUS WMI thermal policies and automated power-state transitions (`FIRMWARE CONNECTED`):

* **Performance Profile (`FIRMWARE`):**
  * **Silent (`Quiet Fans • Lower Power`):** Prioritizes acoustics for light work, media playback, and battery longevity (`Fans: Auto`, `Power: Efficient`, `Acoustics: Quiet`).
  * **Balanced (`Everyday Performance`):** Default equilibrium of fan noise, temperature, and system responsiveness (`Fans: Auto`, `Power: Standard`, `Acoustics: Balanced`).
  * **Turbo (`Maximum Cooling and Power`):** Raises the thermal and power envelope for gaming and sustained workloads (`Fans: Auto`, `Power: Maximum`, `Acoustics: Performance`).
* **Manual Fan Control (`EMBEDDED CONTROLLER`):** Adjusts independent **CPU Fan** and **GPU Fan** duty sliders (`10–100%`) using draft sliders that only write to the EC when **Apply Manual** is pressed, or hands control back via **Return to Auto**.
* **Scenario Profile (`AUTOMATIC`):** Automatically switches thermal profiles when the AC charger is connected or unplugged (e.g., **Balanced** on AC power and **Silent** on battery).

### 3. Cooling, EC Sensors & Thermal Guard Watchdog



Under **Devices → Cooling**, the app exposes dual-channel fan tachometers and EC thermal safeguards (`SYSTEM ONLINE` • `AUTO CONTROL`):

* **Dual Fan Gauges:** Live tachometer readouts for the **CPU Fan** (`36%` duty, `2383 RPM`, `Turbo thermal profile`) and **GPU Fan** (`38%` duty, `2368 RPM`, `Independent fan channel`).
* **Temperatures (`SENSORS`):** Live EC CPU package temperature (`56°C`), active thermal mode (`Turbo`), fan control state (`Firmware automatic`), and manual duty state (`Not active`).
* **Controller Diagnostics & Thermal Guard:** Validates EC register readiness (`Registers OK; tachometer differs from ACPI`), self-test state (`First apply`), and watchdog status (`Normal`). The built-in thermal guard forces fans to **100% at 92 °C**, hands control back to OEM firmware at **98 °C**, and restores user manual duty once temperatures drop below **84 °C**.
* **Temperature History (`LAST 80 SECONDS`):** Plots real-time thermal stability across an 80-second rolling window.

### 4. Battery Health & Firmware Charge Limit



Under **Devices → Battery**, Armoury Crate reads smart-battery telemetry and writes charge thresholds directly to the ASUS embedded controller (`APPLIED AND CONFIRMED`):

* **Charge Limit (`BATTERY CARE 60–100%`):** Writes the requested RSOC charge cap to ASUS WMI `DEVS 0x00120057`. Includes one-click presets for **60%** (Maximum Lifespan), **80%** (Balanced), and **100%** (Full Capacity), plus a **Retry** button and confirmation readback after every boot and wake.

### 5. Discrete GPU & Optimus Status



Under **Devices → GPU**, the app inspects the discrete graphics pipeline and driver state (`DRIVER ACTIVE`):

* **Adapter Profile:** Identifies the **NVIDIA GeForce RTX 3050 Laptop GPU** (`4 GB GDDR6 • Ampere • PCIe 4.0 x16 (Optimus)`) with active status badges (`✓ NVIDIA ACTIVE`, `OPTIMUS`).
* **Live Performance & Driver Bridge:** Reports active acceleration through the **`NVAccel`** driver (`nmx-intel` path), where applications render through the NVIDIA GPU while the internal laptop panel is driven by Intel integrated graphics.
* **Power Features (`HARDWARE`):** Confirms hardware-managed **Dynamic Boost**, **GPU temperature target**, **NVIDIA acceleration (`Active`)**, and **Hybrid graphics (`Optimus`)**.

### 6. Audio Controls & 200% Live Volume Boost



Because the FX506HC built-in speakers clamp hardware volume at 100%, **Devices → Audio** integrates a real-time DSP gain stage (`READY` • `ACTIVE`):

* **Output & Input Controls:** Manages **Built-in Output** (`100%`) and **Built-in Microphone** (`Input active`, mute toggle) for the system default audio devices.
* **Volume Boost (`UP TO 200%`):** Powered by the per-user **`ArmouryBoost`** login agent, this control routes default output audio through a private Core Audio process tap and aggregate device, applying **100% to 200% (`+100% gain`)** in-memory inside a real-time IOProc without recording audio to disk.

### 7. Real-Time Resource Monitor



The **Resource Monitor** delivers 1-second hardware and OS telemetry (`LIVE • 1 S`):

* **Summary KPI Cards:** Tracks **CPU Utilisation** (`12%`, `12 threads • user 6%`), **GPU Utilisation** (`NVIDIA GeForce RTX 3050 Laptop GPU`), **Memory Used** (`68%`, `5.41 GB of 8 GB`), and **Package Temperature** (`62°C` via embedded controller sensor).
* **Telemetry History (`LAST 80 SAMPLES`):** Interactive time-series graph switchable between **CPU**, **GPU**, **MEMORY**, and **TEMPERATURE**, complete with minimum (`5%`), average (`15%`), and peak (`52%`) statistics.
* **At a Glance & Per-Thread CPU Cores:** Displays processor metadata (`11th Gen Intel(R) Core(TM) i5-11400H @ 2.70GHz`, `12 logical cores`), system thermal state (`Nominal`), dual fan speeds (`2387 RPM` / `2376 RPM`), control bridge connectivity (`Connected`), individual load bars for logical cores, and unified memory pressure.

---

## System Architecture

Armoury Crate separates user-interface rendering from privileged hardware writes and real-time audio processing across four layers:

1. **Hardware Layer (`RogControl.kext` & `SSDT-FX506HC.aml`):**
   * `RogControl.kext` is a **VirtualSMC** plugin that communicates with the ASUS WMI/ACPI interface (`\_SB.ATKD`) and embedded controller (`\_SB.PC00.LPCB.EC0`) to expose CPU/GPU temperatures, dual fan tachometers, thermal policies, battery charge limits, and single-zone TUF RGB lighting as native IORegistry properties.
   * `SSDT-FX506HC.aml` maps the FX506HC's OEM EC sensor offsets (`FRMS`, `FRS2`, `CTMP`) into the `\_SB.ATKD.RGSN` ACPI package so the kext can read sensors safely without probing arbitrary EC registers.
2. **Privileged Helper Layer (`armouryctl`, `rogd`, `rogctl`, `tufrgb`):**
   * `armouryctl` (`/usr/local/libexec/armouryctl`) accepts a strictly validated command set from the desktop app via a root-owned, passwordless `sudoers` rule (`/etc/sudoers.d/armouryctl`) restricted to the `admin` group.
   * `rogd` runs as a system `LaunchDaemon` (`com.pengubow.rogd.plist`) to restore saved thermal modes, battery charge limits, keyboard backlight/RGB settings, and touchpad states at boot and after sleep/wake.
   * `rogctl` and `tufrgb` provide direct CLI access for hardware diagnostics and scripting.
3. **Desktop Application Layer (`Armoury Crate.app`):**
   * Built in native SwiftUI with the ROG dark theme, the app runs strictly as the logged-in desktop user (never as `root`). It pauses hardware polling and UI invalidation automatically when minimized, hidden, or occluded to keep background CPU usage near zero.
4. **Real-Time Audio Layer (`ArmouryBoost`):**
   * Runs as a per-user `LaunchAgent` (`com.pengubow.armouryboost.plist`) listening on a `0700` Unix domain socket (`~/Library/Application Support/ArmouryBoost/boost.sock`). When enabled, it attaches a private Core Audio process tap and multiplies output samples by `1.00–2.00` in real time, tearing down the tap immediately if audio callbacks stall.

---

## Feature Matrix

| Feature Area | Capability on ASUS TUF Gaming F15 FX506HC | Status |
| :--- | :--- | :--- |
| **Dashboard** | Live CPU/GPU temperatures, dual fan RPMs, RAM/disk usage, battery health, power draw, quick toggles | Verified on Hardware |
| **Operating Modes** | Firmware thermal policies (**Silent**, **Balanced**, **Turbo**) via ASUS WMI with confirmation check | Verified on Hardware |
| **Scenario Profiles** | Automatic mode switching between AC power and battery power | Verified on Hardware |
| **Cooling & Manual Fans** | Dual EC fan tachometers (`FRMS`/`FRS2`), manual CPU/GPU duty (`10–100%`) via EC `0x25C`/`0x25D`, 92°C/98°C thermal watchdog | Verified on Hardware |
| **Battery Charge Limit** | Firmware RSOC charge cap (`60–100%`) via WMI `DEVS 0x00120057`, persistent across boot and wake | Verified on Hardware |
| **Keyboard & Aura Sync** | Backlight brightness levels `0–3` (`0x00050021`) and single-zone TUF RGB (`Static`, `Breathe`, `Rainbow Cycle`, `Strobe` via `0x00100056`) | Verified on Hardware |
| **GPU Telemetry** | NVIDIA GeForce RTX 3050 Laptop (`NVAccel` / Optimus) status and IOAccelerator telemetry | Verified on Hardware |
| **Volume Boost** | Live **100–200% system-audio gain** via Core Audio process tap (`ArmouryBoost` helper) | Verified on Hardware |
| **Resource Monitor** | Live 1-second CPU, GPU, memory, package temperature, 80-sample history charts, and per-thread load bars | Verified on Hardware |
| **Boot Persistence** | `rogd` LaunchDaemon restores thermal profile, charge limit, keyboard lighting, and fan settings on boot/wake | Verified on Hardware |
| **MUX / Ultimate Mode** | Hardware uses NVIDIA Optimus (no physical MUX switch; internal display wired to Intel iGPU) | Not Applicable |
| **Custom Fan Curves / PL1/PL2** | OEM DSDT marks WMI custom fan-curve and CPU power-limit endpoints as unsupported | Not Offered |

---

## Package Structure

```text
ArmouryCrate-FX506HC-2.2.0/
├── Armoury Crate.app                      # Native SwiftUI macOS desktop application
├── Install Armoury Crate.command          # Interactive userspace installer script
├── Uninstall Armoury Crate.command        # Userspace uninstaller script
├── Check Installation.command             # Read-only verification & diagnostic script
├── OpenCore/
│   ├── Kexts/
│   │   └── RogControl.kext                # VirtualSMC hardware backend plugin
│   ├── ACPI/
│   │   └── SSDT-FX506HC.aml               # FX506HC EC sensor table (RGSN)
│   └── README.md                          # OpenCore EFI setup instructions
├── Tools/
│   ├── armouryctl                         # Privileged root helper binary
│   ├── ArmouryBoost                       # Per-user Core Audio 100–200% boost agent
│   ├── rogd                               # Boot/wake persistence daemon
│   ├── rogctl                             # CLI hardware control & event monitor
│   └── tufrgb                             # CLI single-zone TUF RGB controller
├── Support/
│   ├── config.json                        # Default daemon configuration (80% charge limit, ROG red)
│   ├── com.pengubow.rogd.plist            # LaunchDaemon plist for rogd
│   ├── com.pengubow.armouryboost.plist    # LaunchAgent plist for ArmouryBoost
│   └── armouryctl.sudoers                 # Passwordless sudoers rule for admin group
├── VERSION.txt                            # Release version (2.2.0)
├── README.md                              # Main documentation
├── INSTALL.md                             # Detailed step-by-step installation guide
├── TROUBLESHOOTING.md                     # Diagnostics & troubleshooting reference
└── CHANGELOG.md                           # Release history (2.1.0 – 2.2.0)
```

---

## System Requirements

* **Laptop Model:** ASUS TUF Gaming F15 **FX506HC** only (Intel Core i5-11400H + NVIDIA GeForce RTX 3050 Laptop GPU). Do **not** install on FX507, AMD Ryzen TUF models, or other ASUS laptops, as EC register offsets and WMI device IDs are specific to the FX506HC.
* **Operating System:** macOS 13 Ventura or newer (`x86_64`), tested up to macOS 26 Tahoe (`26.7`).
* **Bootloader & Kernel Extensions:** OpenCore with **Lilu.kext** and **VirtualSMC.kext** enabled and loaded prior to `RogControl.kext`.
* **Permissions:** Administrator user account (member of the macOS `admin` group).
* **Safety Preparation:** Keep a backup of your working `EFI` folder on a separate FAT32 USB flash drive before modifying `config.plist`.

---

## Step-by-Step Installation Guide

Installation consists of two parts: **Part 1 (OpenCore EFI Setup)** loads the kernel extension and ACPI table at boot, and **Part 2 (Userspace Installer)** installs the application, privileged helper, audio booster, and background daemon. Complete **Part 1** first.

### Step 0: Remove macOS Gatekeeper Quarantine

Because the package is ad-hoc signed rather than Apple-notarized, clear the quarantine extended attribute on the extracted folder before running `.command` scripts:

```sh
xattr -dr com.apple.quarantine "/path/to/ArmouryCrate-FX506HC-2.2.0"
```

---

### Part 1: OpenCore Bootloader Setup (EFI)

#### 1. Copy the Kext and ACPI Table to Your EFI

Mount your EFI partition (using `MountEFI`, `ProperTree`, or `diskutil`) and copy the two OpenCore files to the exact locations below without renaming them:

| Source Path in Package | Destination Path on EFI Partition |
| :--- | :--- |
| `OpenCore/Kexts/RogControl.kext` | `EFI/OC/Kexts/RogControl.kext` |
| `OpenCore/ACPI/SSDT-FX506HC.aml` | `EFI/OC/ACPI/SSDT-FX506HC.aml` |

> **Important:** If your `EFI/OC/ACPI` folder contains an older `SSDT-ROG.aml`, `SSDT-FX507*.aml`, or any table that defines `\_SB.ATKD.RGSN`, disable or delete it so two tables do not collide.

#### 2. Add `SSDT-FX506HC.aml` to `config.plist` (`ACPI → Add`)

Open `EFI/OC/config.plist` in **ProperTree** (or your preferred plist editor) and add the following entry under `ACPI → Add`:

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

`SSDT-FX506HC.aml` reads the FX506HC OEM embedded controller fields at `\_SB.PC00.LPCB.EC0` and exposes `\_SB.ATKD.RGSN` as `Package { CPU fan RPM, GPU fan RPM, 0, CPU °C, GPU °C }`:

| EC Field | Offset | Hardware Function | Conversion / Notes |
| :--- | :--- | :--- | :--- |
| `FRMS` | `0x66` | CPU fan tachometer period | `1,425,600 / period` → RPM |
| `FRS2` | `0x68` | GPU fan tachometer period | `1,425,600 / period` → RPM |
| `CTMP` | `0x58` | CPU package temperature | Degrees Celsius (`°C`) |

#### 3. Add `RogControl.kext` to `config.plist` (`Kernel → Add`)

Under `Kernel → Add`, place `RogControl.kext` **strictly after `Lilu.kext` and `VirtualSMC.kext`** (load order is mandatory because `RogControl` links against both):

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

#### 4. Configure NVRAM Boot Arguments (`NVRAM → Add`)

Navigate to `NVRAM → Add → 7C436110-AB2A-4BBB-A880-FE41995C9F82 → boot-args` and append the two required flags:

```text
-rogcontrolnocppc -rogcontrolnohid
```

| Boot Argument | Required / Optional | Purpose |
| :--- | :--- | :--- |
| `-rogcontrolnocppc` | **Required** | Leaves Intel CPU CPPC/EPP power management untouched |
| `-rogcontrolnohid` | **Required** | Disables the ROG N-KEY USB HID hook (the FX506HC TUF keyboard uses ASUS WMI instead) |
| `rogmode=0\|1\|2` | Optional | Sets initial boot thermal mode (`0` = Balanced, `1` = Turbo, `2` = Silent) |
| `rogcharge=80` | Optional | Applies an initial battery charge limit (`60–100`) at kext load |
| `-rogcontroldbg` | Optional | Enables verbose `RogControl.kext` kernel logging for debugging |
| `-rogcontroloff` | Optional | Disables `RogControl.kext` completely (for safe-mode troubleshooting) |

#### 5. Reboot, Reset NVRAM, and Verify Kext Load

Save `config.plist`, reboot your laptop, **Reset NVRAM** once from the OpenCore boot picker, and boot into macOS. Open Terminal and confirm the kext and IORegistry service are active:

```sh
kmutil showloaded --list-only | grep -i RogControl
ioreg -l | grep -i RogControl
```

You should see `com.pengubow.RogControl` in the loaded kernel extensions list.

---

### Part 2: Userspace Application & Helper Installation

#### Option A: Guided Installer (Recommended)

1. Double-click **`Install Armoury Crate.command`** inside the extracted release folder.
2. Enter your macOS administrator password when prompted in Terminal and confirm the installation summary.

The installer automatically performs the following setup:

* Copies **`Armoury Crate.app`** to `/Applications/Armoury Crate.app` and strips quarantine attributes.
* Installs **`armouryctl`** and **`ArmouryBoost`** to `/usr/local/libexec/` (`root:wheel`, mode `0755`).
* Installs **`rogd`**, **`rogctl`**, and **`tufrgb`** to `/usr/local/bin/` (`root:wheel`, mode `0755`).
* Installs `/Library/LaunchDaemons/com.pengubow.rogd.plist` and bootstraps the **`rogd`** persistence daemon.
* Installs `~/Library/LaunchAgents/com.pengubow.armouryboost.plist` and starts the **`ArmouryBoost`** audio agent.
* Installs `/etc/sudoers.d/armouryctl` (`0440`), permitting `admin` users to run `/usr/local/libexec/armouryctl` without a password prompt.
* Seeds `/Library/Application Support/RogControl/config.json` (defaulting to an `80%` charge limit and static ROG-red keyboard lighting) if no prior configuration exists.

#### Option B: Manual Terminal Installation

If you prefer to install all userspace components manually from Terminal, run the following commands from the extracted package directory:

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
sudo xattr -dr com.apple.quarantine "/Applications/Armoury Crate.app"

install -d -m 755 "$HOME/Library/LaunchAgents"
install -m 644 Support/com.pengubow.armouryboost.plist \
  "$HOME/Library/LaunchAgents/com.pengubow.armouryboost.plist"
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.pengubow.armouryboost.plist"
```

---

### Part 3: Post-Install Verification & First-Run Walkthrough

1. **Run the Verification Script:** Double-click **`Check Installation.command`** to perform a read-only check of the app bundle, helper permissions, `sudoers` syntax, `ArmouryBoost` socket, `rogd` daemon, and `RogControl.kext` status.
2. **Launch Armoury Crate:** Open **Armoury Crate** from `/Applications`. Confirm the top-right status indicator reads **`EC ONLINE`** and the bottom-left sidebar shows **`FX506HC • system online`**.
3. **Verify Operating Modes & Cooling:** Open **Operating Mode** and test switching between **Silent**, **Balanced**, and **Turbo** (ensure AC power is connected when testing Turbo). Visit **Devices → Cooling** to inspect live CPU/GPU fan RPMs and test **Manual Fan Control** if desired.
4. **Configure Battery Care:** Open **Devices → Battery**, choose **60%**, **80%**, or **100%**, and click **Apply limit**. Wait up to 60 seconds after boot/wake or click **Retry** if the EC is still settling until the badge reads **`APPLIED AND CONFIRMED`**.
5. **Enable 200% Volume Boost:** Open **Devices → Audio** and toggle **Volume Boost** on. The first time you enable it, macOS will prompt for **System Audio Recording** permission for **`ArmouryBoost`**. Approve it in **System Settings → Privacy & Security → Screen & System Audio Recording**, then adjust the gain slider between `100%` and `200%`.
6. **Optional UI Demo Mode:** To preview the interface with simulated sensor data without writing to hardware:
   ```sh
   open -a "Armoury Crate" --args --demo
   ```

---

## Command-Line Interface (CLI) Reference

All CLI utilities are installed to `/usr/local/bin` and `/usr/local/libexec`:

```sh
# 1. Read-only hardware status and full diagnostic report (no sudo required once kext is loaded)
/usr/local/libexec/armouryctl status
/usr/local/libexec/armouryctl diagnostics

# 2. Privileged hardware controls via armouryctl
sudo /usr/local/libexec/armouryctl mode silent      # silent | balanced | turbo
sudo /usr/local/libexec/armouryctl fan set 50 50    # Set CPU and GPU manual fan duty (10–100%)
sudo /usr/local/libexec/armouryctl fan auto         # Return fans to automatic firmware control
sudo /usr/local/libexec/armouryctl charge 60        # Set battery charge limit (60–100%)
sudo /usr/local/libexec/armouryctl kbd 3            # Set keyboard backlight brightness (0–3)
sudo /usr/local/libexec/armouryctl rgb static ff0033 med   # static | breathe | cycle | strobe
sudo /usr/local/libexec/armouryctl touchpad on      # on | off

# 3. Direct utilities (rogctl & tufrgb)
sudo rogctl status
sudo rogctl charge 80
sudo rogctl brightness 70
sudo rogctl events                                  # Monitor live WMI hotkey events (Fn+F2/F3/F5/F10)

sudo tufrgb static ff0000                           # Set single-zone TUF RGB to static red
sudo tufrgb cycle slow                              # Run rainbow cycle effect
```

---

## Configuration File (`config.json`)

Persistent daemon settings are stored in `/Library/Application Support/RogControl/config.json`:

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

* Valid profile keys in `config.json` are `quiet` (Silent), `balanced` (Balanced), and `performance` (Turbo).
* To reload `rogd` after manually editing `config.json`:
  ```sh
  sudo kill -HUP "$(cat /var/run/rogd.pid)"
  ```

---

## Updating & Uninstalling

### Updating to a Newer Release

1. Quit **Armoury Crate**.
2. Replace `EFI/OC/Kexts/RogControl.kext` and `EFI/OC/ACPI/SSDT-FX506HC.aml` if the release notes indicate kernel/ACPI changes.
3. Run **`Install Armoury Crate.command`** (your existing `config.json` is preserved).
4. Reboot and re-approve **System Audio Recording** for `ArmouryBoost` if macOS prompts due to the updated helper binary hash.

### Uninstalling

1. Run **`Uninstall Armoury Crate.command`** to remove the application, helpers (`armouryctl`, `ArmouryBoost`), CLI tools (`rogd`, `rogctl`, `tufrgb`), `LaunchDaemon`/`LaunchAgent` plists, and `/etc/sudoers.d/armouryctl`.
   * To preserve your configuration and logs during uninstall, run:
     ```sh
     sudo "./Uninstall Armoury Crate.command" --keep-settings
     ```
2. Mount your EFI partition, remove `RogControl.kext` and `SSDT-FX506HC.aml` from `EFI/OC/config.plist`, delete both files from `EFI/OC/Kexts` and `EFI/OC/ACPI`, and reboot.

---

## Troubleshooting Quick Reference

| Symptom | Cause & Resolution |
| :--- | :--- |
| **Sidebar shows `KEXT OFFLINE`** | Verify `RogControl.kext` is loaded (`kmutil showloaded --list-only \| grep -i RogControl`), ordered *after* `Lilu` and `VirtualSMC` in `config.plist`, and `SSDT-FX506HC.aml` is enabled with no conflicting `SSDT-ROG.aml` table. Reset NVRAM and reboot. |
| **`Privileged helper not installed`** | Re-run `Install Armoury Crate.command`. Verify `/etc/sudoers.d/armouryctl` has `0440` permissions (`sudo visudo -cf /etc/sudoers.d/armouryctl`) and your user is in the `admin` group. |
| **Battery charge limit stays `Pending` or `Rejected`** | Connect the AC charger, wait 30–60 seconds after boot/wake, and click **Retry** in **Devices → Battery**. Check `/usr/local/libexec/armouryctl diagnostics \| grep -i charge` (`1` = confirmed, `0` = rejected, `0xFFFFFFFE` = unsupported by BIOS). |
| **Volume Boost stays on `Starting` or `Failed`** | Open **System Settings → Privacy & Security → Screen & System Audio Recording** and enable **`ArmouryBoost`**. Note that Core Audio only starts the IOProc callback when audio is actively playing; check `tail -40 /tmp/ArmouryBoost.err` if a fault occurs. |
| **GPU temperature shows `—`** | The FX506HC DSDT does not expose a dedicated EC GPU temperature register; GPU telemetry is supplemented via `IOAccelerator`/`NVAccel` when active. Dual fan RPMs and EC CPU temperatures operate independently. |
| **App blocked by Gatekeeper / "Damaged"** | Run `sudo xattr -dr com.apple.quarantine "/Applications/Armoury Crate.app"` and launch again. Do not re-sign the installed bundle with `codesign --deep`. |


> **Disclaimer:** This project is an independent community hardware utility and is not affiliated with, endorsed by, or supported by ASUSTeK Computer Inc. Always maintain a bootable OpenCore recovery USB and BIOS access when modifying firmware or thermal settings.

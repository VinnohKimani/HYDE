# HyDE: Giving the 2015 MacBook Pro a Second Life (With Extra Bass)
### Automated Post-Install & Dotfiles Suite for Apple MacBook Pro 13" (Early 2015, MacBookPro12,1)
### Powered by Arch Linux, HyDE & Hyprland 0.57+ (Native Lua)

> *"Apple called this hardware obsolete in 2021. Arch Linux and Hyprland called it an untapped high performance weapon."*

---

> [!NOTE]
> **Personal Rig Notice:** This repository is tuned specifically for **my personal daily driver** (Apple MacBook Pro 13" Retina Early 2015 / `MacBookPro12,1`). If you rock the same aluminum slab or want to adapt it to your own machine, you are encouraged to **fork it**, tailor `pkgs/`, customize `dotfiles/hypr/hyprland.lua`, and run wild.

---

##  What Is This Repo Doing? (TL;DR)

You just finished a fresh `archinstall`. You have a cold black TTY screen, a blinking cursor, an 11 year old unibody aluminum machine with a glowing Apple logo, and a vision.

Because a fresh base install from `archinstall` doesn't always have `git` pre-installed, you can turn your freshly installed machine into a fully functional, riced Wayland desktop with a single command:

```bash
sudo pacman -S --needed git && git clone https://github.com/VinnohKimani/HYDE.git && cd HYDE && ./install.sh
```

It launches an interactive TUI checklist that configures your entire system—from hardware firmware patches and anti-stutter RAM management to Hyprland 0.57+ Lua configs—without touching anything as root in your `$HOME`.

---

## 🛠️ Hardware Subsystem Matrix & Precision Engineering

The Early 2015 Retina MacBook Pro remains one of the finest unibody laptops ever built: MagSafe 2, tactile scissor switches, dual Thunderbolt 2, dedicated HDMI, full-size SD card reader, and dual USB 3.0 ports.

However, running a mainline Linux kernel on proprietary Apple firmware encounters severe subsystem discrepancies—from non-standard ACPI sleep registers to unrouted quad-speaker audio codecs. Here is how this repository resolves each challenge at the kernel and root level:

| Subsystem / Challenge | Uncalibrated Linux State | Precision Engineering Fix |
| :--- | :--- | :--- |
| **Cirrus CS4208 Quad-Driver Audio** | Linux only drives the top tweeters by default. Your machine sounds like an angry wasp trapped inside an empty Red Bull can. | Flashes the Cirrus `cs4208-mbp121.fw` patch and executes raw HDA hex verbs at boot to **unmute the bottom dual subwoofers**, reinforced with a 9-stage PipeWire DSP anti-clipping filter. Full, rich bass restored. |
| **SPI ACPI Sleep & Wake Loop** | You close the lid. It sleeps for 0.4 seconds, then `SPIT` (Apple SPI ACPI trigger) wakes it up like it drank 4 shots of espresso, turning your backpack into an oven. | `macbook-wakeup.service` grabs `SPIT` in `/proc/acpi/wakeup` and disables its wake trigger. Your laptop sleeps when told to sleep. |
| **Physical Power Key Behavior** | Apple placed the power button 1mm above Backspace. One typo while coding, and your laptop shuts down immediately. | We tell `systemd-logind` to ignore single power key taps (`HandlePowerKey=ignore`). Long-press is required to power down. |
| **Bluetooth Sleep State Retention** | After resuming from sleep, the Bluetooth controller stays in a coma, dropping all paired devices. | We disable kernel USB autosuspend on `btusb` (`enable_autosuspend=0`). Bluetooth wakes up instantly on resume. |
| **Broadcom PCIe Power Management** | The PCIe Broadcom BCM43602 wireless card crashes the Linux kernel under specific power-saving states. | We deploy `brcmfmac feature_disable=0x82000`, silencing faulty low-power firmware crash loops permanently. |
| **8GB RAM Constraints in 2026** | Modern browsers, IDEs, and Docker containers will throttle an 8GB machine to a dead halt. | **Tiered Memory**: 7.7GB compressed LZ4 **ZRAM** (prio 100) + 8GB secondary **SSD swapfile** (prio 10) + anti-stutter VM sysctl (`swappiness=150`, `page-cluster=0`). Zero lag under heavy workloads. |
| **SMC Thermals & Active Fan Curves** | Apple's firmware fan curve lets the Broadwell CPU cook at 95°C before spinning up the fan like a jet engine. | Deploys and enables `mbpfan.service` with aggressive, smooth temperature-to-RPM stepped curves to prevent thermal throttling. |
| **Apple Force Touch Trackpad Ergonomics** | The massive Force Touch glass trackpad registers your palms and accidental taps while typing. | Configured in `hyprland.lua` with `disable_while_typing = true`, Mac natural scrolling, and ergonomic `clickfinger_behavior = true`. |
| **Retina IPS Panel Scaling & Geometry** | 2560x1600 on a 13.3" panel looks microscopic at 1x and blurry on fractional wayland scales. | Flawless integer **2x HiDPI scaling** (crisp 1280x800 effective workspace) with `GDK_SCALE=2` and Catppuccin Mocha aesthetic. |
| **Optical S/PDIF Battery Leaks** | Unplugging your 3.5mm headphones leaves the optical S/PDIF red laser transmitter constantly on, draining battery. | Managed directly via ALSA CS4208 pin widget control overrides. |
| **FaceTime HD PCIe Sensor Interface (14e4:1570)** | Apple uses a non-standard PCIe camera instead of standard UVC USB; out-of-the-box it has no driver. | Supported via `bcwc-pcie-git` AUR module and firmware extraction. |

---

## Architecture & Layout

```
.
├── install.sh                  # Interactive TUI/CLI checklist menu (whiptail)
├── .gitignore                  # Excludes Wi-Fi passwords, SSH keys & browser caches
├── lib/
│   └── common.sh               # Color logging (log_info, log_success) & sudo keep-alive
├── modules/                    # 6 Modular Execution Layers
│   ├── 01-packages.sh          # System sync, yay bootstrap & package installation
│   ├── 02-dotfiles.sh          # ~/.config timestamped backup & atomic symlink deployer
│   ├── 03-hardware-audio.sh    # CS4208 woofers, 9-stage DSP, SPI wake & BT fixes
│   ├── 04-ram-performance.sh   # 7.7GB ZRAM + 8GB SSD swapfile + VM sysctl
│   ├── 05-dev-apps.sh          # Compilers, Bun/Docker runtimes & desktop applications
│   └── 06-services.sh          # Enables SDDM, NetworkManager, Bluetooth, OOMD, mbpfan
├── pkgs/                       # Modular package manifests (.lst)
├── dotfiles/                   # Symlinked to ~/.config/ (Hyprland Lua, Waybar, Kitty, etc.)
├── scripts/                    # Symlinked to ~/.local/bin/ (Brightness, Volume, Screen cap)
├── scripts/                    # Symlinked to ~/.local/bin/ (Brightness, Volume, Sync, Screen cap)
├── system/                     # Root-level kernel modprobe, audio firmware & sysctl
└── assets/                     # Crisp 2560x1600 Retina abstract wallpapers & custom CSS
```

---

##  Quick Start (Fresh Machine)

1. Boot into your fresh user account from `archinstall`.
2. Run the one liner:
```bash
sudo pacman -S --needed git && git clone https://github.com/VinnohKimani/HYDE.git && cd HYDE && ./install.sh
```
3. Select your components from the interactive checklist:
   - [x] **1. System Update & Package Installation**
   - [x] **2. Desktop & Dotfiles (HyDE / Hyprland 0.57 Lua)**
   - [x] **3. MacBook Pro 2015 Hardware & Audio Suite**
   - [x] **4. Tiered RAM & Performance Tuning**
   - [x] **5. Development Environments & Apps**
   - [x] **6. System Services Enablement**
4. Reboot into your new battlestation:
```bash
sudo reboot
```

---

## Keyboard & Gesture Cheatsheet

| Key / Gesture | Action |
| :--- | :--- |
| `Super + Return` | Open Kitty terminal |
| `Super + Space` | Rofi application launcher |
| `Super + Q` | Close active window |
| `Super + E` | Thunar file manager |
| `Super + V` | Toggle floating window mode |
| `Super + F` | Toggle fullscreen |
| `Super + L` | Lock screen (`hyprlock`) |
| `F1 / F2` | Display brightness down / up (with Dunst OSD) |
| `F5 / F6` | Keyboard backlight down / up |
| `F10 / F11 / F12` | Mute / Volume Down / Volume Up (**auto unmutes automatically**) |
| `Print` | Instant full-screen screenshot |
| `Super + Shift + S` | Select area screenshot -> copied directly to clipboard |
| `Super + Shift + E` | Select area screenshot -> opens in Swappy editor |
| `Super + Shift + D` | Toggle display modes (Internal Retina vs. External HDMI/DP) |
| `3-Finger Swipe Left / Right` | Smoothly glide between workspaces on the glass trackpad |

---

##  Security & Idempotence
##  Upstream Synchronization & Drift Tracking

To keep your system updated with official [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE) improvements, theme updates, and upstream fixes **without risking your custom MacBook Pro hardware fixes**, use `scripts/sync-upstream.sh`.

```bash
# Launch the interactive inspection and sync menu:
./scripts/sync-upstream.sh
```

### Key Capabilities:
- **Automatic Remote Management**: Automatically detects or adds `upstream` pointing to `https://github.com/HyDE-Project/HyDE.git` and fetches latest revisions.
- **Drift Detection**: Calculates how many commits ahead and behind your local branch is.
- **Hardware Protection Guardrails**: Automatically marks your custom hardware configs (`system/audio/*`, `system/memory/*`, `system/hardware/*`, `dotfiles/hypr/hyprland.lua`, etc.) with `[PROTECTED: CUSTOM MBP12,1]` badges to prevent accidental overwrites.
- **Safe Staging Branches (`--stage`)**: Creates an isolated branch (`sync/upstream-YYYYMMDD_HHMMSS`) to test a dry-run merge of upstream before touching your working branch.
- **Selective File Checkout**: Interactively pull single files or fixes from upstream while leaving your customized files untouched.

### CLI Flags:
```bash
./scripts/sync-upstream.sh --check     # Quick exit code drift check (great for terminal greetings / cron)
./scripts/sync-upstream.sh --diff      # Display unified colored diff against upstream
./scripts/sync-upstream.sh --log       # Review upstream commit messages not in local HEAD
./scripts/sync-upstream.sh --stage     # Create test staging branch and attempt dry-run merge
```

---sudo pacman -S obs-studio


##  Security & Idempotence

- **Zero Root Pollution**: `install.sh` refuses to run under `sudo` directly so that files in your `$HOME` remain owned by your user. Root access is requested on demand only for `/etc` and package management.
- **Strict `.gitignore`**: NetworkManager Wi-Fi keys (`*.nmconnection`), SSH credentials, `.env` secrets, and browser caches are permanently barred from commits.
- **Idempotent**: Re-running `./install.sh` will never create duplicate `/etc/fstab` lines, re allocate swapfiles, or clobber configs without backups.

---

<p align="center">
  <b> Forged in silicon defiance. </b><br>
  <i>Apple planned its obsolescence. We stripped the bloat, weaponized the hardware, and turned an 11-year-old unibody slab into a zero-compromise, lightning-fast Wayland battlestation. Zero telemetry. Pure bare-metal control.</i>
</p>

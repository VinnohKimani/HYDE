# 🍏 HyDE: Giving the 2015 MacBook Pro a Second Life (With Extra Bass)
### Automated Post-Install & Dotfiles Suite for Apple MacBook Pro 13" (Early 2015, MacBookPro12,1)
### Powered by Arch Linux, HyDE & Hyprland 0.57+ (Native Lua)

> *"Apple called this hardware obsolete in 2021. Arch Linux and Hyprland called it an untapped high-performance weapon."*

---

> [!NOTE]
> **Personal Rig Notice:** This repository is tuned specifically for **my personal daily driver** (Apple MacBook Pro 13" Retina Early 2015 / `MacBookPro12,1`). If you rock the same aluminum slab or want to adapt it to your own machine, you are encouraged to **fork it**, tailor `pkgs/`, customize `dotfiles/hypr/hyprland.lua`, and run wild.

---

## ⚡ What Is This Repo Doing? (TL;DR)

You just finished a fresh `archinstall`. You have a cold black TTY screen, a blinking cursor, an 11-year-old unibody aluminum machine with a glowing Apple logo, and a vision.

Because a fresh base install from `archinstall` doesn't always have `git` pre-installed, you can turn your freshly installed machine into a fully functional, riced Wayland desktop with a single command:

```bash
sudo pacman -S --needed git && git clone https://github.com/VinnohKimani/HYDE.git && cd HYDE && ./install.sh
```

It launches an interactive TUI checklist that configures your entire system—from hardware firmware patches and anti-stutter RAM management to Hyprland 0.57+ Lua configs—without touching anything as root in your `$HOME`.

---

## 🧰 The MacBook Pro 2015 Quirks (And How We Fix Every Single One)

The Early 2015 Retina MacBook Pro is the pinnacle of Apple hardware engineering: MagSafe 2, tactile scissor keys, dual Thunderbolt 2 / Mini-DP, HDMI, full-size SD card slot, and real USB ports. 

However, running mainline Linux on it without hardware-specific tuning comes with hilarious "Apple quirks":

| Hardware Quirk | What Normally Happens | How This Suite Fixes It |
| :--- | :--- | :--- |
| **Tinny Soda-Can Audio** | Linux only drives the top tweeters. Your machine sounds like an angry wasp trapped inside an empty Red Bull can. | We flash the Cirrus `cs4208-mbp121.fw` patch and fire raw HDA hex verbs at boot to **unmute the bottom dual subwoofers**, reinforced with a 9-stage PipeWire DSP anti-clipping filter. Real bass restored. |
| **Backpack Sauna Mode** | You close the lid. It sleeps for 0.4 seconds, then `SPIT` (Apple SPI ACPI trigger) wakes it up like it drank 4 shots of espresso, turning your backpack into an oven. | `macbook-wakeup.service` grabs `SPIT` in `/proc/acpi/wakeup` and disables its wake trigger. Your laptop sleeps when told to sleep. |
| **The Power Key Landmine** | Apple placed the power button 1mm above Backspace. One typo while coding, and your laptop shuts down immediately. | We tell `systemd-logind` to ignore single power key taps (`HandlePowerKey=ignore`). Long-press is required to power down. |
| **Bluetooth Amnesia** | After resuming from sleep, the Bluetooth controller stays in a coma, dropping all paired devices. | We disable kernel USB autosuspend on `btusb` (`enable_autosuspend=0`). Bluetooth wakes up instantly on resume. |
| **Broadcom WiFi Kernel Panics** | The PCIe Broadcom BCM43602 wireless card crashes the Linux kernel under specific power-saving states. | We deploy `brcmfmac feature_disable=0x82000`, silencing faulty low-power firmware crash loops permanently. |
| **8GB RAM Wall in 2026** | Modern browsers, IDEs, and Docker containers will throttle an 8GB machine to a dead halt. | **Tiered Memory**: 7.7GB compressed LZ4 **ZRAM** (prio 100) + 8GB secondary **SSD swapfile** (prio 10) + anti-stutter VM sysctl (`swappiness=150`, `page-cluster=0`). Zero lag under heavy workloads. |
| **Thermal Throttling & Jet Fan Curve** | Apple's firmware fan curve lets the Broadwell CPU cook at 95°C before spinning up the fan like a jet engine. | Deploys and enables `mbpfan.service` with aggressive, smooth temperature-to-RPM stepped curves to prevent thermal throttling. |
| **Trackpad Palm Rejection & Accidental Taps** | The massive Force Touch glass trackpad registers your palms and accidental taps while typing. | Configured in `hyprland.lua` with `disable_while_typing = true`, Mac natural scrolling, and ergonomic `clickfinger_behavior = true`. |
| **Retina Display HiDPI Scaling** | 2560x1600 on a 13.3" panel looks microscopic at 1x and blurry on fractional wayland scales. | Flawless integer **2x HiDPI scaling** (crisp 1280x800 effective workspace) with `GDK_SCALE=2` and Catppuccin Mocha aesthetic. |
| **Headphone Jack Red Laser Glowing** | Unplugging your 3.5mm headphones leaves the optical S/PDIF red laser transmitter constantly on, draining battery. | Managed directly via ALSA CS4208 pin widget control overrides. |
| **FaceTime HD PCIe Webcam (14e4:1570)** | Apple uses a non-standard PCIe camera instead of standard UVC USB; out-of-the-box it has no driver. | Supported via `bcwc-pcie-git` AUR module and firmware extraction. |

---

## ❓ FAQ: Do I Need to Run the Package Export Commands?

> **Short Answer: NO!**

The package lists in `pkgs/` are completely pre-configured and ready to deploy:
- `pkgs/base-desktop.lst` (Hyprland 0.57+, SDDM, Waybar, Dunst, Kitty, PipeWire, brightness/volume scripts, fonts)
- `pkgs/aur.lst` (Yay, mbpfan, wlogout, swaylock-effects, etc.)
- `pkgs/dev.lst` (Neovim, Tmux, Python, Node, Rust, Docker, etc.)
- `pkgs/apps.lst` (Brave, Discord, Telegram, Obsidian, VS Code, etc.)

**When would you use the export commands?**  
Only if you have been daily-driving this system for months, installed 30 new personal packages, and want to **snapshot your installed apps back into your git repo**:
```bash
pacman -Qqen > pkgs/base-desktop.lst   # Snapshot official packages
pacman -Qqem > pkgs/aur.lst            # Snapshot AUR packages
```
If you are doing a fresh install or reinstalling: **just run `./install.sh` and let it do the heavy lifting.**

---

## 🏗️ Architecture & Layout

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
├── system/                     # Root-level kernel modprobe, audio firmware & sysctl
└── assets/                     # Crisp 2560x1600 Retina abstract wallpapers & custom CSS
```

---

## 🚀 Quick Start (Fresh Machine)

1. Boot into your fresh user account from `archinstall`.
2. Run the one-liner:
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

## 🎹 Keyboard & Gesture Cheatsheet

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
| `F10 / F11 / F12` | Mute / Volume Down / Volume Up (**auto-unmutes automatically**) |
| `Print` | Instant full-screen screenshot |
| `Super + Shift + S` | Select area screenshot -> copied directly to clipboard |
| `Super + Shift + E` | Select area screenshot -> opens in Swappy editor |
| `Super + Shift + D` | Toggle display modes (Internal Retina vs. External HDMI/DP) |
| `3-Finger Swipe Left / Right` | Smoothly glide between workspaces on the glass trackpad |

---

## 🛡️ Security & Idempotence

- **Zero Root Pollution**: `install.sh` refuses to run under `sudo` directly so that files in your `$HOME` remain owned by your user. Root access is requested on-demand only for `/etc` and package management.
- **Strict `.gitignore`**: NetworkManager Wi-Fi keys (`*.nmconnection`), SSH credentials, `.env` secrets, and browser caches are permanently barred from commits.
- **Idempotent**: Re-running `./install.sh` will never create duplicate `/etc/fstab` lines, re-allocate swapfiles, or clobber configs without backups.

---

## 📤 Push Changes to GitHub

To commit and push all newly created files to your remote repository:

```bash
cd /home/vinnoh/Development/HYDE

# 1. Stage everything
git add .

# 2. Commit with a message
git commit -m "feat: complete HyDE post-install suite & badass documentation for MacBook Pro 12,1"

# 3. Push to origin
git push -u origin main
```

---

<p align="center">
  <b>⚡ Forged in silicon defiance. ⚡</b><br>
  <i>Apple planned its obsolescence. We stripped the bloat, weaponized the hardware, and turned an 11-year-old unibody slab into a zero-compromise, lightning-fast Wayland battlestation. Zero telemetry. Pure bare-metal control.</i>
</p>

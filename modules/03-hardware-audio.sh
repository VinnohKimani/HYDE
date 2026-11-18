#!/usr/bin/env bash
# ==============================================================================
# Module 03: Apple MacBook Pro 12,1 (Early 2015) Hardware & Audio Suite
# Configures Cirrus CS4208 dual woofers, PipeWire DSP, SPI wake, and Bluetooth fixes
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_step "Deploying MacBook Pro 2015 Hardware & Audio Configurations"

init_sudo

# 1. Cirrus CS4208 Firmware Patch & ALSA Config
log_info "Installing Cirrus CS4208 firmware patch to /lib/firmware/..."
sudo mkdir -p /lib/firmware
sudo cp "${SCRIPT_DIR}/system/audio/cs4208-mbp121.fw" /lib/firmware/cs4208-mbp121.fw

log_info "Configuring ALSA snd-hda-intel model & patch in /etc/modprobe.d/..."
sudo mkdir -p /etc/modprobe.d
sudo cp "${SCRIPT_DIR}/system/audio/alsa-macbook.conf" /etc/modprobe.d/alsa-macbook.conf

# 2. Dual Woofer Unmute Script & Systemd Unit
log_info "Installing woofer unmute script to /usr/local/bin/..."
sudo cp "${SCRIPT_DIR}/system/audio/macbook-cs4208-woofers.sh" /usr/local/bin/macbook-cs4208-woofers.sh
sudo chmod 755 /usr/local/bin/macbook-cs4208-woofers.sh

log_info "Installing macbook-cs4208-woofers.service to /etc/systemd/system/..."
sudo cp "${SCRIPT_DIR}/system/audio/macbook-cs4208-woofers.service" /etc/systemd/system/macbook-cs4208-woofers.service

# 3. System-wide PipeWire 9-stage DSP Filter Chain
log_info "Installing PipeWire 9-stage anti-clipping acoustic filter chain..."
sudo mkdir -p /etc/pipewire/pipewire.conf.d
sudo cp "${SCRIPT_DIR}/system/audio/99-macbook-dsp.conf" /etc/pipewire/pipewire.conf.d/99-macbook-dsp.conf

# 4. Sleep & Wakeup ACPI Service (SPI Keyboard/Trackpad Fix)
log_info "Installing SPI ACPI wakeup inhibitor service..."
sudo cp "${SCRIPT_DIR}/system/hardware/macbook-wakeup.service" /etc/systemd/system/macbook-wakeup.service

# 5. Kernel Driver Stability Fixes
log_info "Deploying Bluetooth autosuspend fix (/etc/modprobe.d/btusb.conf)..."
sudo cp "${SCRIPT_DIR}/system/hardware/btusb.conf" /etc/modprobe.d/btusb.conf

log_info "Deploying Broadcom BCM43602 WiFi fix (/etc/modprobe.d/brcmfmac.conf)..."
sudo cp "${SCRIPT_DIR}/system/hardware/brcmfmac.conf" /etc/modprobe.d/brcmfmac.conf

# 6. NetworkManager MAC Randomization
log_info "Enabling Wi-Fi MAC address randomization..."
sudo mkdir -p /etc/NetworkManager/conf.d
sudo cp "${SCRIPT_DIR}/system/hardware/mac-rand.conf" /etc/NetworkManager/conf.d/mac-rand.conf

# 7. Logind Power Key Protection
log_info "Configuring systemd logind to ignore accidental power key taps..."
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp "${SCRIPT_DIR}/system/hardware/ignore-power-key.conf" /etc/systemd/logind.conf.d/ignore-power-key.conf

# 8. Reload and Enable Services if systemd is running
if [[ -d /run/systemd/system ]]; then
    log_info "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    sudo systemctl enable macbook-cs4208-woofers.service || true
    sudo systemctl enable macbook-wakeup.service || true
    # Run woofer activation immediately if hardware exists
    sudo /usr/local/bin/macbook-cs4208-woofers.sh || log_warn "Could not test woofers immediately (no CS4208 chip or sandbox container)."
else
    log_info "System is not currently running systemd (PID 1). Services enabled for next boot."
fi

log_success "Module 03: MacBook Pro hardware and audio configuration complete."

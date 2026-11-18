#!/usr/bin/env bash
# ==============================================================================
# Direct Standalone Hardware & System Installer for MacBook Pro 12,1
# Deploys memory tuning, audio firmware/services, and sleep/wake fixes
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root (e.g. sudo $0)" >&2
    exit 1
fi

echo "==> Deploying System & Hardware configurations for MacBook Pro 12,1..."

# 1. Memory & Sysctl
mkdir -p /etc/systemd /etc/sysctl.d
cp "${SCRIPT_DIR}/memory/zram-generator.conf" /etc/systemd/zram-generator.conf
cp "${SCRIPT_DIR}/memory/99-vm.conf" /etc/sysctl.d/99-vm.conf
sysctl --system || true

# 2. Audio & CS4208 Dual Woofers
mkdir -p /lib/firmware /etc/modprobe.d /usr/local/bin /etc/systemd/system /etc/pipewire/pipewire.conf.d
cp "${SCRIPT_DIR}/audio/cs4208-mbp121.fw" /lib/firmware/cs4208-mbp121.fw
cp "${SCRIPT_DIR}/audio/alsa-macbook.conf" /etc/modprobe.d/alsa-macbook.conf
cp "${SCRIPT_DIR}/audio/macbook-cs4208-woofers.sh" /usr/local/bin/macbook-cs4208-woofers.sh
chmod 755 /usr/local/bin/macbook-cs4208-woofers.sh
cp "${SCRIPT_DIR}/audio/macbook-cs4208-woofers.service" /etc/systemd/system/macbook-cs4208-woofers.service
cp "${SCRIPT_DIR}/audio/99-macbook-dsp.conf" /etc/pipewire/pipewire.conf.d/99-macbook-dsp.conf

# 3. Hardware, Bluetooth, WiFi, Power Key
cp "${SCRIPT_DIR}/hardware/macbook-wakeup.service" /etc/systemd/system/macbook-wakeup.service
cp "${SCRIPT_DIR}/hardware/btusb.conf" /etc/modprobe.d/btusb.conf
cp "${SCRIPT_DIR}/hardware/brcmfmac.conf" /etc/modprobe.d/brcmfmac.conf
mkdir -p /etc/NetworkManager/conf.d /etc/systemd/logind.conf.d
cp "${SCRIPT_DIR}/hardware/mac-rand.conf" /etc/NetworkManager/conf.d/mac-rand.conf
cp "${SCRIPT_DIR}/hardware/ignore-power-key.conf" /etc/systemd/logind.conf.d/ignore-power-key.conf

if [[ -d /run/systemd/system ]]; then
    systemctl daemon-reload
    systemctl enable macbook-cs4208-woofers.service
    systemctl enable macbook-wakeup.service
    /usr/local/bin/macbook-cs4208-woofers.sh || true
fi

echo "==> System & Hardware deployment complete."

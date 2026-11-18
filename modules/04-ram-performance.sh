#!/usr/bin/env bash
# ==============================================================================
# Module 04: Tiered RAM & Performance Tuning
# Configures 7.7GB ZRAM (Prio 100) + 8GB SSD /swapfile (Prio 10) + VM Sysctl
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_step "Configuring Tiered Memory & VM Performance Tuning"

init_sudo

# 1. ZRAM Generator Configuration
log_info "Configuring systemd-zram-generator (7.7GB, LZ4, Priority 100)..."
sudo mkdir -p /etc/systemd
sudo cp "${SCRIPT_DIR}/system/memory/zram-generator.conf" /etc/systemd/zram-generator.conf

if ! has_cmd /usr/lib/systemd/system-generators/systemd-zram-setup-generator && ! pacman -Qi zram-generator >/dev/null 2>&1; then
    log_info "Installing zram-generator package..."
    sudo pacman -S --needed --noconfirm zram-generator
fi

# 2. Kernel VM Sysctl Parameters
log_info "Deploying anti-stutter VM parameters (/etc/sysctl.d/99-vm.conf)..."
sudo mkdir -p /etc/sysctl.d
sudo cp "${SCRIPT_DIR}/system/memory/99-vm.conf" /etc/sysctl.d/99-vm.conf

log_info "Applying sysctl parameters immediately..."
sudo sysctl --system || true

# 3. Secondary 8GB SSD Swapfile Setup (Priority 10)
SWAP_PATH="/swapfile"
SWAP_SIZE_GB=8

if [[ -f "$SWAP_PATH" ]]; then
    log_info "Existing swapfile detected at ${SWAP_PATH}. Skipping allocation."
else
    log_info "Allocating ${SWAP_SIZE_GB}GB secondary SSD swapfile at ${SWAP_PATH}..."
    if ! sudo fallocate -l "${SWAP_SIZE_GB}G" "$SWAP_PATH" 2>/dev/null; then
        log_warn "fallocate failed, falling back to dd..."
        sudo dd if=/dev/zero of="$SWAP_PATH" bs=1M count=$((SWAP_SIZE_GB * 1024)) status=progress
    fi

    log_info "Setting secure permissions (0600) on ${SWAP_PATH}..."
    sudo chmod 600 "$SWAP_PATH"

    log_info "Formatting ${SWAP_PATH} as swap..."
    sudo mkswap -U clear "$SWAP_PATH"
fi

# Enable swapfile with priority 10 if not already active
if swapon --show=NAME --noheadings | grep -q "^${SWAP_PATH}$"; then
    log_info "Swapfile ${SWAP_PATH} is already active."
else
    log_info "Activating ${SWAP_PATH} with priority 10..."
    sudo swapon -p 10 "$SWAP_PATH" || log_warn "swapon failed (could be inside restricted container)."
fi

# Idempotently add /swapfile to /etc/fstab with priority 10
FSTAB_LINE="/swapfile none swap defaults,pri=10 0 0"
if grep -q "^/swapfile" /etc/fstab 2>/dev/null; then
    log_info "/swapfile already declared in /etc/fstab."
else
    log_info "Appending /swapfile to /etc/fstab..."
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null
fi

# 4. Trigger ZRAM setup if systemd is active
if [[ -d /run/systemd/system ]]; then
    log_info "Starting systemd-zram-setup@zram0..."
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-zram-setup@zram0.service || true
fi

log_success "Module 04: Tiered RAM & VM performance tuning completed."

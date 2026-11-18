#!/usr/bin/env bash
# ==============================================================================
# Module 06: System Services Enablement
# Enables and starts core system daemons (sddm, NetworkManager, bluetooth, oomd)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

log_step "Enabling Core System Services"

init_sudo

SERVICES=(
    "NetworkManager.service"
    "bluetooth.service"
    "sddm.service"
    "systemd-oomd.service"
    "macbook-cs4208-woofers.service"
    "macbook-wakeup.service"
    "mbpfan.service"
)

if [[ -d /run/systemd/system ]]; then
    log_info "Reloading systemd manager configuration..."
    sudo systemctl daemon-reload

    for svc in "${SERVICES[@]}"; do
        log_info "Enabling and starting service: ${svc}..."
        sudo systemctl enable "${svc}" || log_warn "Failed to enable: ${svc}"
        # Start immediately except sddm if in active terminal to avoid kicking user out
        if [[ "$svc" != "sddm.service" ]]; then
            sudo systemctl start "${svc}" 2>/dev/null || true
        fi
        log_success "Service ${svc} configured."
    done
else
    log_warn "System is not booted with systemd as PID 1 (e.g. inside chroot or container)."
    log_info "Enabling systemd service symlinks directly in /etc/systemd/system/..."
    for svc in "${SERVICES[@]}"; do
        log_info "Enabling ${svc}..."
        sudo systemctl enable "${svc}" 2>/dev/null || true
    done
fi

log_success "Module 06: All core system services enabled."
